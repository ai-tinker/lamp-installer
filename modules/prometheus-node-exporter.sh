install_prometheus_node_exporter() {

if dpkg -l | grep -q prometheus-node-exporter; then
warn "prometheus-node-exporter already installed"
return
fi

info "Installing prometheus-node-exporter"

apt-get install -y prometheus-node-exporter >> "$LOGFILE"
systemctl enable prometheus-node-exporter
systemctl start prometheus-node-exporter

}

