#!/bin/bash

E_BADARGS=65
DATE=$(date +"%Y%m%d-%T")

# Must be root to run
if [[ ${UID} -ne 0 ]]; then
	        echo "You must be root to run this script"
		        exit $E_BADARGS
fi
#Check for arguments
#if [ -z $1 ] || [ -z $2 ] || [ -z $3 ]; then
if [ -z $1 ]; then
	        #echo "Usage: `basename $0` /<dir> <PathToBackupDirectory>"
	        echo "Usage: sudo bash `basename $0` <Domain Name>"
	        exit $E_BADARGS
fi

DOMAINNAME=$1

DEFAULTFILE="/etc/httpd/vhosts.d/mydomain.conf"

if [ ! -f $DEFAULTFILE ]; then
	echo "No $DEFAULTFILE found!!";
	exit 1;
fi

#/bin/cp -rf $LINUXHOSTFILE $BKDST/linuxhosts.cfg-$DATE

cp $DEFAULTFILE /etc/httpd/vhosts.d/$DOMAINNAME.conf

sed -i 's/mydomain/$DOMAINNAME/g' /etc/httpd/vhosts.d/$DOMAINNAME.conf
mkdir /var/www/vhosts/$DOMAINNAME
echo "Your Project Directory is : /var/www/vhosts/$DOMAINNAME"

/usr/sbin/apachectl configtest
/usr/sbin/apachectl graceful 
/usr/sbin/apachectl -S 

echo "****DONE****"
