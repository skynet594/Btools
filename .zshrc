export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="alanpeabody"

source $ZSH/oh-my-zsh.sh

if [[ -n $SSH_CONNECTION ]]; then
	export EDITOR='vim'
else
	export EDITOR='mvim'
fi

export PATH=$PATH:$HOME/go/bin
export PATH=$PATH:$GOPATH/bin
export PATH=$PATH:$HOME/.local/bin

# Pip
function Pip() {
	pip ${@} --break-system-packages
}

alias cl="clear"
alias e="exit"

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
