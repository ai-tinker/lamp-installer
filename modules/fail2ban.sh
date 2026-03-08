install_fail2ban() {

if dpkg -l | grep -q fail2ban; then
warn "fail2ban already installed, ensuring service state"
else
info "Installing fail2ban"
apt-get install -y fail2ban >> "$LOGFILE"
fi

systemctl enable fail2ban
systemctl start fail2ban

}
