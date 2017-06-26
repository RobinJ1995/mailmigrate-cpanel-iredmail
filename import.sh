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
		if [[ $old_hash == \!\!* ]] # CPanel's way of disabling an account
		then
			continue;
		fi
		hash={CRYPT}$old_hash
	
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
	
		dir=$dir$username-$domain-$date/
	
		# Insert domain if it doesn't exist yet
		exists=`$mysqlcommand -e "SELECT COUNT(*) FROM domain WHERE domain = \"$domain\";"`
		if [ $exists -eq 0 ]
		then
			echo "Creating domain $domain..."
			$mysqlcommand -e "INSERT INTO domain (domain, settings, created) VALUES ('$domain', 'default_user_quota:$quota;', NOW());"
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
	else
		existing_targets=`$mysqlcommand -e "SELECT goto FROM alias WHERE address = \"$email\";"`
		
		if [[ ! $existing_targets == *$alias_target* ]]
		then
			echo "Adding alias target $alias_target to $email..."
			$mysqlcommand -e "UPDATE alias SET goto = CONCAT(goto, ',', '$alias_target') WHERE address = '$email';"
		fi
	fi
done
