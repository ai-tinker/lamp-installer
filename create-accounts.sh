#!/bin/bash

# 20260308, root password mysql BELUM BERHASIL DI-SET
# Gunakan akun myuser sebagai superadmin

############################################################
# ACCOUNT CREATOR
# Read configuration from /tmp/data.txt
############################################################

EXIT_OK=0
EXIT_RUNTIME=1
EXIT_USAGE=2
EXIT_CONFIG=3

info() { echo "[INFO] $1"; }
warn() { echo "[WARN] $1"; }
error() { echo "[ERROR] $1"; }
ok() { echo "[OK] $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GLOBAL_CONFIG="$SCRIPT_DIR/files/config.conf"

if [ ! -f "$GLOBAL_CONFIG" ]; then
error "Global config not found: $GLOBAL_CONFIG"
exit "$EXIT_CONFIG"
fi

source "$GLOBAL_CONFIG"

############################################################
# CHECK ROOT PRIVILEGE
############################################################

if [ "$EUID" -ne 0 ]; then
error "Script must be run with sudo or root"
echo "Example:"
echo "sudo ./create-vhost.sh"
exit "$EXIT_USAGE"
fi

if [ ! -f "$CONFIG" ]; then
warn "Config file not found: $CONFIG"
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

sshuser=$(get_config sshuser)
sshpwd=$(get_config sshpwd)

myuser=$(get_config myuser)
myppwd=$(get_config myppwd)
if [ -z "$myppwd" ]; then
myppwd=$(get_config mypwd)
fi
myrootuser=$(get_config myrootuser)
myrootpwd=$(get_config myrootpwd)

############################################################
# VALIDATION
############################################################

if [ -z "$sshuser" ] || [ -z "$sshpwd" ]; then
error "sshuser or sshpwd not defined"
exit "$EXIT_CONFIG"
fi

if [ -z "$myrootuser" ] || [ -z "$myrootpwd" ]; then
error "myrootuser or myrootpwd not defined"
exit "$EXIT_CONFIG"
fi

if [ -z "$myuser" ] || [ -z "$myppwd" ]; then
error "myuser or myppwd not defined"
exit "$EXIT_CONFIG"
fi

############################################################
# INFO
############################################################

echo ""
echo "======================================"
echo "Account Creation Script"
echo "======================================"
echo ""

echo "SSH USER  : $sshuser"
echo "MYSQL USER: $myuser"
echo ""

############################################################
# CREATE/UPDATE SSH USER
############################################################

info "Ensuring SSH user..."

if id "$sshuser" >/dev/null 2>&1; then
warn "SSH user '$sshuser' already exists. Updating group membership and password."
else
info "Creating SSH user..."
useradd -m -s /bin/bash "$sshuser"
ok "SSH user created"
fi

echo "$sshuser:$sshpwd" | chpasswd
usermod -aG sudo "$sshuser"
ok "SSH user ensured with sudo group and configured password"

############################################################
# MYSQL HELPER
############################################################

echo ""
info "Ensuring MySQL account state..."

mysql_exec() {
QUERY="$1"

mysql -u"$myrootuser" -p"$myrootpwd" -e "$QUERY" >/dev/null 2>&1 && return 0

return 1
}

if [ "$myrootuser" != "root" ]; then
error "myrootuser must be 'root' for this script"
exit "$EXIT_CONFIG"
fi

############################################################
# ROOT PASSWORD POLICY
############################################################

if mysql -uroot -e "SELECT 1;" >/dev/null 2>&1; then
info "Fresh install detected: root has no password, applying myrootpwd"
mysql -uroot -e "ALTER USER '$myrootuser'@'localhost' IDENTIFIED BY '$myrootpwd'; FLUSH PRIVILEGES;" >/dev/null 2>&1 || {
error "Failed to set MySQL root password on fresh install. MySQL provisioning aborted."
exit "$EXIT_RUNTIME"
}
ok "MySQL root password configured"
else
info "MySQL root password already set. Skipping root password change."
mysql_exec "SELECT 1;" || {
error "Cannot authenticate with myrootuser/myrootpwd. MySQL provisioning aborted."
exit "$EXIT_RUNTIME"
}
ok "MySQL root credentials verified"
fi

############################################################
# CREATE/UPDATE MYSQL USER
############################################################

info "Ensuring MySQL user '$myuser'"

mysql_exec "CREATE USER IF NOT EXISTS '$myuser'@'localhost' IDENTIFIED BY '$myppwd';" || {
error "Unable to authenticate as MySQL root to create/update '$myuser'"
exit "$EXIT_RUNTIME"
}

mysql_exec "ALTER USER '$myuser'@'localhost' IDENTIFIED BY '$myppwd';" || {
error "Unable to set password for MySQL user '$myuser'"
exit "$EXIT_RUNTIME"
}

mysql_exec "GRANT ALL PRIVILEGES ON *.* TO '$myuser'@'localhost' WITH GRANT OPTION; FLUSH PRIVILEGES;" || {
error "Unable to grant privileges for MySQL user '$myuser'"
exit "$EXIT_RUNTIME"
}

ok "MySQL user ensured"

############################################################

echo ""
echo "======================================"
echo "Completed"
echo "======================================"
echo ""
