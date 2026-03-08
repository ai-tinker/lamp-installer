install_mysql() {

if dpkg -l | grep -q mysql-server; then
warn "MySQL already installed"
return
fi

info "Installing MySQL"

DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server >> "$LOGFILE"

systemctl enable mysql
systemctl start mysql

}