#!/bin/bash

source config.sh

source=`cat $maildirs_sourcefile`

mysqlcommand="mysql -B -N -u$mysql_username -D$mysql_database"
if [ $mysql_password ]
then
	mysqlcommand="$mysqlcommand -p$mysql_password"
fi

for account in $source
do
	username=`echo $account | cut -d@ -f1`
	domain=`echo $account | cut -d@ -f2 | cut -d: -f1`
	email=`echo $account | cut -d: -f1`
	source_maildir=`echo $account | cut -d: -f2`
	target_maildir=`$mysqlcommand -e "SELECT CONCAT(storagebasedirectory, '/', storagenode, '/', maildir) FROM mailbox WHERE username=\"$email\" LIMIT 1;"`
	
	echo "Copying mailbox for $email..."
	mkdir -p ${target_maildir}Maildir
	rsync -avP $maildirs_sourceserver:$source_maildir ${target_maildir}Maildir
done
