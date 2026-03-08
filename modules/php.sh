install_php() {

if dpkg -l | grep -q php-cli; then
warn "PHP already installed, ensuring required PHP packages"
else
info "Installing PHP"
fi

apt-get install -y \
php \
php-cli \
php-common \
php-mysql \
php-curl \
php-gd \
php-mbstring \
php-xml \
php-zip \
php-bcmath \
php-intl \
libapache2-mod-php >> "$LOGFILE"

}

create_php_test_file() {

if [ -f /var/www/html/info.php ]; then
warn "PHP test file already exists"
return
fi

info "Creating PHP test file at /var/www/html/info.php"
cat > /var/www/html/info.php <<'EOF'
<?php
phpinfo();
EOF

}
