install_mysql() {

if dpkg -l | grep -q mysql-server; then
warn "MySQL already installed, ensuring required package and service state"
else
info "Installing MySQL"
fi

DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server >> "$LOGFILE"

systemctl enable mysql
systemctl start mysql

}
