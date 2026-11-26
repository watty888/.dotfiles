# zsh reads ~/.zshenv before anything else and before it knows where ZDOTDIR
# points, so this file has to sit in $HOME itself — it cannot be moved under
# .config/zsh with the rest of the shell config. It is symlinked from the repo.
#
# Without this, zsh reads ~/.zshrc and never sees .config/zsh/.zshrc at all.
export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
# Guarded: rustup is not installed on every machine, and an unguarded `.` of a
# missing file prints an error at the start of every shell.
[ -r "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Linux only: point ssh at the socket-activated OpenSSH agent (systemd user
# unit ssh-agent.socket). Without this SSH_AUTH_SOCK is unset, ssh-add has no
# agent to talk to, and ~/.ssh/config's `AddKeysToAgent yes` silently does
# nothing. macOS already sets SSH_AUTH_SOCK to launchd's agent, which talks to
# the Keychain; overriding it there would break ssh-add.
if [[ $OSTYPE == linux* ]]; then
  export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR:-/run/user/$UID}/ssh-agent.socket"
fi
