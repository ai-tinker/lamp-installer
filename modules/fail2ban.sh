install_fail2ban() {

if dpkg -l | grep -q fail2ban; then
warn "fail2ban already installed"
return
fi

info "Installing fail2ban"

apt-get install -y fail2ban >> "$LOGFILE"
systemctl enable fail2ban
systemctl start fail2ban

}
