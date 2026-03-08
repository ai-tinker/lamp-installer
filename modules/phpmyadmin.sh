install_phpmyadmin() {
  NEED_INSTALL=1

  if dpkg -l | grep -q phpmyadmin; then
    warn "phpMyAdmin already installed, ensuring Apache integration"
    NEED_INSTALL=0
  fi

  if [ "$NEED_INSTALL" -eq 1 ]; then
    info "Installing phpMyAdmin (preseeded non-interactive)"

    echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
    echo "phpmyadmin phpmyadmin/dbconfig-install boolean false" | debconf-set-selections

    DEBIAN_FRONTEND=noninteractive apt-get install -y phpmyadmin >> "$LOGFILE"
  fi

  if [ -f /etc/phpmyadmin/apache.conf ] && [ ! -f /etc/apache2/conf-available/phpmyadmin.conf ]; then
    ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-available/phpmyadmin.conf
  fi

  PHPMYADMIN_APACHE_CONF="/etc/apache2/conf-available/phpmyadmin.conf"
  if [ ! -f "$PHPMYADMIN_APACHE_CONF" ] && [ -f /etc/phpmyadmin/apache.conf ]; then
    PHPMYADMIN_APACHE_CONF="/etc/phpmyadmin/apache.conf"
  fi

  if [ -f "$PHPMYADMIN_APACHE_CONF" ]; then
    if grep -Eq "^[[:space:]]*Alias[[:space:]]+/phpmyadmin[[:space:]]+/usr/share/phpmyadmin" "$PHPMYADMIN_APACHE_CONF"; then
      info "Updating phpMyAdmin Alias to /db/php-myadmin"
      sed -i -E "s#^[[:space:]]*Alias[[:space:]]+/phpmyadmin[[:space:]]+/usr/share/phpmyadmin#Alias /db/php-myadmin /usr/share/phpmyadmin#" "$PHPMYADMIN_APACHE_CONF"
    elif grep -Eq "^[[:space:]]*Alias[[:space:]]+/db/php-myadmin[[:space:]]+/usr/share/phpmyadmin" "$PHPMYADMIN_APACHE_CONF"; then
      warn "phpMyAdmin Alias already set to /db/php-myadmin"
    else
      warn "phpMyAdmin Alias line not found in $PHPMYADMIN_APACHE_CONF"
    fi
  else
    warn "phpMyAdmin Apache config not found for Alias update"
  fi

  a2enconf phpmyadmin >> "$LOGFILE"
}
