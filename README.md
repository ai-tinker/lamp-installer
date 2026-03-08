# lamp-installer


lxc launch ubuntu:24.04/amd64 hardening5
./fix-logind.sh hardening5


sudo mkdir /mnt/h && sudo chown ubuntu:ubuntu /mnt/h & sudo apt update -y && sudo apt install sshfs -y && sudo sshfs ubuntu@10.24.7.27:/home/ubuntu/ /mnt/h/ -o allow_other -o rw && cd /mnt/h

