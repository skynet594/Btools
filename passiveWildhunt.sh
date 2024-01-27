#!/bin/bash




echo -n "Enter your Telegram Chat ID: "
read CHATID
echo -n "Enter your Telegram Bot Token: "
read TOKEN


##passive enumeration started here
crt() {
	curl -s "https://crt.sh/?q=%25.$1" |
		grep -oE "[\.a-zA-Z0-9-]+\.$1" |
		sort -u
}

rapiddns() {
	curl -s "https://rapiddns.io/subdomain/$1?full=1" |
		grep -oE "[\.a-zA-Z0-9-]+\.$1" |
		sort -u
}

passive() {
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
		rm -rf config
		mv $config_path .
		rm -rf $Btools_path
	else
		git clone git@github.com:SpeedyQweku/Btools.git || exit
		rm -rf config
		mv $config_path .
		rm -rf $Btools_path
	fi

	Dir=config/wordlists
	if test -d "$Dir"; then
		rm -rf "$Dir"
	fi
	mkdir "$Dir" && wget -q https://wordlists-cdn.assetnote.io/data/manual/best-dns-wordlist.txt -P "$Dir"

	## Glolbal directories
	Dir=resolvers
	if test -d "$Dir"; then
		rm -rf "$Dir"
	fi
	mkdir "$Dir"

	DirR=Result
	if test -d "$DirR"; then
		rm -rf "$DirR"
	fi
	mkdir "$DirR"

	resolver_path="$dir2/resolvers/resolvers.txt"
	if [ -e "$resolver_path" ]; then
		echo "File exists."
	else
		wget -q https://raw.githubusercontent.com/trickest/resolvers/main/resolvers.txt -P "$HOME/recon/resolvers/"
	fi

	## directories created
	local domain="$1"
	IFS='.' read -ra data <<<"$domains"
	if [ -d "${data[0]}" ]; then
		mkdir "$domain" && cd "$domain" || exit
	else
		mkdir "${data[0]}" && cd "${data[0]}" || exit
	fi

	Dir=allresults
	if test -d "$Dir"; then
		printf "First directory created\n"
		rm -rf "$Dir"
	fi
	mkdir "$Dir"

	declare -a files=("amass" "subfinder" "assetfinder" "findomain" "githubsubs" "gitlabsubs" "ourl" "shosubgo" "gau" "crt" "rapiddns" "waybackurls" "tlsx" "rerunall")
	for file in "${files[@]}"; do
		File="allresults/${file}.txt"
		if test -f "$File"; then
			printf "A new %s.txt file has been created\n", "$file"
			rm "$File"
		else
			touch "$File"
		fi
	done

	##all domains run and an alert is sent to telegram for each domain processed
	sendTele -c "$CHATID" -t "$TOKEN" -m "Doing recon on $domain now"

	printf "\n"
	printf "[-] SUBFINDER SEARCHING FOR SUBDOMAINS\n=====================================\n"
	subfinder -d "$domain" -o allresults/subfinder.txt
	printf "\n"

	printf "[-] ASSETFINDER SEARCHING FOR SUBDOMAINS\n=====================================\n"
	assetfinder -subs-only "$domain" >>allresults/assetfinder.txt
	printf "\n"

	printf "[-] FINDOMAIN SEARCHING FOR SUBDOMAINS\n=====================================\n"
	findomain -u allresults/findomain.txt -t "$domain"
	printf "\n"

	printf "[-] ourl searching for subs\n=====================================\n"
	ourl -subs -p -a "$domain" >>allresults/ourl.txt
	printf "\n"

	printf "[-] SEARCHING FOR SUBDOMAINS ON GITHUB\n=====================================\n"
	github-subdomains -d "$domain" -t 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,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 -o allresults/githubsubs.txt
	printf "\n"

	printf "[-] SEARCHING FOR SUBDOMAINS ON GITLAB\n=====================================\n"
	gitlab-subdomains -d "$domain" -t glpat-AeWyCS55u2TNateyax4Q,glpat-baUgPcXWN-N_opxisyvJ >>allresults/gitlabsubs.txt
	printf "\n"

	printf "[-] SHOSUBGO SEARCHING FOR SUBDOMAINS\n=====================================\n"
	shosubgo -d "$domain" -s oBrxB7VlTtqCKznyDAxTjcB3I7Lu7EvA >>allresults/shosubgo.txt && cat allresults/shosubgo.txt
	printf "\n"

	printf "[-] GAU SEARCHING FOR SUBDOMAINS\n=====================================\n"
	gau --threads 5 --subs "$domain" | unfurl -u domains | sort -u -o allresults/gau.txt
	cat allresults/gau.txt
	printf "\n"

	printf "[-] CRT SEARCHING FOR SUBDOMAINS\n=====================================\n"
	crt "$domain" >allresults/crt.txt
	cat allresults/crt.txt
	printf "\n"

	printf "[-] RAPIDDNS SEARCHING FOR SUBDOMAINS\n=====================================\n"
	rapiddns "$domain" >allresults/rapiddns.txt
	cat allresults/rapiddns.txt
	printf "\n"

	printf "[-] WAYBACKMACHINE SEARCHING FOR SUBDOMAINS IT MAIGHT TAKE SOMETIME\n=====================================\n"
	waybackurls "$domain" | unfurl -u domains | sort -u -o allresults/waybackurls.txt
	cat allresults/waybackurls.txt
	printf "\n"

	printf "[-] TLSX SEARCHING FOR SUBDOMAINS\n=====================================\n"
	tlsx -u "$domain" -san -cn -silent -resp-only -o allresults/tlsx.txt
	printf "\n"

	printf "[-] BBOT \n=====================================\n"
	bbot -t "$domain" -f subdomain-enum -rf passive -y --force -o bbot-results --name $domain
	printf "\n"

	printf "[-] AMASS SEARCHING FOR SUBDOMAINS IT MIGHT TAKE LONG-PASSIVE\n=====================================\n"
	amass enum -passive -norecursive -config ../config/passive.yaml -d "$domain"
	psql postgres://admin:password@localhost:5432/amass -c "SELECT content->>'name' FROM assets WHERE type = 'FQDN' AND content->>'name' LIKE '%$domain'" | grep ".\\$domain$" >>allresults/amass.txt
	printf "\n"

	## All subdomains obtained are combined.
	printf "[-] CERO SEARCHING FOR SUBDOMAINS \n=====================================\n"
	cd allresults/ || exit
	cat * ../bbot-results/$domain/subdomains.txt | sort -u | cero | sed 's/^*.//' | grep -e "\." | sort -u | tee -a cero.txt
	printf "\n"

	printf "[-] COMBING ALL RESULTS \n=====================================\n"
	cat * ../bbot-results/$domain/subdomains.txt | sort -u | tee -a uniqued.txt
	cd $dir2 && cd ..
	printf "\n"
}

