#!/bin/bash
#Script to Auto Install LAMP Stack
#Author nabil@techie.com

E_BADARGS=65
DATE=$(date +"%Y%m%d-%T")

OSVERSION=`cat /etc/os-release | grep -w 'ID' | sed -e 's/"//g' -e 's/ID=//';`
LOGS="/tmp/lampstack.log"

DBPASS="pakistan"
# Must be root to run
if [[ ${UID} -ne 0 ]]; then
	        echo "You must be root to run this script"
		exit $E_BADARGS
fi

#Starting Installation

if [[ $OSVERSION == "ol" ]]
then
	echo "Installing LAMP on Oracle Linux"
	yum update -y
	yum install httpd httpd-tools vim net-tools -y
	systemctl start httpd
	systemctl enable httpd
	systemctl status httpd
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
	#mysql -uroot -p
	#Enable PHP/HTTPD Modules if required.
	#a2enmod rewrite
	#phpenmod mcrypt
	
	#Enable port on firewall
	#firewall-cmd --permanent --zone=public --add-service=http
	#firewall-cmd --permanent --zone=public --add-service=https
	#systemctl reload firewalld
elif [[ $OSVERSION == "centos" ]]
then
	echo "Section in progress"

elif [[ $OSVERSION == "debian" ]]
then
	echo "Section in progress"

elif [[ $OSVERSION == "centos" ]]
then
	echo "Section in progress"

else
	echo "OS does not match!"
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
