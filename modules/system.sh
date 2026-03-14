EXIT_OK=0
EXIT_RUNTIME=1
EXIT_USAGE=2
EXIT_CONFIG=3

log() {
echo "$(date '+%F %T') $1" | tee -a "$LOGFILE"
}

info() { log "[INFO] $1"; }
warn() { log "[WARN] $1"; }
error() { log "[ERROR] $1"; }

check_root() {

if [ "$EUID" -ne 0 ]; then
error "Run as root"
exit "$EXIT_USAGE"
fi

}

update_repo() {

info "Updating repository"
apt-get update -y >> "$LOGFILE"

}

restart_services() {

if systemctl list-unit-files | grep -q '^apache2\.service'; then
info "Restarting Apache"
systemctl restart apache2 || warn "Failed to restart Apache"
else
warn "Apache service not installed, skipping restart"
fi

if systemctl list-unit-files | grep -q '^mysql\.service'; then
info "Restarting MySQL"
systemctl restart mysql || warn "Failed to restart MySQL"
else
warn "MySQL service not installed, skipping restart"
fi

}

summary() {

echo ""
echo "================================="
echo "LAMP INSTALLATION COMPLETED"
echo "================================="
echo ""

}
