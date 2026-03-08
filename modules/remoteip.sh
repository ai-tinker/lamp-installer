configure_remoteip() {

CONF="/etc/apache2/conf-available/remoteip.conf"
SRC="$BASE_DIR/files/remoteip.conf"

if [ -f "$CONF" ]; then
warn "remoteip config exists, ensuring Apache conf is enabled"
else
info "Installing remoteip configuration"
cp "$SRC" "$CONF"
fi

a2enconf remoteip >> "$LOGFILE"

}
