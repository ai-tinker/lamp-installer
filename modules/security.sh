apache_security() {

CONF="/etc/apache2/conf-available/security-hardening.conf"

if [ -f "$CONF" ]; then
warn "Security config exists"
return
fi

info "Applying Apache security hardening"

cat <<EOF > "$CONF"

ServerTokens Prod
ServerSignature Off

<IfModule mod_headers.c>

Header always set X-Content-Type-Options "nosniff"
Header always set X-Frame-Options "SAMEORIGIN"
Header always set X-XSS-Protection "1; mode=block"

</IfModule>

EOF

a2enconf security-hardening >> "$LOGFILE"

}

