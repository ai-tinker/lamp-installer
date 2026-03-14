#!/bin/bash

############################################################
# PROFESSIONAL LAMP INSTALLER
# Ubuntu 22.04 / 24.04
############################################################

set -e

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
MODULE_DIR="$BASE_DIR/modules"
GLOBAL_CONFIG="$BASE_DIR/files/config.conf"

LOGFILE="/var/log/lamp_installer.log"

source $MODULE_DIR/system.sh
source $MODULE_DIR/apache.sh
source $MODULE_DIR/mysql.sh
source $MODULE_DIR/php.sh
source $MODULE_DIR/phpmyadmin.sh
source $MODULE_DIR/prometheus-node-exporter.sh
source $MODULE_DIR/fail2ban.sh
source $MODULE_DIR/wazuh-agent.sh
source $MODULE_DIR/remoteip.sh


source $MODULE_DIR/security.sh

CONFIG=".env"
if [ -f "$GLOBAL_CONFIG" ]; then
source "$GLOBAL_CONFIG"
fi

ENV_FILE="$CONFIG"
if [[ "$ENV_FILE" != /* ]]; then
ENV_FILE="$BASE_DIR/$ENV_FILE"
fi

get_config() {
KEY="$1"
DEFAULT="$2"

if [ ! -f "$ENV_FILE" ]; then
echo "$DEFAULT"
return
fi

VALUE=$(grep -E "^[[:space:]]*$KEY[[:space:]]*=" "$ENV_FILE" \
| head -n1 \
| cut -d '=' -f2- \
| sed 's/^[ \t]*//;s/[ \t]*$//')

if [ -z "$VALUE" ]; then
echo "$DEFAULT"
else
echo "$VALUE"
fi
}

is_enabled() {
VALUE="$(echo "${1:-}" | tr '[:upper:]' '[:lower:]')"
case "$VALUE" in
1|true|yes|on) return 0 ;;
0|false|no|off|"") return 1 ;;
*)
warn "Invalid toggle value '$1', defaulting to disabled"
return 1
;;
esac
}

run_module_if_enabled() {
TOGGLE_KEY="$1"
TOGGLE_VALUE="$2"
LABEL="$3"
FUNCTION_NAME="$4"

if is_enabled "$TOGGLE_VALUE"; then
info "$LABEL enabled ($TOGGLE_KEY=$TOGGLE_VALUE)"
"$FUNCTION_NAME"
else
info "$LABEL disabled ($TOGGLE_KEY=$TOGGLE_VALUE)"
fi
}

generate_password() {
LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom 2>/dev/null | head -c 20
}

set_env_value() {
KEY="$1"
VALUE="$2"

if grep -Eq "^[[:space:]]*$KEY[[:space:]]*=" "$ENV_FILE"; then
sed -i "s|^[[:space:]]*$KEY[[:space:]]*=.*|$KEY=$VALUE|" "$ENV_FILE"
else
echo "$KEY=$VALUE" >> "$ENV_FILE"
fi
}

prepare_env_file() {
TEMPLATE_ENV="$BASE_DIR/.env-example"

if [ -f "$ENV_FILE" ]; then
info "Environment file already exists at $ENV_FILE, skipping creation"
return
fi

if [ ! -f "$TEMPLATE_ENV" ]; then
warn "Template file not found at $TEMPLATE_ENV, skipping .env creation"
return
fi

cp "$TEMPLATE_ENV" "$ENV_FILE"

set_env_value sshpwd "$(generate_password)"
set_env_value mypwd "$(generate_password)"
set_env_value myrootpwd "$(generate_password)"

info "Environment file created at $ENV_FILE"
}

main() {

clear

info "Starting LAMP Installer"

check_root
update_repo

ENABLE_APACHE=$(get_config ENABLE_APACHE true)
ENABLE_MYSQL=$(get_config ENABLE_MYSQL true)
ENABLE_PHP=$(get_config ENABLE_PHP true)
ENABLE_PHP_TEST_FILE=$(get_config ENABLE_PHP_TEST_FILE true)
ENABLE_PHPMYADMIN=$(get_config ENABLE_PHPMYADMIN true)
ENABLE_PROMETHEUS_NODE_EXPORTER=$(get_config ENABLE_PROMETHEUS_NODE_EXPORTER true)
ENABLE_FAIL2BAN=$(get_config ENABLE_FAIL2BAN true)
ENABLE_WAZUH_AGENT=$(get_config ENABLE_WAZUH_AGENT false)
ENABLE_APACHE_MODULES=$(get_config ENABLE_APACHE_MODULES true)
ENABLE_REMOTEIP=$(get_config ENABLE_REMOTEIP true)
ENABLE_APACHE_SECURITY=$(get_config ENABLE_APACHE_SECURITY true)

run_module_if_enabled ENABLE_APACHE "$ENABLE_APACHE" "Apache installation" install_apache
run_module_if_enabled ENABLE_MYSQL "$ENABLE_MYSQL" "MySQL installation" install_mysql
run_module_if_enabled ENABLE_PHP "$ENABLE_PHP" "PHP installation" install_php
run_module_if_enabled ENABLE_PHP_TEST_FILE "$ENABLE_PHP_TEST_FILE" "PHP test file setup" create_php_test_file
run_module_if_enabled ENABLE_PHPMYADMIN "$ENABLE_PHPMYADMIN" "phpMyAdmin installation" install_phpmyadmin
run_module_if_enabled ENABLE_PROMETHEUS_NODE_EXPORTER "$ENABLE_PROMETHEUS_NODE_EXPORTER" "Prometheus Node Exporter installation" install_prometheus_node_exporter
run_module_if_enabled ENABLE_FAIL2BAN "$ENABLE_FAIL2BAN" "fail2ban installation" install_fail2ban
run_module_if_enabled ENABLE_WAZUH_AGENT "$ENABLE_WAZUH_AGENT" "Wazuh agent installation" install_wazuh_agent
run_module_if_enabled ENABLE_APACHE_MODULES "$ENABLE_APACHE_MODULES" "Apache module enablement" enable_apache_modules
run_module_if_enabled ENABLE_REMOTEIP "$ENABLE_REMOTEIP" "RemoteIP configuration" configure_remoteip
run_module_if_enabled ENABLE_APACHE_SECURITY "$ENABLE_APACHE_SECURITY" "Apache security hardening" apache_security

restart_services
prepare_env_file
summary

}

main
