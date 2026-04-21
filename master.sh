#!/bin/bash
# LAMP Stack Installer (Native MySQL + PHP 8.x)
# Author: nabil@techie.com

set -e

DBPASS="pakistan"
OS_ID=$(grep -w ID /etc/os-release | cut -d= -f2 | tr -d '"')

if [[ $EUID -ne 0 ]]; then
    echo "Run as root"
    exit 1
fi

########################################
# RHEL / OL / Rocky / Alma (8/9)
########################################
if [[ "$OS_ID" =~ ^(ol|rhel|centos|rocky|almalinux)$ ]]; then

    echo "Detected RHEL-based OS: $OS_ID"

    OS_MAJOR=$(rpm -E %{rhel})

    dnf -y update

    ################################
    # Apache
    ################################
    dnf -y install httpd httpd-tools mod_ssl vim net-tools curl
    systemctl enable --now httpd

    ################################
    # PHP 8.x (latest available in AppStream)
    ################################
    echo "Installing PHP 8.x..."

    dnf -y module reset php

    if [[ $OS_MAJOR -eq 8 ]]; then
        dnf -y module enable php:8.1
    elif [[ $OS_MAJOR -eq 9 ]]; then
        dnf -y module enable php:8.2
    fi

    dnf -y install \
        php php-fpm php-mysqlnd php-opcache php-gd php-xml php-mbstring php-cli php-curl

    systemctl enable --now php-fpm

    ################################
    # MySQL (Native Oracle Linux Repo)
    ################################
    echo "Installing MySQL from native OS repo..."

    dnf -y install mysql-server

    systemctl enable --now mysqld

    ################################
    # Secure MySQL (OL default setup)
    ################################
    MYSQL_TEMP_PASS=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}' || true)

    if [[ -n "$MYSQL_TEMP_PASS" ]]; then
mysql --connect-expired-password -uroot -p"$MYSQL_TEMP_PASS" <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '$DBPASS';
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
FLUSH PRIVILEGES;
EOF
    else
mysql -uroot <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '$DBPASS';
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
FLUSH PRIVILEGES;
EOF
    fi

    ################################
    # Apache config
    ################################
    echo "ServerName 127.0.0.1" >> /etc/httpd/conf/httpd.conf

    mkdir -p /var/www/vhosts/mydomain

    cat > /var/www/vhosts/mydomain/index.php <<EOF
<?php phpinfo(); ?>
EOF

    echo "127.0.0.1 mydomain.com" >> /etc/hosts

    apachectl configtest && systemctl reload httpd

########################################
# Debian / Ubuntu / Pop!_OS
########################################
elif [[ "$OS_ID" =~ ^(debian|ubuntu|pop)$ ]]; then

    echo "Detected Debian-based OS: $OS_ID"

    apt update -y

    ################################
    # Apache
    ################################
    apt install -y apache2 curl vim net-tools
    systemctl enable --now apache2

    ################################
    # PHP 8.x
    ################################
    apt install -y \
        php php-fpm php-mysql php-cli php-gd php-xml php-mbstring php-curl

    ################################
    # MySQL (native apt repo)
    ################################
    DEBIAN_FRONTEND=noninteractive apt install -y mysql-server
    systemctl enable --now mysql

    mysql -uroot <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$DBPASS';
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
FLUSH PRIVILEGES;
EOF

    ################################
    # Apache config
    ################################
    mkdir -p /var/www/html/mydomain

    cat > /var/www/html/mydomain/index.php <<EOF
<?php phpinfo(); ?>
EOF

    echo "127.0.0.1 mydomain.com" >> /etc/hosts

    systemctl restart apache2

else
    echo "Unsupported OS: $OS_ID"
    exit 1
fi

########################################
# Final Output
########################################
echo "===================================="
echo "LAMP Installation Completed"
echo "PHP Version: $(php -v | head -n 1)"
echo "MySQL Root Password: $DBPASS"
echo "URL: http://mydomain.com"
echo "===================================="
