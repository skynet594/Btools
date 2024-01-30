#!/bin/bash

# Check if the number of arguments is correct
if [ "$#" -ne 1 ]; then
	echo "Usage: $0 <target.txt>"
	exit 1
fi

echo -n "[-] Enter your Telegram Chat ID: "
read CHATID

if [ -z "$CHATID" ]; then
	echo -e "\e[31m[Error] Please provide a Telegram Chat ID.\e[0m"
	exit 1
fi

echo -n "[-] Enter your Telegram Bot Token: "
read TOKEN

if [ -z "$TOKEN" ]; then
	echo -e "\e[31m[Error] Please provide a Telegram Bot Token.\e[0m"
	exit 1
fi

echo -n "[-] Enter your GitHub SSH File Name: "
read sshfile

# Check if the SSH file name is provided
if [ -z "$sshfile" ]; then
	echo -e "\e[31m[Error] Please provide a GitHub SSH file name.\e[0m"
	exit 1
fi

# Check if the SSH key file exists
if [ ! -f "$HOME/.ssh/$sshfile" ]; then
	echo -e "\e[31m[Error] SSH key file '$sshfile' not found in '$HOME/.ssh/'"
	exit 1
fi

echo "[+] Starting SSH agent..."
eval "$(ssh-agent -s)"
printf "\n"

# Add the SSH key to the agent
echo "[+] Adding SSH key to agent..."
ssh-add "$HOME/.ssh/$sshfile"
printf "\n"

# Check if adding the key was successful
if [ $? -eq 0 ]; then
	echo "[+] SSH key added successfully!"
	printf "\n"
else
	echo "[Error] Failed to add SSH key to agent."
fi

# printf "nameserver 8.8.8.8\n" | sudo tee -a /etc/resolv.conf
if ! grep -q "nameserver 8.8.8.8" /etc/resolv.conf; then
	printf "[+] Added Some DNS Resolvers To Your System\n=====================================\n"
	printf "nameserver 8.8.8.8\nnameserver 76.76.2.0\nnameserver 9.9.9.9\nnameserver 208.67.222.222\nnameserver 1.1.1.1\nnameserver 185.228.168.9\nnameserver 76.76.19.19\nnameserver 94.140.14.14\n" | sudo tee -a /etc/resolv.conf
	printf "\n"
