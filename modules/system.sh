log() {
echo "$(date '+%F %T') $1" | tee -a "$LOGFILE"
}

info() { log "[INFO] $1"; }
warn() { log "[WARN] $1"; }
error() { log "[ERROR] $1"; }

check_root() {

if [ "$EUID" -ne 0 ]; then
error "Run as root"
exit 1
fi

}

update_repo() {

info "Updating repository"
apt-get update -y >> "$LOGFILE"

}

restart_services() {

info "Restarting Apache"
systemctl restart apache2

info "Restarting MySQL"
systemctl restart mysql

}

summary() {

echo ""
echo "================================="
echo "LAMP INSTALLATION COMPLETED"
echo "================================="
echo ""

}