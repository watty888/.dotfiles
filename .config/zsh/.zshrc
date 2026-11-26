# Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Oh My Zsh Configuration
export ZSH="$HOME/.oh-my-zsh"
export XDG_CONFIG_HOME="$HOME/.config"

# Homebrew — /opt/homebrew on Apple Silicon macOS, /home/linuxbrew on Linux,
# absent on most Arch installs. Loaded before Oh My Zsh so that plugins and the
# tool inits below (fzf, zoxide, nvim) find brew-installed binaries. Guarded:
# unguarded, a missing brew makes every single shell start with an error.
for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
  if [ -x "$_brew" ]; then
    eval "$("$_brew" shellenv zsh)"
    break
  fi
done
unset _brew

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(git zsh-autosuggestions zsh-syntax-highlighting fzf-tab)
case $OSTYPE in
  darwin*) plugins=(macos $plugins) ;;
  linux*)  [ -f /etc/arch-release ] && plugins=(archlinux $plugins) ;;
esac

source $ZSH/oh-my-zsh.sh

# Shell Options - History
setopt HIST_IGNORE_ALL_DUPS
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY

# fzf integration for Ctrl+R history search
if command -v fzf &> /dev/null; then
  # fzf >= 0.48 ships its own zsh integration (Homebrew's fzf on macOS); the
  # file paths below are for distro packages that only install the scripts.
  if fzf --zsh &> /dev/null; then
    source <(fzf --zsh)
  elif [ -f /usr/share/fzf/key-bindings.zsh ]; then
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
# Dotfiles live as real files in $HOME, tracked by a bare repo at ~/.dotfiles
# whose work-tree is $HOME. status.showUntrackedFiles=no is set on that repo,
# otherwise `dot status` would list every file in your home directory.
alias dot='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
alias swayconf="nvim $XDG_CONFIG_HOME/sway/config"
# After a reboot: load the GitLab key into the shared ssh-agent, so the
# claude-rc@* Remote Control servers can push from phone sessions.
alias gitlab-unlock='ssh-add ~/.ssh/id_ed25519_gitlab'
alias glu='gitlab-unlock'
alias github-unlock='ssh-add ~/.ssh/id_ed25519_github'
alias ghu='github-unlock'
alias hetzner-unlock='ssh-add -t 1h ~/.ssh/id_ed25519_hetzner'
alias hu='hetzner-unlock'
# Same for pass: cache the passphrase of the pass encryption subkey in
# gpg-agent until reboot (needs allow-preset-passphrase in gpg-agent.conf).
# Checked with a real decrypt; a wrong passphrase is cleared again.
pass-unlock() {
  local grip=613E4706D6FB75C2EDAB29BA4B0C27D984D62C58 pw
  local probe=$(find ~/.password-store -name '*.gpg' -print -quit)
  read -rs "pw?pass passphrase: " && print
  # Arch installs it under /usr/lib/gnupg, Homebrew under $(brew --prefix)/libexec.
  local preset=/usr/lib/gnupg/gpg-preset-passphrase
  [[ -x $preset ]] || preset=${HOMEBREW_PREFIX:-/opt/homebrew}/libexec/gpg-preset-passphrase
  print -r -- "$pw" | $preset --preset $grip
  unset pw
  if gpg --batch --pinentry-mode error -d "$probe" >/dev/null 2>&1; then
    print "pass unlocked until reboot (pass-lock to lock)"
  else
    gpg-connect-agent reloadagent /bye >/dev/null
    print "wrong passphrase, nothing cached" >&2
    return 1
  fi
}
# Clears every cached gpg passphrase.
alias pass-lock='gpg-connect-agent reloadagent /bye >/dev/null && print "pass locked"'
alias pu='pass-unlock'
alias pl='pass-lock'
alias экзоскелет="nvim"


# Powerlevel10k customization

# PATH Configuration
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

# zoxide (smart directory jumping)
if command -v zoxide &> /dev/null; then
  eval "$(zoxide init --no-cmd zsh)"
  alias z='__zoxide_z'
  alias zi='__zoxide_zi'
fi

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

# Jenv (Java version manager) - lazy-loaded on first use.
# jenv installs into ~/.jenv/bin, which is not on PATH by default — without
# this line the lazy-loader below can never find the binary it shells out to.
[ -d "$HOME/.jenv/bin" ] && export PATH="$HOME/.jenv/bin:$PATH"
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

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# To customize prompt, run `p10k configure` or edit ~/.config/zsh/.p10k.zsh.
[[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh

# Follow the desktop light/dark theme ($mod+Shift+t, ~/.config/sway/scripts/theme-switch.sh):
# .p10k.zsh picks its palette from the recorded theme, so when that changes, re-source it
# and reload the prompt. Runs before p10k's own precmd, so the very next prompt is recoloured.
_p10k_follow_theme() {
  local f=${XDG_STATE_HOME:-$HOME/.local/state}/desktop-theme t=latte
  [[ -r $f && "$(<$f)" == mocha ]] && t=mocha
  [[ $t == ${_p10k_theme:-} ]] && return
  source ~/.config/zsh/.p10k.zsh && (( $+functions[p10k] )) && p10k reload
}
precmd_functions=(_p10k_follow_theme $precmd_functions)
