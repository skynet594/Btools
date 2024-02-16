export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="alanpeabody"
#plugins=(git)
source $ZSH/oh-my-zsh.sh


export PATH=$PATH:$HOME/.local/bin
export PATH=$PATH:$HOME/tools
export PATH=$PATH:$HOME/.cargo/bin/
### GoLang ####
export GOPATH=$HOME/go/
export GOROOT=/usr/local/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin


# editors
setnvim() {
	alias v="nvim"
	alias sv="sudo nvim"
	alias dnvim="cd $HOME/.config/nvim"
	alias vzsh="nvim $HOME/.zshrc"
}
[ -f /bin/zsh ] && setnvim

alias n="nano"
alias th="touch"
alias e="exit"
alias cl="clear"
alias rzsh="source $HOME/.zshrc"
alias p3="python3"

# Pip
function Pip() {
	pip ${@} --break-system-packages
}
