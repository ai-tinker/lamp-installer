install_apache() {

if dpkg -l | grep -q apache2; then
warn "Apache already installed, ensuring required packages and service state"
else
info "Installing Apache"
fi

apt-get install -y apache2 apache2-utils >> "$LOGFILE"

systemctl enable apache2
systemctl start apache2

}

enable_apache_modules() {

info "Enabling Apache modules"

a2enmod rewrite >> "$LOGFILE"
a2enmod ssl >> "$LOGFILE"
a2enmod headers >> "$LOGFILE"
a2enmod remoteip >> "$LOGFILE"

}
