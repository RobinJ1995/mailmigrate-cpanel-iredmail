#!/bin/bash

users=`ls /home`
alias_domains=`ls /etc/valiases`

for user in $users
do
	if [ ! -d /home/$user/etc ]
	then
		continue
	fi
	
	domains=`ls /home/$user/etc`
	
	for domain in $domains
	do
		if [ ! -d /home/$user/etc/"$domain" ] || [ ! -f /home/$user/etc/"$domain"/shadow ]
		then
			continue
		fi
		
		combined=`cat /home/$user/etc/$domain/shadow | cut -d: -f1,2`
		n=`echo $combined | wc -w`
		
		for account in $combined
		do
			username=`echo $account | cut -d: -f1`
			password=`echo $account | cut -d: -f2`
			
			echo $username@$domain:$password
		done
	done
done

for domain in $alias_domains
do
	aliases=`cat "/etc/valiases/$domain"`
	
	while read -r alias
	do
		from=`echo "$alias" | cut -d: -f1 | tr -d ' '`
		to=`echo "$alias" | cut -d: -f2- | tr -d ' '`
		
		if [[ $to == \:* ]] || [[ $to == \"\:* ]] || [[ ! $to == *@* ]]
		then
			continue;
		fi
		
		if [[ ! $from == *@$domain ]]
		then
			from=$from@$domain
		fi
		
		echo ">$from:$to"
	done < "/etc/valiases/$domain"
done
