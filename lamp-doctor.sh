#!/bin/bash

############################################################
# LAMP DOCTOR
# Advanced LAMP diagnostic tool
############################################################

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
NC="\e[0m"

PASS=0
WARN=0
FAIL=0

print_header() {

echo ""
echo "=============================================================="
echo "                    LAMP DOCTOR REPORT"
echo "=============================================================="
echo ""

printf "%-28s | %-7s | %s\n" "COMPONENT" "STATUS" "DETAIL"
printf "%s\n" "--------------------------------------------------------------"

}

check() {

NAME=$1
STATUS=$2
DETAIL=$3

case $STATUS in

OK)
COLOR=$GREEN
((PASS++))
;;

WARN)
COLOR=$YELLOW
((WARN++))
;;

FAIL)
COLOR=$RED
((FAIL++))
;;

esac

printf "%-28s | ${COLOR}%-7s${NC} | %s\n" "$NAME" "$STATUS" "$DETAIL"

}

############################################################
# APACHE CHECK
############################################################

check_apache() {

if systemctl is-active --quiet apache2; then
check "Apache Service" OK "Running"
else
check "Apache Service" FAIL "Not running"
fi

if command -v apache2 >/dev/null; then
VER=$(apache2 -v | head -1)
check "Apache Version" OK "$VER"
else
check "Apache Version" FAIL "Not installed"
fi

if apache2ctl configtest >/dev/null 2>&1; then
check "Apache Config" OK "Syntax OK"
else
check "Apache Config" FAIL "Syntax error"
fi

}

############################################################
# MYSQL CHECK
############################################################

check_mysql() {

if systemctl is-active --quiet mysql; then
check "MySQL Service" OK "Running"
else
check "MySQL Service" FAIL "Not running"
fi

if command -v mysql >/dev/null; then
VER=$(mysql --version)
check "MySQL Client" OK "$VER"
else
check "MySQL Client" FAIL "Missing"
fi

mysqladmin ping >/dev/null 2>&1

if [ $? -eq 0 ]; then
check "MySQL Connection" OK "Database responding"
else
check "MySQL Connection" WARN "Cannot ping database"
fi

}

############################################################
# PHP CHECK
############################################################

check_php() {

if command -v php >/dev/null; then
VER=$(php -v | head -1)
check "PHP CLI" OK "$VER"
else
check "PHP CLI" FAIL "Missing"
fi

MODULES=(curl gd mbstring mysqli xml zip intl)

for MOD in "${MODULES[@]}"; do

php -m | grep -q "$MOD"

if [ $? -eq 0 ]; then
check "PHP module $MOD" OK "Loaded"
else
check "PHP module $MOD" WARN "Missing"
fi

done

}

############################################################
# APACHE MODULE CHECK
############################################################

check_apache_modules() {

MODULES=(rewrite ssl headers remoteip)

for MOD in "${MODULES[@]}"; do

apache2ctl -M | grep -q "$MOD"

if [ $? -eq 0 ]; then
check "Apache mod_$MOD" OK "Enabled"
else
check "Apache mod_$MOD" FAIL "Disabled"
fi

done

}

############################################################
# CONFIG FILE CHECK
############################################################

check_configs() {

[ -f /etc/apache2/conf-enabled/remoteip.conf ] \
&& check "RemoteIP Config" OK "Installed" \
|| check "RemoteIP Config" WARN "Missing"

[ -f /etc/apache2/conf-enabled/security-hardening.conf ] \
&& check "Security Hardening" OK "Enabled" \
|| check "Security Hardening" WARN "Missing"

[ -f /etc/apache2/conf-enabled/phpmyadmin.conf ] \
&& check "phpMyAdmin Config" OK "Enabled" \
|| check "phpMyAdmin Config" WARN "Missing"

}

############################################################
# FILE CHECK
############################################################

check_files() {

[ -f /var/www/html/info.php ] \
&& check "PHP Test File" OK "Exists" \
|| check "PHP Test File" WARN "Missing"

}

############################################################
# PORT CHECK
############################################################

check_ports() {

ss -tuln | grep -q ":80 " \
&& check "Port 80" OK "Listening" \
|| check "Port 80" FAIL "Closed"

ss -tuln | grep -q ":443 " \
&& check "Port 443" OK "Listening" \
|| check "Port 443" WARN "Closed"

ss -tuln | grep -q ":3306 " \
&& check "MySQL Port" OK "Listening" \
|| check "MySQL Port" WARN "Closed"

}

############################################################
# FIREWALL CHECK
############################################################

check_firewall() {

if command -v ufw >/dev/null; then

STATUS=$(ufw status | head -1)

check "Firewall UFW" OK "$STATUS"

else

check "Firewall UFW" WARN "Not installed"

fi

}

############################################################
# VHOST CHECK
############################################################

check_vhost() {

COUNT=$(ls /etc/apache2/sites-enabled | wc -l)

if [ "$COUNT" -gt 0 ]; then
check "Apache VirtualHost" OK "$COUNT enabled"
else
check "Apache VirtualHost" WARN "No site enabled"
fi

}

############################################################
# SCORE
############################################################

print_score() {

TOTAL=$((PASS+WARN+FAIL))

SCORE=$(( PASS * 100 / TOTAL ))

echo ""
echo "=============================================================="
echo "RESULT SUMMARY"
echo "--------------------------------------------------------------"

printf "PASS : %s\n" "$PASS"
printf "WARN : %s\n" "$WARN"
printf "FAIL : %s\n" "$FAIL"

echo ""

printf "SYSTEM HEALTH SCORE : %s%%\n" "$SCORE"

echo "=============================================================="
echo ""

}

############################################################
# MAIN
############################################################

print_header

check_apache
check_mysql
check_php
check_apache_modules
check_configs
check_files
check_ports
check_firewall
check_vhost

print_score

