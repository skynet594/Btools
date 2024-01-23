#!/bin/bash


##passive enumeration started here
crt() {
	curl -s "https://crt.sh/?q=%25.$1" \
    | grep -oE "[\.a-zA-Z0-9-]+\.$1" \
    | sort -u
}

rapiddns() {
	curl -s "https://rapiddns.io/subdomain/$1?full=1" \
    | grep -oE "[\.a-zA-Z0-9-]+\.$1" \
    | sort -u
}

passive() {
	path=$(pwd)
	dir2="$path/recon"
	if [ -d "$dir2" ]; then
		cd "$dir2" || exit
	else
		mkdir -p "$dir2" && cd "$dir2" || exit
	fi

	Btools_path="$HOME/recon/Btools"
	config_path="$Btools_path/config"
	if [ -e "$Btools_path" ];then
		rm -rf $Btools_path
		git clone git@github.com:SpeedyQweku/Btools.git
		mv $config_path .
		rm -rf $Btools_path
	else
		git clone git@github.com:SpeedyQweku/Btools.git
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

	resolver_path="$HOME/recon/resolvers/resolvers.txt"
	if [ -e "$resolver_path" ];then
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

	Dir=portscan
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
	sendtele "Doing recon on $domain now"

	printf "SUBFINDER SEARCHING FOR SUBDOMAINS\n=====================================\n"
	subfinder -d "$domain" -o allresults/subfinder.txt
	printf "\n"

	printf "ASSETFINDER SEARCHING FOR SUBDOMAINS\n=====================================\n"
	assetfinder -subs-only "$domain" >> allresults/assetfinder.txt
	printf "\n"

	printf "FINDOMAIN SEARCHING FOR SUBDOMAINS\n=====================================\n"
	findomain -u allresults/findomain.txt -t "$domain"
	printf "\n"

	printf "ourl searching for subs\n=====================================\n"
	ourl -subs -p -a "$domain" >> allresults/ourl.txt
	printf "\n"

	printf "SEARCHING FOR SUBDOMAINS ON GITHUB\n=====================================\n"
	github-subdomains -d "$domain" -t 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,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 -o allresults/githubsubs.txt
	printf "\n"

	printf "SEARCHING FOR SUBDOMAINS ON GITLAB\n=====================================\n"
	gitlab-subdomains -d "$domain" -t glpat-AeWyCS55u2TNateyax4Q,glpat-baUgPcXWN-N_opxisyvJ >> allresults/gitlabsubs.txt
	printf "\n"

	printf "SHOSUBGO SEARCHING FOR SUBDOMAINS\n=====================================\n"
	shosubgo -d "$domain" -s oBrxB7VlTtqCKznyDAxTjcB3I7Lu7EvA >> allresults/shosubgo.txt
	cat allresults/shosubgo.txt
	printf "\n"

	printf "GAU SEARCHING FOR SUBDOMAINS\n=====================================\n"
	gau --threads 5 --subs "$domain" | unfurl -u domains | sort -u -o allresults/gau.txt
	cat allresults/gau.txt
	printf "\n"

	printf "CRT SEARCHING FOR SUBDOMAINS\n=====================================\n"
	crt "$domain" > allresults/crt.txt
	cat allresults/crt.txt
	printf "\n"

	printf "RAPIDDNS SEARCHING FOR SUBDOMAINS\n=====================================\n"
	rapiddns "$domain" > allresults/rapiddns.txt
	cat allresults/rapiddns.txt
	printf "\n"

	printf "WAYBACKMACHINE SEARCHING FOR SUBDOMAINS IT MAIGHT TAKE SOMETIME\n=====================================\n"
	waybackurls "$domain" | unfurl -u domains | sort -u -o allresults/waybackurls.txt
	cat allresults/waybackurls.txt
	printf "\n"

	printf "TLSX SEARCHING FOR SUBDOMAINS\n=====================================\n"
	tlsx -u "$domain" -san -cn -silent -resp-only -o allresults/tlsx.txt
	printf "\n"

	printf "BBOT \n=====================================\n"
	bbot -t "$domain" -f subdomain-enum -rf passive -y --force -o bbot-results --name $domain

	printf "AMASS SEARCHING FOR SUBDOMAINS IT MIGHT TAKE LONG-PASSIVE\n=====================================\n"
	amass enum -passive -norecursive -config ../config/config1.yaml -d "$domain" 
	psql postgres://admin:password@localhost:5432/amass -c "SELECT content->>'name' FROM assets WHERE type = 'FQDN' AND content->>'name' LIKE '%$domain'" | grep ".\\$domain$" >> allresults/amass.txt
	rm -f "$resolver_path"
	printf "\n"

	printf "==> ACTIVE RECON - AMASS BRUTEFORCING\n=====================================\n"
	active "$domain"
	printf "\n"

	printf "==> ACTIVE-PASS\n=====================================\n"
	pass "$domain"
	cd "$dir2" && cd ..
	printf "\n"
}

