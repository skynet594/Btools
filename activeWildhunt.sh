#!/bin/bash

echo -n "Enter your Telegram Chat ID: "
read CHATID
echo -n "Enter your Telegram Bot Token: "
read TOKEN

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

	DirW=Wordlists
	if test -d "$DirW"; then
		rm -rf "$DirW"
	fi
	mkdir "$DirW" && wget -q https://raw.githubusercontent.com/emadshanab/admin-paths/main/admin.txt -P "$DirW"
	wget -q https://raw.githubusercontent.com/SpeedyQweku/sfuzz/main/wordlist/swaggerwordlist.txt -P "$DirW"
	wget -q https://raw.githubusercontent.com/SpeedyQweku/dfuzz/main/wordlist/secretlist.txt -P "$DirW"

	DirT=nuclei-templates
	if test -d "$DirT"; then
		rm -rf "$DirT"
	fi
	mkdir "$DirT" && wget -q https://raw.githubusercontent.com/projectdiscovery/nuclei-templates/8b2bc8ab8ef801d4342bb4ec4fedb5460296da29/subdomain-takeover/detect-all-takeovers.yaml -P "$DirT"

	resolver_path="$dir2/resolvers/resolvers.txt"
	if [ -e "$resolver_path" ]; then
		echo "File exists."
	else
		wget -q https://raw.githubusercontent.com/trickest/resolvers/main/resolvers.txt -P "$dir2/resolvers/"
	fi

	DirF=activeresults
	if test -d "$DirF"; then
		echo "Folder exists."
	else
		mkdir "$DirF"
	fi
	sendTele -c "$CHATID" -t "$TOKEN" -m "Doing recon on $domain now"

	printf "[-] ACTIVE RECON - AMASS BRUTEFORCING\n=====================================\n"
	amass enum -brute -alts -config ../config/active.yaml -d $domain
	psql postgres://admin:password@localhost:5432/amass -c "SELECT content->>'name' FROM assets WHERE type = 'FQDN' AND content->>'name' LIKE '%$domain'" | grep ".\\$domain$" >>$DirF/active-amass.txt
	printf "\n"
}

CheckerScan() {
	## Checking for live domain
	printf "[|] CHECKING %s FOR LIVE DOMAINS\n=====================================\n"
	cat $DirF/ActiveResult.txt | $HOME/go/bin/httpx -t 70 -o $DirF/AllLiveDomains.txt
	sendTele -c "$CHATID" -t "$TOKEN" -m '{nl}Httpx scan for [CheckerScan] is done.{nl}Go start your URL gathering.{nl}Results name : [AllLiveDomains.txt].'
	printf "\n"

	##scans for swagger files on webserver ports
	printf "[|] SCANNING FOR SWAGGER PATH ON WEBSERVER PORTS\n====================================================================\n"
	sfuzz -l $DirF/AllLiveDomains.txt -c 30 -w $DirW/swaggerwordlist.txt -o $DirF/ValidSwagger.txt

	##scans for secrets file on webserver ports
	printf "[|] SCANNING FOR SECRET FILES ON WEBSERVER PORTS \n====================================================================\n"
	dfuzz -l $DirF/AllLiveDomains.txt -c 30 -w $DirW/secretlist.txt -o $DirF/ValidSecrets.txt

	##Scanning for dns take over.
	printf "[|] SCANNING FOR  DNSTAKEOVER\n====================================================================\n"
	dnstake -t $DirF/ActiveResult.txt -c 50 -o $DirF/dnstakeover.out

	##Scanning for subdomain takeover.
	printf "[|] SCANNING FOR SUBDOMAIN DNSTAKEOVER\n====================================================================\n"
	nuclei -l $DirF/ActiveResult.txt -t $DirT/detect-all-takeovers.yaml -o $DirF/subtakeover.txt

	##scans for secrets file on webserver ports
	printf "[|] SCANNING FOR SECRET FILES ON WEBSERVER PORTS \n====================================================================\n"
	dfuzz -l $DirF/AllLiveDomains.txt -c 30 -w $DirW/admin.txt -o $DirF/adminpanel.txt

	##Removes http/https
	printf "[|] REMOVING HTTPS/HTTP FROM SUBDOMAINS\n==================================================================\n"
	cat $DirF/AllLiveDomains.txt | grep -oP '(?<=://)[^/]+(?=/|$)' | tee -a $DirF/noprotocolDomains.txt
	printf "\n"

	##Using smap for port scan
	printf "[|] RUNNING A FULL PORT SCAN THIS MIGHT TAKE LONGER\n====================================================================\n"
	smap -iL $DirF/ActiveResult.txt -oX $DirF/output.xml
}

portscan() {
	##Using rustscan to scan all ports
	exclude_port="80,443,25,465,587,22,2525,21"
	printf "[|] RUNNING A FULL PORT SCAN THIS MIGHT TAKE LONGER\n====================================================================\n"
	naabu -silent -nc -list $DirF/ActiveResult.txt -p - -exclude-ports $exclude_port | tee -a $DirF/allOpenports.txt
	# rustscan -a $DirF/ActiveResult.txt --range 1-65535 --scan-order "Random" --accessible | tee -a $DirF/allOpenports.txt

	##To check for live webservers
	printf "[|] CHECKING FOR LIVE WEBSERVERS ON OPEN PORTS\n====================================================================\n"
	cat $DirF/allOpenports.txt | $HOME/go/bin/httpx -t 70 -o $DirF/LiveWebServers.txt
	sendTele -c "$CHATID" -t "$TOKEN" -m '{nl}Httpx scan for [portscan] is done.{nl}Go start your URL gathering.{nl}Results name : [AllLiveDomains.txt].'

	##scans for swagger files on webserver ports
	printf "[|] SCANNING FOR SWAGGER PATH ON WEBSERVER PORTS\n====================================================================\n"
	sfuzz -l $DirF/LiveWebServers.txt -c 30 -w $DirW/swaggerwordlist.txt -o $DirF/ValidWebServerSwagger.txt

	##scans for secrets file on webserver ports
	printf "[|] SCANNING FOR SECRET FILES ON WEBSERVER PORTS\n====================================================================\n"
	dfuzz -l $DirF/LiveWebServers.txt -c 30 -w $DirW/secretlist.txt -o $DirF/ValidWebServerSecrets.txt
}

sendTele -c "$CHATID" -t "$TOKEN" -t "$1" -a
for domains in $(cat $1); do
	passive "$domains"
done

cat "$2" | anew $DirF/active-amass.txt | tee -a $DirF/ActiveResult.txt

if [ $(wc -l "$DirF/ActiveResult.txt" | awk '{print $1}') -eq 0 ]; then
	sendTele -c "$CHATID" -t "$TOKEN" -m "Active Subdomain Enumeration Done,{nl}[ActiveResult.txt] : 0"
	exit
else
	if CheckerScan && portscan; then
		sendTele -c "$CHATID" -t "$TOKEN" -m "Active Subdomain Enumeration Done, Enjoy!!!"
	else
		echo "Error: CheckerScan or portscan failed."
	fi
fi
