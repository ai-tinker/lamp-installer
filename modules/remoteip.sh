configure_remoteip() {

CONF="/etc/apache2/conf-available/remoteip.conf"
SRC="$BASE_DIR/files/remoteip.conf"

if [ -f "$CONF" ]; then
warn "remoteip already configured"
return
fi

info "Installing remoteip configuration"

cp "$SRC" "$CONF"

a2enconf remoteip >> "$LOGFILE"

}