liveChecker() {
	## Checking for live domain
	printf "[|] CHECKING %s FOR LIVE DOMAINS\n=====================================\n"
	cat $DirR/passiveResult.txt | $HOME/go/bin/httpx -t 70 -o $DirR/AllLiveDomains.txt
	sendTele -c "$CHATID" -t "$TOKEN" -m '... Httpx scan is done,{nl}Go start your subdomain-takeover and secret finder scan on the results\[AllLiveDomains.txt].{nl}While you wait for the port scan to finish.'
	printf "\n"

	printf "[|] REMOVING HTTPS/HTTP FROM SUBDOMAINS to use in cero \n==================================================================\n"
	cat $DirR/AllLiveDomains.txt | grep -oP '(?<=://)[^/]+(?=/|$)' | tee -a $DirR/noprotocolDomains.txt
	printf "\n"

	##Using rustscan to scan all ports
	exclude_port="80,443,25,465,587,22,2525,21"
	printf "[|] RUNNING A FULL PORT SCAN THIS MIGHT TAKE LONGER\n====================================================================\n"
	naabu -silent -nc -list $DirR/passiveResult.txt -p - -exclude-ports $exclude_port | tee -a $DirR/allOpenports.txt
	# rustscan -a $DirR/passiveResult.txt --range 1-65535 --scan-order "Random" --accessible | tee -a $DirR/allOpenports.txt
}

sendTele -c "$CHATID" -t "$TOKEN" -f "$1" -p
for domains in $(cat $1); do
	passive "$domains"
done

path=$(pwd)
folder_path="$path/recon"

for subfolder in "$folder_path"/*/; do
	# Check if the sub.txt file exists in the current subfolder
	if [ -e "$subfolder/allresults/uniqued.txt" ]; then
		# If the file exists, use cat to output its contents
		cat "$subfolder/allresults/uniqued.txt" >> $folder_path/$DirR/passiveResult.txt
	fi
done

cd $folder_path && liveChecker
sendtele -c "$CHATID" -t "$TOKEN" -m "Passive Subdomain Enumeration Done, Enjoy!!!"
