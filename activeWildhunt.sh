#!/bin/bash

CHATID=""
TOKEN=""

active() {
	path=$(pwd)
	dir2="$path/recon"
	if [ -d "$dir2" ]; then
		cd "$dir2" || exit
	else
		mkdir -p "$dir2" && cd "$dir2" || exit
	fi

	Btools_path="$dir2/Btools"
	config_path="$Btools_path/config"
	if [ -e "$Btools_path" ]; then
		rm -rf $Btools_path
		git clone git@github.com:SpeedyQweku/Btools.git || exit
		mv $config_path .
		rm -rf $Btools_path
	else
		git clone git@github.com:SpeedyQweku/Btools.git || exit
		mv $config_path .
		rm -rf $Btools_path
	fi

	Dir=config/wordlists
	if test -d "$Dir"; then
		printf "First directory created\n"
		rm -rf "$Dir"
	fi
	mkdir "$Dir" && wget -q https://wordlists-cdn.assetnote.io/data/manual/best-dns-wordlist.txt -P "$Dir"

	## Glolbal directories
	Dir=resolvers
	if test -d "$Dir"; then
		printf "First directory created\n"
		rm -rf "$Dir"
	fi
	mkdir "$Dir"

	resolver_path="$dir2/resolvers/resolvers.txt"
	if [ -e "$resolver_path" ]; then
		echo "File exists."
	else
		wget -q https://raw.githubusercontent.com/trickest/resolvers/main/resolvers.txt -P "$HOME/recon/resolvers/"
	fi

	DirF=activeresults
	if test -d "$DirF"; then
		echo "Folder exists."
	else
		mkdir "$DirF"
	fi
	sendTele -c "$CHATID" -t "$TOKEN" -m "Doing recon on $domain now"

	printf "[-] ACTIVE RECON - AMASS BRUTEFORCING\n=====================================\n"
	amass enum -brute -alts -config ../config/config2.yaml -d $domain
	psql postgres://admin:password@localhost:5432/amass -c "SELECT content->>'name' FROM assets WHERE type = 'FQDN' AND content->>'name' LIKE '%$domain'" | grep ".\\$domain$" >>$DirF/active-amass.txt
	printf "\n"
}

liveChecker() {
	cd $DirF

	## Checking for live domain
	printf "[|] CHECKING %s FOR LIVE DOMAINS\n=====================================\n"
	cat ActiveResult.txt | $HOME/go/bin/httpx -t 70 -o AllLiveDomains.txt
	sendTele -c "$CHATID" -t "$TOKEN" -m '... Httpx scan is done,{nl}Go start your subdomain-takeover and secret finder scan on the results[AllLiveDomains.txt].{nl}While you wait for the port scan to finish.'
	printf "\n"

	printf "[|] REMOVING HTTPS/HTTP FROM SUBDOMAINS to use in cero \n==================================================================\n"
	cat AllLiveDomains.txt | grep -oP '(?<=://)[^/]+(?=/|$)' | tee noprotocolDomains.txt
	printf "\n"

	##Using rustscan to scan all ports
	exclude_port="80,443,25,465,587,22,2525,21"
	printf "[|] RUNNING A FULL PORT SCAN THIS MIGHT TAKE LONGER\n====================================================================\n"
	naabu -silent -nc -list ActiveResult.txt -p - -exclude-ports $exclude_port | tee -a allOpenports.txt

	rustscan -a ActiveResult.txt --range 1-65535 --scan-order "Random" --accessible | tee -a allOpenports.txt
}

sendTele -c "$CHATID" -t "$TOKEN" -t "$1" -a
for domains in $(cat $1); do
	passive "$domains"
done
cat passiveResult.txt | anew $DirF/active-amass.txt | tee -a $DirF/ActiveResult.txt
liveChecker
sendTele -c "$CHATID" -t "$TOKEN" -m "Active Subdomain Enumeration Done, Enjoy!!!"
