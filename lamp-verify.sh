#!/bin/bash

############################################################
# LAMP INSTALLATION VERIFICATION
############################################################

SEP="============================================================"
LINE="------------------------------------------------------------"

printf "\n"
printf "%s\n" "$SEP"
printf "%s\n" "           LAMP INSTALLATION VERIFICATION REPORT"
printf "%s\n" "$SEP"
printf "\n"

PASS="OK"
FAIL="FAIL"
WARN="WARN"

check() {

NAME="$1"
RESULT="$2"
DETAIL="$3"

printf "%-25s | %-6s | %s\n" "$NAME" "$RESULT" "$DETAIL"

}

printf "%-25s | %-6s | %s\n" "COMPONENT" "STATUS" "DETAIL"
printf "%s\n" "$LINE"

############################################################
# APACHE
############################################################

if systemctl is-active --quiet apache2 2>/dev/null; then
check "Apache Service" "$PASS" "Running"
else
check "Apache Service" "$FAIL" "Not running"
fi

if dpkg -l | grep -q apache2; then
VERSION=$(apache2 -v | head -1)
check "Apache Package" "$PASS" "$VERSION"
else
check "Apache Package" "$FAIL" "Not installed"
fi

############################################################
# MYSQL
############################################################

if systemctl is-active --quiet mysql 2>/dev/null; then
check "MySQL Service" "$PASS" "Running"
else
check "MySQL Service" "$FAIL" "Not running"
fi

if command -v mysql >/dev/null 2>&1; then
VERSION=$(mysql --version)
check "MySQL Client" "$PASS" "$VERSION"
else
check "MySQL Client" "$FAIL" "Not installed"
fi

############################################################
# PHP
############################################################

if command -v php >/dev/null 2>&1; then
VERSION=$(php -v | head -1)
check "PHP CLI" "$PASS" "$VERSION"
else
check "PHP CLI" "$FAIL" "Not installed"
fi

############################################################
# APACHE MODULES
############################################################

apache2ctl -M 2>/dev/null | grep -q rewrite && \
check "Apache mod_rewrite" "$PASS" "Enabled" || \
check "Apache mod_rewrite" "$FAIL" "Disabled"

apache2ctl -M 2>/dev/null | grep -q ssl && \
check "Apache mod_ssl" "$PASS" "Enabled" || \
check "Apache mod_ssl" "$FAIL" "Disabled"

apache2ctl -M 2>/dev/null | grep -q headers && \
check "Apache mod_headers" "$PASS" "Enabled" || \
check "Apache mod_headers" "$FAIL" "Disabled"

apache2ctl -M 2>/dev/null | grep -q remoteip && \
check "Apache mod_remoteip" "$PASS" "Enabled" || \
check "Apache mod_remoteip" "$FAIL" "Disabled"

############################################################
# REMOTEIP CONFIG
############################################################

if [ -f /etc/apache2/conf-enabled/remoteip.conf ]; then
check "RemoteIP Config" "$PASS" "Installed"
else
check "RemoteIP Config" "$FAIL" "Missing"
fi

############################################################
# SECURITY HARDENING
############################################################

if [ -f /etc/apache2/conf-enabled/security-hardening.conf ]; then
check "Apache Security" "$PASS" "Enabled"
else
check "Apache Security" "$WARN" "Not installed"
fi

############################################################
# PHPMYADMIN
############################################################

if dpkg -l | grep -q phpmyadmin; then
check "phpMyAdmin Package" "$PASS" "Installed"
else
check "phpMyAdmin Package" "$FAIL" "Missing"
fi

if [ -f /etc/apache2/conf-enabled/phpmyadmin.conf ]; then
check "phpMyAdmin Config" "$PASS" "Enabled"
else
check "phpMyAdmin Config" "$WARN" "Not enabled"
fi

############################################################
# PHP TEST FILE
############################################################

if [ -f /var/www/html/info.php ]; then
check "PHP Test File" "$PASS" "/var/www/html/info.php"
else
check "PHP Test File" "$WARN" "Missing"
fi

############################################################
# PORT CHECK
############################################################

if ss -tuln | grep -q ":80 "; then
check "Port 80" "$PASS" "Listening"
else
check "Port 80" "$FAIL" "Closed"
fi

if ss -tuln | grep -q ":443 "; then
check "Port 443" "$PASS" "Listening"
else
check "Port 443" "$WARN" "Not active"
fi

############################################################

printf "\n"
printf "%s\n" "$SEP"
printf "%s\n" "Verification completed"
printf "%s\n" "$SEP"
printf "\n"