install_prometheus_node_exporter() {

if dpkg -l | grep -q prometheus-node-exporter; then
warn "prometheus-node-exporter already installed, ensuring service state"
else
info "Installing prometheus-node-exporter"
apt-get install -y prometheus-node-exporter >> "$LOGFILE"
fi

systemctl enable prometheus-node-exporter
systemctl start prometheus-node-exporter

}