##active subdomain enumeration begins here using amass
active(){
	resolver_path="$HOME/recon/resolvers/resolvers.txt"
	if [ -e "$resolver_path" ];then
		echo "File exists."
	else
		wget -q https://raw.githubusercontent.com/trickest/resolvers/main/resolvers.txt -P "$HOME/recon/resolvers/"
	fi

	amass enum -brute -alts	 -config ../config/config2.yaml -d $domain
	psql postgres://admin:password@localhost:5432/amass -c "SELECT content->>'name' FROM assets WHERE type = 'FQDN' AND content->>'name' LIKE '%$domain'" | grep ".\\$domain$" >> allresults/amass.txt
	rm -f "$resolver_path"
}

pass(){
    ## All subdomains obtained are combined.
	printf "==>COMBING ALL RESULTS FROM SCRIPT 1 \n=====================================\n"
    cd allresults/ || exit
	cat crt.txt rapiddns.txt subfinder.txt assetfinder.txt findomain.txt githubsubs.txt gitlabsubs.txt shosubgo.txt ourl.txt gau.txt waybackurls.txt tlsx.txt amass.txt ../bbot-results/$domain/subdomains.txt | sort -u > uniqued.txt

    ## Script 2 is run here on all collected subdomains to get more subdomains. This is done before live domains are check.
	printf "==>SCRIPT 2 STARTS RUNING ONLY AMASS ON ALL SUBDOMAINS FOR MORE DOMAINS\n=====================================\n"
	amass enum -passive -norecursive -df uniqued.txt --dir "$domain-subsrerun"
	sqlite3 "$domain-subsrerun"/amass.sqlite "SELECT content->>'name' FROM assets WHERE type = 'FQDN' AND content->>'name' LIKE '%$domain'" > rerunall.txt

	## All subdomains obtained are combined.
	printf "==>COMBING ALL RESULTS FROM SCRIPT 1 AND 2 | CHECKING LIVE | UNIQUE\n=====================================\n"
	cat crt.txt rapiddns.txt subfinder.txt assetfinder.txt findomain.txt githubsubs.txt gitlabsubs.txt shosubgo.txt ourl.txt gau.txt waybackurls.txt tlsx.txt amass.txt ../bbot-results/$domain/subdomains.txt rerunall.txt | sort -u > alluniqued.txt

    ## Checking for live domain
	printf "CHECKING %s FOR LIVE DOMAINS\n=====================================\n", "$domain"
	cat alluniqued.txt | $HOME/go/bin/httpx -t 70 -o AllLiveDomains.txt
    sendtele "... Httpx scan is done on $domain,{nl}Go start your subdomain-takeover and secret scan on the results[AllLiveDomains.txt].{nl}While you wait for the port scan to finish."
	printf "\n"

    ##Using rustscan to scan all ports
	printf "==>SCRIPT 3 RUNNING FULL PORT SCAN THIS MIGHT TAKE LONGER\n=====================================\n"
	rustscan -a alluniqued.txt --range 1-65535 --scan-order "Random" > /portscan/allOpenports.txt
}

sendtele "$1"
for domains in $(cat $1); do
	passive "$domains"
done
sendtele "All done!!!"