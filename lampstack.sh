#!/bin/bash
#Script to Auto Install LAMP Stack
#Author nabil@techie.com

E_BADARGS=65
DATE=$(date +"%Y%m%d-%T")

#OSVERSION=`cat /etc/os-release | grep -w 'ID' | sed -e 's/"//g' -e 's/ID=//';`
OSVERSION=`grep -w 'ID' < /etc/os-release | sed -e 's/"//g' -e 's/ID=//';`
LOGS="/tmp/lampstack.log"

DBPASS="pakistan"
# Must be root to run
if [[ ${UID} -ne 0 ]]; then
	        echo "You must be root to run this script"
		exit $E_BADARGS
fi

#Starting Installation

if [[ $OSVERSION == "ol" ]] ||  [[ $OSVERSION == "centos" ]] ||  [[ $OSVERSION == "redhat" ]]; then
	echo "Installing LAMP on $OSVERSION"
	yum update -y
	yum install httpd httpd-tools vim net-tools -y
	systemctl start httpd
	systemctl enable httpd
	ps aux | grep httpd
#	systemctl status httpd;
#	apachectl graceful
#	apachectl -S
	yum install php php-fpm php-mysqlnd php-opcache php-gd php-xml php-mbstring -y
	systemctl start php-fpm
	systemctl enable php-fpm
	yum install mariadb-server mariadb -y
	systemctl start mariadb
	systemctl enable mariadb
	mysql_secure_installation <<EOF

y
$DBPASS
$DBPASS
y
y
y
y
EOF
	#Apache configs
	echo 'ServerName 127.0.0.1' >> /etc/httpd/conf/httpd.conf
	mkdir /etc/httpd/vhosts.d
	cp mydomain.conf /etc/httpd/vhosts.d/
	cp ssl-mydomain.conf-default /etc/httpd/vhosts.d/
	mkdir -p /var/www/vhosts/mydomain
	echo '127.0.0.1 mydomain.com' >> /etc/hosts
	touch /var/www/vhosts/mydomain/index.php
	echo '<?php phpinfo() ?>' >> /var/www/vhosts/mydomain/index.php
	echo 'Include vhosts.d/*.conf' >> /etc/httpd/conf/httpd.conf
	apachectl configtest
	#Check if Apache is OK then reload
	if apachectl -S; then
	  apachectl graceful
	  curl --silent http://mydomain.com/index.php | grep -w 'head'
	else
  	echo 'apache config failed, check errors'
	fi
	echo 'Database Password:'
	echo $DBPASS
	#mysql -uroot -p
	#Enable PHP/HTTPD Modules if required.
	#a2enmod rewrite
	#phpenmod mcrypt
	
	#Enable port on firewall
	#firewall-cmd --permanent --zone=public --add-service=http
	#firewall-cmd --permanent --zone=public --add-service=https
	#systemctl reload firewalld
elif [[ $OSVERSION == "debian" ]] ||  [[ $OSVERSION == "ubuntu" ]] ||  [[ $OSVERSION == "pop" ]]; then
	echo "Section in progress"

elif [[ $OSVERSION == "unknown" ]]
then
	echo "OS Unknown! ----- $OSVERSION "

else
	echo "OS does not match required configurations!"
fi









#if [[ $CHECK == "no" ]] || [[ -z "$CHECK" ]];
#then
#	echo -n "OK: No SSH ROOT access enabled, "
#else
#	echo -n "CRITICAL: SSH ROOT access is enabled, "
#fi
#
#
#if [ ! -f $LINUXHOSTFILE ]; then
#	echo "No $LINUXHOSTFILE found!!";
#	exit 1;
#fi
