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
    # PHP 8.x
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
    # MySQL (Native Repo)
    ################################
    echo "Installing MySQL..."

    dnf -y install mysql-server
    systemctl enable --now mysqld

    ################################
    # Secure MySQL
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
    # Apache configs (your block)
    ################################
    echo "Configuring Apache virtual host..."

    grep -q "ServerName 127.0.0.1" /etc/httpd/conf/httpd.conf || \
        echo 'ServerName 127.0.0.1' >> /etc/httpd/conf/httpd.conf

    mkdir -p /etc/httpd/vhosts.d

    # Copy only if files exist
    [[ -f mydomain.conf ]] && cp mydomain.conf /etc/httpd/vhosts.d/
    [[ -f ssl-mydomain.conf-default ]] && cp ssl-mydomain.conf-default /etc/httpd/vhosts.d/

    mkdir -p /var/www/vhosts/mydomain

    grep -q "mydomain.com" /etc/hosts || \
        echo '127.0.0.1 mydomain.com' >> /etc/hosts

    cat > /var/www/vhosts/mydomain/index.php <<EOF
<?php phpinfo(); ?>
EOF

    grep -q "vhosts.d" /etc/httpd/conf/httpd.conf || \
        echo 'Include vhosts.d/*.conf' >> /etc/httpd/conf/httpd.conf

    apachectl configtest

    if apachectl -S; then
        apachectl graceful
        curl --silent http://mydomain.com/index.php | grep -w 'head' || true
    else
        echo 'apache config failed, check errors'
    fi

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
    # MySQL
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

    grep -q "mydomain.com" /etc/hosts || \
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