fi

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
	else
		git clone git@github.com:SpeedyQweku/Btools.git || exit
		rm -rf config
		mv $config_path .
	fi

	## Moving bbot to .config
	bbot_path="$Btools_path/bbot"
	bbot_config="$HOME/.config/bbot"
	if [[ -d "$bbot_config" ]]; then
		rm -rf "$bbot_config"
		mv "$bbot_path" "$HOME/.config/"
	else
		mv "$bbot_path" "$HOME/.config/"
	fi

	ourlPath="$Btools_path/ptool/ourl"
	destination_directory="$HOME/.local/bin"
	if [ -e "$ourlPath" ]; then
		if [ ! -e "$destination_directory/$(basename "$ourlPath")" ]; then
			mv "$ourlPath" "$destination_directory" && echo "[+] File moved successfully to '$destination_directory'."
		else
			printf "\n"
			echo -e "\e[31m[Warning] File already exists in destination directory '$destination_directory'.\e[0m"
		fi
	else
		printf "\n"
		echo -e "\e[31m[Warning] File '$ourlPath' not found in source directory.\e[0m"
		exit 1
	fi

	Dir=config/wordlists
	if test -d "$Dir"; then
		rm -rf "$Dir"
	fi
	mkdir "$Dir" && wget -q https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-5000.txt -P "$Dir"

	## Glolbal directories
	DirRe=resolvers
	if test -d "$DirRe"; then
		rm -rf "$DirRe"
	fi
	mkdir "$DirRe"

	DirW=Wordlists
	if test -d "$DirW"; then
		rm -rf "$DirW"
	fi

	mkdir "$DirW" && wget -q https://raw.githubusercontent.com/emadshanab/admin-paths/main/admin.txt -P "$DirW"
	wget -q https://raw.githubusercontent.com/SpeedyQweku/sfuzz/main/wordlist/swaggerwordlist.txt -P "$DirW" || {
		echo -e "\e[31mError: Download failed or repository is private. Make it public. File: swaggerwordlist.txt\e[0m"
		exit 1
	}
	wget -q https://raw.githubusercontent.com/SpeedyQweku/dfuzz/main/wordlist/secretlist.txt -P "$DirW" || {
		echo -e "\e[31mError: Download failed or repository is private. Make it public. File: secretlist.txt\e[0m"
		exit 1
	}

	DirT=nuclei-templates
	if test -d "$DirT"; then
		rm -rf "$DirT"
	fi
	mkdir "$DirT" && wget -q https://raw.githubusercontent.com/projectdiscovery/nuclei-templates/8b2bc8ab8ef801d4342bb4ec4fedb5460296da29/subdomain-takeover/detect-all-takeovers.yaml -P "$DirT"

	DirR=Result
	if test -d "$DirR"; then
		rm -rf "$DirR"
	fi
	mkdir "$DirR"

	resolver_path="$dir2/$DirRe/resolvers.txt"
	if [ -e "$resolver_path" ]; then
		echo "File exists."
	else
		wget -q https://raw.githubusercontent.com/trickest/resolvers/main/resolvers.txt -P "$dir2/$DirRe"
	fi

	#Removing the Btools
	rm -rf "$Btools_path"

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
	sendTele -c "$CHATID" -t "$TOKEN" -m "{nl}Doing recon on $domain now"

	printf "\n"
	printf "[-] SUBFINDER SEARCHING FOR SUBDOMAINS\n=====================================\n"
	subfinder -d "$domain" -o allresults/subfinder.txt -pc ../config/provider-config.yaml
	printf "\n"

	printf "[-] ASSETFINDER SEARCHING FOR SUBDOMAINS\n=====================================\n"
	assetfinder -subs-only "$domain" | tee -a allresults/assetfinder.txt
	printf "\n"

	printf "[-] FINDOMAIN SEARCHING FOR SUBDOMAINS\n=====================================\n"
	findomain -u allresults/findomain.txt -t "$domain"
	printf "\n"

	printf "[-] ourl searching for subs\n=====================================\n"
	"$HOME/.local/bin/ourl" -subs -p -a "$domain" | tee -a allresults/ourl.txt
	printf "\n"

	printf "[-] SEARCHING FOR SUBDOMAINS ON GITHUB\n=====================================\n"
	github-subdomains -d "$domain" -t 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,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 -o allresults/githubsubs.txt
	printf "\n"

	printf "[-] SEARCHING FOR SUBDOMAINS ON GITLAB\n=====================================\n"
	gitlab-subdomains -d "$domain" -t glpat-AeWyCS55u2TNateyax4Q,glpat-baUgPcXWN-N_opxisyvJ | tee -a allresults/gitlabsubs.txt
	printf "\n"

	printf "[-] SHOSUBGO SEARCHING FOR SUBDOMAINS\n=====================================\n"
	shosubgo -d "$domain" -s oBrxB7VlTtqCKznyDAxTjcB3I7Lu7EvA | tee -a allresults/shosubgo.txt
	printf "\n"

	printf "[-] GAU SEARCHING FOR SUBDOMAINS\n=====================================\n"
	gau --threads 5 --subs "$domain" | unfurl -u domains | sort -u -o allresults/gau.txt
	cat allresults/gau.txt
	printf "\n"

	printf "[-] CRT SEARCHING FOR SUBDOMAINS\n=====================================\n"
	crt "$domain" | tee -a allresults/crt.txt
	printf "\n"

	printf "[-] RAPIDDNS SEARCHING FOR SUBDOMAINS\n=====================================\n"
	rapiddns "$domain" | tee -a allresults/rapiddns.txt
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

