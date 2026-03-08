#!/bin/bash

############################################################
# ACCOUNT CREATOR
# Read configuration from /tmp/data.txt
############################################################

CONFIG="/tmp/.env" # was "/tmp/data.txt"

if [ ! -f "$CONFIG" ]; then
echo "[ERROR] Config file not found: $CONFIG"
exit 1
fi

############################################################
# CONFIG PARSER
############################################################

get_config() {

KEY="$1"

grep -E "^[[:space:]]*$KEY[[:space:]]*=" "$CONFIG" \
| head -n1 \
| cut -d '=' -f2- \
| sed 's/^[ \t]*//;s/[ \t]*$//'

}

############################################################
# LOAD VARIABLES
############################################################

sshuser=$(get_config sshuser)
sshpwd=$(get_config sshpwd)

myuser=$(get_config myuser)
mypwd=$(get_config mypwd)

############################################################
# VALIDATION
############################################################

if [ -z "$sshuser" ] || [ -z "$sshpwd" ]; then
echo "[ERROR] sshuser or sshpwd not defined"
exit 1
fi

if [ -z "$myuser" ] || [ -z "$mypwd" ]; then
echo "[ERROR] myuser or mypwd not defined"
exit 1
fi

############################################################
# INFO
############################################################

echo ""
echo "======================================"
echo "Account Creation Script"
echo "======================================"
echo ""

echo "SSH USER  : $sshuser"
echo "MYSQL USER: $myuser"
echo ""

############################################################
# CHECK SSH USER
############################################################

echo "[INFO] Checking SSH user..."

if id "$sshuser" >/dev/null 2>&1; then
echo "[ERROR] SSH user '$sshuser' already exists"
exit 1
fi

############################################################
# CREATE SSH USER
############################################################

echo "[INFO] Creating SSH user..."

useradd -m -s /bin/bash "$sshuser"

echo "$sshuser:$sshpwd" | chpasswd

usermod -aG sudo "$sshuser"

echo "[OK] SSH user created and added to sudo group"

############################################################
# MYSQL ROOT PASSWORD HANDLING
############################################################

echo ""
echo "[INFO] Checking MySQL root password..."

mysql -uroot -e "SELECT 1;" >/dev/null 2>&1
ROOT_NO_PASSWORD=$?

if [ "$myuser" = "root" ]; then

    if [ $ROOT_NO_PASSWORD -eq 0 ]; then
        echo "[INFO] MySQL root password is empty, setting password..."

        mysql -uroot <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '$mypwd';
FLUSH PRIVILEGES;
EOF

        echo "[OK] MySQL root password configured"

    else
        echo "[WARN] MySQL root already has a password. Skipping change."
    fi

else

############################################################
# CREATE MYSQL USER
############################################################

echo "[INFO] Creating MySQL user..."

USER_EXISTS=$(mysql -uroot -Nse "SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user='$myuser');")

if [ "$USER_EXISTS" = "1" ]; then
echo "[WARN] MySQL user already exists"
else

mysql -uroot <<EOF
CREATE USER '$myuser'@'localhost' IDENTIFIED BY '$mypwd';
GRANT ALL PRIVILEGES ON *.* TO '$myuser'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

echo "[OK] MySQL user created"

fi

fi

############################################################

echo ""
echo "======================================"
echo "Completed"
echo "======================================"
echo ""

