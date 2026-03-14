#!/bin/bash

############################################################
# ACCOUNT CREATOR + MYSQL PROVISIONER
# Robust / Idempotent Version
############################################################

EXIT_OK=0
EXIT_RUNTIME=1
EXIT_USAGE=2
EXIT_CONFIG=3

info() { echo "[INFO] $1"; }
warn() { echo "[WARN] $1"; }
error() { echo "[ERROR] $1"; }
ok() { echo "[OK] $1"; }

############################################################
# LOAD GLOBAL CONFIG
############################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GLOBAL_CONFIG="$SCRIPT_DIR/files/config.conf"

if [ ! -f "$GLOBAL_CONFIG" ]; then
    error "Global config not found: $GLOBAL_CONFIG"
    exit "$EXIT_CONFIG"
fi

source "$GLOBAL_CONFIG"

if [ ! -f "$CONFIG" ]; then
    error "Config file not found: $CONFIG"
    exit "$EXIT_CONFIG"
fi

############################################################
# ROOT CHECK
############################################################

if [ "$EUID" -ne 0 ]; then
    error "Script must be run with sudo or root"
    echo "Example:"
    echo "sudo ./create-vhost.sh"
    exit "$EXIT_USAGE"
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
    error "sshuser or sshpwd not defined in config"
    exit "$EXIT_CONFIG"
fi

if [ -z "$myrootuser" ] || [ -z "$myrootpwd" ]; then
    error "myrootuser or myrootpwd not defined in config"
    exit "$EXIT_CONFIG"
fi

if [ -z "$myuser" ] || [ -z "$myppwd" ]; then
    error "myuser or myppwd not defined in config"
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
# SSH USER SETUP
############################################################

info "Ensuring SSH user..."

if id "$sshuser" >/dev/null 2>&1; then
    warn "SSH user '$sshuser' already exists"
else
    info "Creating SSH user..."
    useradd -m -s /bin/bash "$sshuser"
    ok "SSH user created"
fi

echo "$sshuser:$sshpwd" | chpasswd
usermod -aG sudo "$sshuser"

ok "SSH user ensured"

############################################################
# MYSQL FUNCTIONS
############################################################

mysql_exec_root() {

mysql -uroot -p"$myrootpwd" -e "$1" >/dev/null 2>&1

}

mysql_exec_socket() {

mysql -uroot -e "$1" >/dev/null 2>&1

}

############################################################
# MYSQL ROOT CONFIGURATION
############################################################

echo ""
info "Configuring MySQL root authentication..."

MYSQL_SOCKET_LOGIN=false
MYSQL_PASSWORD_LOGIN=false

if mysql_exec_socket "SELECT 1"; then
    MYSQL_SOCKET_LOGIN=true
fi

if mysql_exec_root "SELECT 1"; then
    MYSQL_PASSWORD_LOGIN=true
fi

############################################################
# CASE 1: ROOT VIA SOCKET
############################################################

if [ "$MYSQL_SOCKET_LOGIN" = true ]; then

    info "Root login via auth_socket detected"
    info "Setting root password and switching to mysql_native_password"

    mysql -uroot <<SQL >/dev/null 2>&1
ALTER USER '$myrootuser'@'localhost'
IDENTIFIED WITH mysql_native_password
BY '$myrootpwd';
FLUSH PRIVILEGES;
SQL

fi

############################################################
# VERIFY ROOT PASSWORD
############################################################

if mysql_exec_root "SELECT 1"; then
    ok "MySQL root password verified"
else
    error "Cannot authenticate with configured MySQL root password"
    exit "$EXIT_RUNTIME"
fi

############################################################
# CREATE / UPDATE MYSQL USER
############################################################

info "Ensuring MySQL user '$myuser'"

mysql_exec_root "
CREATE USER IF NOT EXISTS '$myuser'@'localhost'
IDENTIFIED BY '$myppwd';
"

mysql_exec_root "
ALTER USER '$myuser'@'localhost'
IDENTIFIED BY '$myppwd';
"

mysql_exec_root "
GRANT ALL PRIVILEGES ON *.* TO '$myuser'@'localhost'
WITH GRANT OPTION;
"

mysql_exec_root "FLUSH PRIVILEGES;"

ok "MySQL user ensured"

############################################################

echo ""
echo "======================================"
echo "Completed"
echo "======================================"
echo ""