CheckerScan() {
	## Checking for live domain
	printf "[|] CHECKING %s FOR LIVE DOMAINS\n=====================================\n"
	cat $DirR/passiveResult.txt | $HOME/go/bin/httpx -t 70 -o $DirR/AllLiveDomains.txt
	sendTele -c "$CHATID" -t "$TOKEN" -m '{nl}Httpx scan for [CheckerScan] is done.{nl}Go start your URL gathering.{nl}Results name : [AllLiveDomains.txt].'
	printf "\n"

	##scans for swagger files on webserver ports
	printf "[|] SCANNING FOR SWAGGER PATH ON WEBSERVER PORTS\n====================================================================\n"
	sfuzz -l $DirR/AllLiveDomains.txt -c 30 -w $DirW/swaggerwordlist.txt -o $DirR/ValidSwagger.txt
	printf "\n"

	# ##scans for secrets file on webserver ports
	printf "[|] SCANNING FOR SECRET FILES ON WEBSERVER PORTS \n====================================================================\n"
	dfuzz -l $DirR/AllLiveDomains.txt -c 30 -w $DirW/secretlist.txt -o $DirR/ValidSecrets.txt
	printf "\n"

	##Scanning for dns take over.
	printf "[|] SCANNING FOR  DNSTAKEOVER\n====================================================================\n"
	dnstake -t $DirR/passiveResult.txt -c 50 -o $DirR/dnstakeover.out
	printf "\n"

	##Scanning for subdomain takeover.
	printf "[|] SCANNING FOR SUBDOMAIN DNSTAKEOVER\n====================================================================\n"
	nuclei -l $DirR/passiveResult.txt -t $DirT/detect-all-takeovers.yaml -o $DirR/subtakeover.txt
	printf "\n"

	##scans for secrets file on webserver ports
	printf "[|] SCANNING FOR SECRET FILES ON WEBSERVER PORTS \n====================================================================\n"
	dfuzz -l $DirR/AllLiveDomains.txt -c 30 -w $DirW/admin.txt -o $DirR/adminpanel.txt
	printf "\n"

	##Removes http/https
	printf "[|] REMOVING HTTPS/HTTP FROM SUBDOMAINS to use in cero \n==================================================================\n"
	cat $DirR/AllLiveDomains.txt | grep -oP '(?<=://)[^/]+(?=/|$)' | tee -a $DirR/noprotocolDomains.txt
	printf "\n"

	##Using smap for port scan
	printf "[|] RUNNING SMAP\n====================================================================\n"
	smap -iL $DirR/passiveResult.txt -oX $DirR/output.xml
	printf "\n"
}

portscan() {
	##Using rustscan to scan all ports
	exclude_port="80,443,25,465,587,22,2525,21"
	printf "[|] RUNNING A FULL PORT SCAN THIS MIGHT TAKE LONGER\n====================================================================\n"
	naabu -silent -nc -list $DirR/passiveResult.txt -p - -exclude-ports $exclude_port | tee -a $DirR/allOpenports.txt
	printf "\n"
	# rustscan -a $DirR/passiveResult.txt --range 1-65535 --scan-order "Random" --accessible | tee -a $DirR/allOpenports.txt

	##To check for live webservers
	printf "[|] CHECKING FOR LIVE WEBSERVERS ON OPEN PORTS\n====================================================================\n"
	cat allOpenports.txt | $HOME/go/bin/httpx -t 70 -o $DirR/LiveWebServers.txt
	sendTele -c "$CHATID" -t "$TOKEN" -m '{nl}Httpx scan for [portscan] is done.{nl}Go start your URL gathering.{nl}Results name : [AllLiveDomains.txt].'
	printf "\n"

	##scans for swagger files on webserver ports
	printf "[|] SCANNING FOR SWAGGER PATH ON WEBSERVER PORTS\n====================================================================\n"
	sfuzz -l $DirR/LiveWebServers.txt -c 30 -w $DirW/swaggerwordlist.txt -o $DirR/ValidWebServerSwagger.txt
	printf "\n"

	##scans for secrets file on webserver ports
	printf "[|] SCANNING FOR SECRET FILES ON WEBSERVER PORTS \n====================================================================\n"
	dfuzz -l $DirR/LiveWebServers.txt -c 30 -w $DirW/secretlist.txt -o $DirR/ValidWebServerSecrets.txt
	printf "\n"
}

sendTele -c "$CHATID" -t "$TOKEN" -f "$1" -p
for domains in $(cat $1); do
	passive "$domains"
done

path=$(pwd)
folder_path="$path/recon"

for subfolder in "$folder_path"/*/; do
	if [ -e "$subfolder/allresults/uniqued.txt" ]; then
		cat "$subfolder/allresults/uniqued.txt" >>$folder_path/$DirR/passiveResult.txt
	fi
done

cd $folder_path && CheckerScan && portscan
sendtele -c "$CHATID" -t "$TOKEN" -m "{nl}Passive Subdomain Enumeration Done, Enjoy!!!"
