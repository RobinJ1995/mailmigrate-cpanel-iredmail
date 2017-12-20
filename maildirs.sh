#!/bin/bash

users=`ls /home`

for user in $users
do
	if [ ! -d /home/$user/mail ]
	then
		continue
	fi
	
	domains=`ls /home/$user/mail`
	for domain in $domains
	do
		if [ ! -d /home/$user/mail/"$domain" ] || [[ ! $domain == *.* ]]
		then
			continue
		fi
		
		usernames=`ls /home/$user/mail/"$domain"`
		for username in $usernames
		do
			echo $username@$domain:/home/$user/mail/"$domain"/"$username"/
		done
	done
done

