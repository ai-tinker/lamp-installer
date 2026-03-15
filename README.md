# lamp-installer


lxc launch ubuntu:24.04/amd64 hardening5
./fix-logind.sh hardening5


sudo mkdir /mnt/h && sudo chown ubuntu:ubuntu /mnt/h & sudo apt update -y && sudo apt install sshfs -y && sudo sshfs ubuntu@10.24.7.180:/home/ubuntu/devel /mnt/h/ -o allow_other -o rw && cd /mnt/h

## Module Toggle via .env

`lamp-installer.sh` membaca flag `ENABLE_*` dari `.env` untuk menentukan modul yang dijalankan.

Contoh:

```env
ENABLE_PHPMYADMIN = false
ENABLE_PROMETHEUS_NODE_EXPORTER = true
ENABLE_WAZUH_AGENT = false
```

Nilai yang didukung: `true/false`, `1/0`, `yes/no`, `on/off` (case-insensitive).

Tambahan:
ClamAv