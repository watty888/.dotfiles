# Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Oh My Zsh Configuration
export ZSH="$HOME/.oh-my-zsh"
export XDG_CONFIG_HOME="$HOME/.config"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(git archlinux zsh-autosuggestions zsh-syntax-highlighting fzf-tab)

source $ZSH/oh-my-zsh.sh

# Shell Options - History
setopt HIST_IGNORE_ALL_DUPS
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY

# fzf integration for Ctrl+R history search
if command -v fzf &> /dev/null; then
  if [ -f /usr/share/fzf/key-bindings.zsh ]; then
    source /usr/share/fzf/key-bindings.zsh
  elif [ -f ~/.fzf/shell/key-bindings.zsh ]; then
    source ~/.fzf/shell/key-bindings.zsh
  fi
fi

# Double-Escape to prepend sudo to last command
sudo-command-line() {
  [[ -z $BUFFER ]] && BUFFER="$(fc -ln -1)"
  if [[ $BUFFER != sudo\ * ]]; then
    BUFFER="sudo $BUFFER"
  fi
  CURSOR=${#BUFFER}
}
zle -N sudo-command-line
bindkey '\e\e' sudo-command-line

# Editor Configuration
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

# Aliases
alias zshconfig="nvim $XDG_CONFIG_HOME/zsh/.zshrc"
alias zshupdate="source $XDG_CONFIG_HOME/zsh/.zshrc"
alias ohmyzsh="nvim $ZSH"
alias kitty-conf="nvim $XDG_CONFIG_HOME/kitty/kitty.conf"
alias v="nvim"
alias dot='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias swayconf="nvim $XDG_CONFIG_HOME/sway/config"


# Powerlevel10k customization
[[ ! -f $HOME/.p10k.zsh ]] || source $HOME/.p10k.zsh

# PATH Configuration
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

# zoxide (smart directory jumping)
eval "$(zoxide init --no-cmd zsh)"
alias z='__zoxide_z'
alias zi='__zoxide_zi'

# Tool Initialization

# fnm (Fast Node Manager)
FNM_PATH="$HOME/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "$(fnm env --shell zsh)"
fi

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Jenv (Java version manager) - lazy-loaded on first use
jenv() {
  unfunction jenv
  eval "$(command jenv init -)"
  jenv "$@"
}

# Envman - lazy-loaded on first use
envman() {
  unfunction envman
  [ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"
  [ -n "$1" ] && envman "$@"
}

# Homebrew (Linuxbrew)
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"
