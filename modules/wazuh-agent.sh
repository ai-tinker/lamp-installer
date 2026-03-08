install_wazuh_agent() {

WAZUH_MANAGER_IP="${WAZUH_MANAGER_IP:-10.1.8.4}"
WAZUH_LIST="/etc/apt/sources.list.d/wazuh.list"
WAZUH_KEYRING="/usr/share/keyrings/wazuh.gpg"
WAZUH_CONF="/var/ossec/etc/ossec.conf"

if dpkg -l | grep -q wazuh-agent; then
warn "wazuh-agent already installed"
else
info "Installing Wazuh repository prerequisites"
apt-get install -y curl gnupg apt-transport-https >> "$LOGFILE"

if [ ! -f "$WAZUH_KEYRING" ]; then
info "Installing Wazuh GPG key"
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --dearmor -o "$WAZUH_KEYRING"
fi

if [ ! -f "$WAZUH_LIST" ]; then
info "Adding Wazuh apt repository"
echo "deb [signed-by=$WAZUH_KEYRING] https://packages.wazuh.com/4.x/apt/ stable main" > "$WAZUH_LIST"
fi

info "Updating package index for Wazuh repository"
apt-get update -y >> "$LOGFILE"

info "Installing wazuh-agent"
WAZUH_MANAGER="$WAZUH_MANAGER_IP" apt-get install -y wazuh-agent >> "$LOGFILE"
fi

if [ -f "$WAZUH_CONF" ]; then
info "Configuring Wazuh manager address: $WAZUH_MANAGER_IP"
sed -i "0,/<address>.*<\\/address>/s//<address>${WAZUH_MANAGER_IP}<\\/address>/" "$WAZUH_CONF"
fi

systemctl daemon-reload
systemctl enable wazuh-agent
systemctl restart wazuh-agent

}
