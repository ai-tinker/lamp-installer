#!/bin/bash

############################################################
# APACHE VHOST CREATOR (FINAL VERSION)
############################################################

CONFIG="/tmp/.env" # was "/tmp/data.txt"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="$SCRIPT_DIR/files/vhost-template.conf"

APACHE_AVAILABLE="/etc/apache2/sites-available"
APACHE_ENABLED="/etc/apache2/sites-enabled"

WEBROOT_BASE="/var/www"

############################################################
# CHECK ROOT PRIVILEGE
############################################################

if [ "$EUID" -ne 0 ]; then
echo "[ERROR] Script must be run with sudo or root"
echo "Example:"
echo "sudo ./create-vhost.sh"
exit 1
fi

############################################################
# CHECK CONFIG FILE
############################################################

if [ ! -f "$CONFIG" ]; then
echo "[ERROR] Config file not found: $CONFIG"
exit 1
fi

############################################################
# CHECK TEMPLATE
############################################################

if [ ! -f "$TEMPLATE" ]; then
echo "[ERROR] Vhost template not found:"
echo "$TEMPLATE"
exit 1
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
echo "[ERROR] subdomain or sshuser missing in config"
exit 1
fi

############################################################
# CHECK SSH USER
############################################################

if ! id "$sshuser" >/dev/null 2>&1; then
echo "[ERROR] SSH user '$sshuser' not found"
echo "Please run create-accounts.sh first"
exit 1
fi

############################################################
# DEFINE PATHS
############################################################

VHOST_FILE="$APACHE_AVAILABLE/$subdomain.conf"
WEBROOT="$WEBROOT_BASE/$subdomain"
HTMLDIR="$WEBROOT/html"

############################################################
# CHECK IF VHOST ALREADY EXISTS
############################################################

if [ -f "$VHOST_FILE" ]; then
echo "[WARN] VirtualHost already exists:"
echo "$VHOST_FILE"
exit 0
fi

############################################################
# CREATE WEB DIRECTORY
############################################################

echo "[INFO] Creating web directory"

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
# GENERATE VHOST FROM TEMPLATE
############################################################

echo "[INFO] Generating VirtualHost configuration"

echo "[INFO] Creating VHOST:"
echo "$VHOST_FILE"

sed "s/___DOMAIN___/$subdomain/g" "$TEMPLATE" > "$VHOST_FILE"

############################################################
# ENABLE SITE
############################################################

echo "[INFO] Enabling site"

if [ ! -f "$APACHE_ENABLED/$subdomain.conf" ]; then
sudo a2ensite "$subdomain.conf" >/dev/null
else
echo "[WARN] Site already enabled"
fi

############################################################
# APACHE CONFIG TEST
############################################################

echo "[INFO] Testing Apache configuration"

apache2ctl configtest >/var/log/apache-test.log 2>&1

if [ $? -ne 0 ]; then

echo "[ERROR] Apache configuration invalid"
cat /var/log/apache-test.log

echo "[INFO] Rolling back..."

a2dissite "$subdomain.conf" >/dev/null 2>&1
rm -f "$VHOST_FILE"

exit 1

fi

############################################################
# RELOAD APACHE
############################################################

echo "[INFO] Reloading Apache"

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

