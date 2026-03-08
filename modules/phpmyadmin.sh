install_phpmyadmin() {
  if dpkg -l | grep -q phpmyadmin; then
    warn "phpMyAdmin already installed"
    return
  fi

  info "Installing phpMyAdmin (preseeded non-interactive)"

  echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
  echo "phpmyadmin phpmyadmin/dbconfig-install boolean false" | debconf-set-selections

  DEBIAN_FRONTEND=noninteractive apt-get install -y phpmyadmin >> "$LOGFILE"

  if [ -f /etc/phpmyadmin/apache.conf ] && [ ! -f /etc/apache2/conf-available/phpmyadmin.conf ]; then
    ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-available/phpmyadmin.conf
  fi

  a2enconf phpmyadmin >> "$LOGFILE"
}
