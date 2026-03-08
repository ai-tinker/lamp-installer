#!/bin/bash

############################################################
# APACHE VHOST CREATOR (FINAL VERSION)
############################################################

EXIT_OK=0
EXIT_RUNTIME=1
EXIT_USAGE=2
EXIT_CONFIG=3

info() { echo "[INFO] $1"; }
warn() { echo "[WARN] $1"; }
error() { echo "[ERROR] $1"; }
ok() { echo "[OK] $1"; }

GLOBAL_CONFIG="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/files/config.conf"

if [ ! -f "$GLOBAL_CONFIG" ]; then
error "Global config not found: $GLOBAL_CONFIG"
exit "$EXIT_CONFIG"
fi

source "$GLOBAL_CONFIG"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="$SCRIPT_DIR/files/vhost-template.conf"

APACHE_AVAILABLE="/etc/apache2/sites-available"
APACHE_ENABLED="/etc/apache2/sites-enabled"

WEBROOT_BASE="/var/www"

############################################################
# CHECK ROOT PRIVILEGE
############################################################

if [ "$EUID" -ne 0 ]; then
error "Script must be run with sudo or root"
echo "Example:"
echo "sudo ./create-vhost.sh"
exit "$EXIT_USAGE"
fi

############################################################
# CHECK CONFIG FILE
############################################################

if [ ! -f "$CONFIG" ]; then
warn "Config file not found: $CONFIG"
exit "$EXIT_CONFIG"
fi

############################################################
# CHECK TEMPLATE
############################################################

if [ ! -f "$TEMPLATE" ]; then
error "Vhost template not found:"
echo "$TEMPLATE"
exit "$EXIT_CONFIG"
fi

############################################################
# CONFIG PARSER
############################################################

get_config() {

KEY="$1"

grep -E "^[[:space:]]*$KEY[[:space:]]*=" "$CONFIG" \
| head -n1 \
| cut -d '=' -f2- \
| sed 's/^[ \t]*//;s/[ \t]*$//'

}

############################################################
# LOAD VARIABLES
############################################################

subdomain=$(get_config subdomain)
sshuser=$(get_config sshuser)

if [ -z "$subdomain" ] || [ -z "$sshuser" ]; then
error "subdomain or sshuser missing in config"
exit "$EXIT_CONFIG"
fi

############################################################
# CHECK SSH USER
############################################################

if ! id "$sshuser" >/dev/null 2>&1; then
error "SSH user '$sshuser' not found"
echo "Please run create-accounts.sh first"
exit "$EXIT_RUNTIME"
fi

############################################################
# DEFINE PATHS
############################################################

VHOST_FILE="$APACHE_AVAILABLE/$subdomain.conf"
WEBROOT="$WEBROOT_BASE/$subdomain"
HTMLDIR="$WEBROOT/html"

############################################################
# ENSURE VHOST FILE
############################################################

if [ -f "$VHOST_FILE" ]; then
warn "VirtualHost already exists:"
echo "$VHOST_FILE"
info "Keeping existing VirtualHost file"
else
info "Generating VirtualHost configuration"
info "Creating VHOST:"
echo "$VHOST_FILE"
sed "s/___DOMAIN___/$subdomain/g" "$TEMPLATE" > "$VHOST_FILE"
fi

############################################################
# ENSURE WEB DIRECTORY
############################################################

info "Creating web directory"

mkdir -p "$HTMLDIR"

############################################################
# SET OWNER
############################################################

chown -R "$sshuser:$sshuser" "$WEBROOT"

############################################################
# CREATE DEFAULT INDEX FILE
############################################################

INDEX="$HTMLDIR/index.html"

if [ ! -f "$INDEX" ]; then

cat <<EOF > "$INDEX"
<html>
<head>
<title>$subdomain</title>
</head>
<body>
<h1>VirtualHost Ready</h1>
<p>$subdomain is configured correctly.</p>
</body>
</html>
EOF

fi

############################################################
# ENABLE SITE
############################################################

info "Enabling site"

if [ ! -f "$APACHE_ENABLED/$subdomain.conf" ]; then
a2ensite "$subdomain.conf" >/dev/null
else
warn "Site already enabled"
fi

############################################################
# APACHE CONFIG TEST
############################################################

info "Testing Apache configuration"

apache2ctl configtest >/var/log/apache-test.log 2>&1

if [ $? -ne 0 ]; then

error "Apache configuration invalid"
cat /var/log/apache-test.log

info "Rolling back..."

a2dissite "$subdomain.conf" >/dev/null 2>&1
rm -f "$VHOST_FILE"

exit "$EXIT_RUNTIME"

fi

############################################################
# RELOAD APACHE
############################################################

info "Reloading Apache"

systemctl reload apache2

############################################################
# SUCCESS MESSAGE
############################################################

echo ""
echo "======================================"
echo "VirtualHost created successfully"
echo "======================================"
echo ""
echo "Domain  : $subdomain"
echo "Webroot : $HTMLDIR"
echo "Owner   : $sshuser"
echo ""
exit "$EXIT_OK"
