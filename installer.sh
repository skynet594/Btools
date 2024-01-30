#!/bin/bash

go="go1.21.5.linux-amd64.tar.gz"

sudo apt update && sudo apt upgrade -y
sudo apt install wget unzip tmux python3 python3-dev python3-pip git nmap zsh libpcap-dev jq-y

wget https://go.dev/dl/$go
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf $go
sudo ln -sf /usr/local/go/bin/go /usr/local/bin/
rm -rf $go

cd
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$HOME/.local/bin:$PATH
cd

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

source .bashrc

printf 'Installing the following Tools\n'

printf '[>] My Personal Tools\n'

packages=(
    "github.com/SpeedyQweku/dnsdump@latest"
    "github.com/SpeedyQweku/sfuzz@latest"
    "github.com/SpeedyQweku/sendTele@latest"
    "github.com/SpeedyQweku/RealTime@latest"
    "github.com/SpeedyQweku/dfuzz@latest"
)

for package in "${packages[@]}"; do
    if go install "$package"; then
        echo "Package $package installed successfully"
    else
        echo "Error installing package $package"
        exit 1
    fi
done

printf '[>] Amass\n'
go install -v github.com/owasp-amass/amass/v4/...@master

printf '[>] Smap\n'
go install -v github.com/s0md3v/smap/cmd/smap@latest

printf '[>] Subfinder\n'
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest

printf '[>] Nuclei\n'
go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest

printf '[>] Dnstake\n'
go install github.com/pwnesia/dnstake/cmd/dnstake@latest

printf '[>] Assetfinder\n'
go install github.com/tomnomnom/assetfinder@latest

printf '[>] Gau\n'
go install github.com/lc/gau/v2/cmd/gau@latest

printf '[>] Waybackurls\n'
go install github.com/tomnomnom/waybackurls@latest

printf '[>] Github-subdomains\n'
go install github.com/gwen001/github-subdomains@latest

printf '[>] Crobat\n'
go install github.com/cgboal/sonarsearch/cmd/crobat@latest

printf '[>] gf\n'
go install github.com/tomnomnom/gf@latest

printf '[>] Anew\n'
go install -v github.com/tomnomnom/anew@master

printf '[>] Tlsx'
go install github.com/projectdiscovery/tlsx/cmd/tlsx@latest

printf '[>] Puredns\n'
go install github.com/d3mondev/puredns/v2@latest

printf '[>] Gotator\n'
go install -v github.com/Josue87/gotator@latest

printf '[>] Gospider\n'
go install github.com/jaeles-project/gospider@latest

printf '[>] Unfurl\n'
go install github.com/tomnomnom/unfurl@latest

printf '[>] Cero\n'
go install github.com/glebarez/cero@latest

printf '[>] Httpx\n'
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest

printf '[>] Httprobe\n'
go install github.com/tomnomnom/httprobe@master

printf '[>] gitlab-subdomains'
go install github.com/gwen001/gitlab-subdomains@latest

printf '[>] shosubgo'
go install github.com/incogbyte/shosubgo@latest

printf '[>] naabu'
go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest

printf '[>] subjack'
go install github.com/haccer/subjack@latest

printf '[>] trufflehog'
curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b /usr/local/bin

printf '[>] ffuf'
go install github.com/ffuf/ffuf/v2@latest

printf '[>] meg'
go install github.com/tomnomnom/meg@master

printf '[>] Sqlite\n'
wget https://www.sqlite.org/2024/sqlite-tools-linux-x64-3450000.zip
sudo mv sqlite3 sqldiff sqlite3_analyzer /usr/bin/
rm -rf sqlite-tools-linux-x64-3450000.zip

source .bashrc
printf '[>] Massdns\n'
git clone https://github.com/blechschmidt/massdns.git
cd massdns && make && sudo make install
cd && rm -rf massdns

printf '[>] Findomain\n'
wget -N -c https://github.com/Findomain/Findomain/releases/download/9.0.0/findomain-linux.zip
unzip findomain-linux.zip
sudo mv findomain /usr/local/bin/findomain
chmod 755 /usr/local/bin/findomain
rm -rf findomain-linux.zip

printf '[>] RustScan\n'
git clone https://github.com/RustScan/RustScan.git
cd RustScan && cargo build --release
sudo cp ./target/release/rustscan /usr/local/bin
rm -rf RustScan

printf '[>] Postgresql\n'
sudo sh -c 'echo "deb https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get -y install postgresql

cd
echo 'export PATH=$PATH:$HOME/go/bin' >>.bashrc

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

source .bashrc

printf 'All your tools are installed,Enjoy hacking Sir!!!\n'

# printf '[>] Unimap\n'
# git clone https://github.com/Edu4rdSHL/unimap.git && cd unimap
# cargo build --release
# sudo cp ./target/release/unimap /usr/local/bin
# cd

# printf '[>] Dnsvalidator\n'
# git clone https://github.com/vortexau/dnsvalidator.git
# cd dnsvalidator/
# python3 setup.py install
# pip3 install -r requirements.txt
# pip3  install setuptools==58.2.0
# cd
