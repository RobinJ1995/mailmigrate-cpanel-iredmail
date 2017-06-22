#!/bin/bash

source config.sh

date=`date +%Y.%m.%d.%H.%M.%S`
storage_base=`dirname $maildir`
storage_node=`basename $maildir`
source=`cat $sourcefile`

users=`ls /home`
mysqlcommand="mysql -B -N -u$mysql_username -D$mysql_database"
if [ $mysql_password ]
then
	mysqlcommand="$mysqlcommand -p$mysql_password"
fi

for account in $source
do
	if [[ ! $account == \>* ]] # Not an alias
	then
		username=`echo $account | cut -d@ -f1`
		domain=`echo $account | cut -d@ -f2 | cut -d: -f1`
		email=`echo $account | cut -d: -f1`
		alias_target=$email
		old_hash=`echo $account | cut -d@ -f2 | cut -d: -f2`
		dir=
	
		# Convert hash
		if [[ $old_hash == \$6* ]]
		then
			hash={SHA512}`echo $old_hash | cut -c4-`
		elif [[ $old_hash == \$1* ]]
		then
			hash={MD5}`echo $old_hash | cut -c4-`
		else
			continue # Probably starts with !!, which is CPanel's way of disabling an account
		fi
	
		# Maildir format
		if [[ $maildir_style == 'hashed' ]]
		then
			length=`echo $username | wc -L`
			if [[ $length -gt 3 ]]
			then
				length=3
			fi
		
			for ((i=1; i<=$length; i++))
			do
				dir=$dir`echo $username | cut -c $i`/
			done
		fi
	
		dir=$dir$username-$date/
	
		# Insert domain if it doesn't exist yet
		exists=`$mysqlcommand -e "SELECT COUNT(*) FROM domain WHERE domain = \"$domain\";"`
		if [ $exists -eq 0 ]
		then
			echo "Creating domain $domain..."
			$mysqlcommand -e "INSERT INTO domain (domain, settings, created) VALUES ('$domain', 'default_user_quota:100;', NOW());"
		fi
	
		# Insert user if it doesn't exist yet
		exists=`$mysqlcommand -e "SELECT COUNT(*) FROM mailbox WHERE username = \"$email\";"`
		if [ $exists -eq 0 ]
		then
			echo "Creating mailbox $email..."
			$mysqlcommand -e "INSERT INTO mailbox (username, password, name, storagebasedirectory, storagenode, maildir, quota, domain, created) VALUES ('$email', '$hash', '$username', '$storage_base', '$storage_node', '$dir', $quota, '$domain', NOW());"
		fi
	else
		account=`echo $account | cut -c2-`
		email=`echo $account | cut -d: -f1`
		alias_target=`echo $account | cut -d: -f2`
	fi
	
	# Insert alias if it doesn't exist yet
	exists=`$mysqlcommand -e "SELECT COUNT(*) FROM alias WHERE address = \"$email\";"`
	if [ $exists -eq 0 ]
	then
		echo "Creating alias $email -> $alias_target..."
		$mysqlcommand -e "INSERT INTO alias (address, goto, domain, created) VALUES ('$email', '$alias_target', '$domain', NOW());"
	fi
done
