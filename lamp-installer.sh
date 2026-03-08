#!/bin/bash

############################################################
# PROFESSIONAL LAMP INSTALLER
# Ubuntu 22.04 / 24.04
############################################################

set -e

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
MODULE_DIR="$BASE_DIR/modules"

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

main() {

clear

info "Starting LAMP Installer"

check_root
update_repo

install_apache
install_mysql
install_php
create_php_test_file
install_phpmyadmin
install_prometheus_node_exporter
install_fail2ban
# install_wazuh_agent

enable_apache_modules
configure_remoteip
apache_security

restart_services
summary

}

main
