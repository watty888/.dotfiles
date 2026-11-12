#!/bin/sh
# theme-switch.sh — flip the desktop between Catppuccin Latte (light) and Mocha (dark).
#
#   theme-switch.sh toggle        switch to the other theme ($mod+Shift+t in ../config)
#   theme-switch.sh latte|mocha   switch to that theme
#   theme-switch.sh apply         re-apply the recorded theme, e.g. after a fresh dotfiles
#                                 checkout, where the untracked symlinks below don't exist yet
#
# The recorded theme is one word in $XDG_STATE_HOME/desktop-theme.
#
# Each app keeps both palettes as tracked files under <app>/themes/, and its config pulls in
# an UNTRACKED symlink that this script points at one of them (untracked so that switching
# never shows up in `dot status`):
#
#   sway      sway/theme.conf          -> themes/{latte,mocha}.conf    (include in config)
#   waybar    waybar/theme.css         -> themes/{latte,mocha}.css     (@import in style.css)
#   mako      mako/theme               -> themes/{latte,mocha}         (include= in config)
#   fuzzel    fuzzel/theme.ini         -> themes/{latte,mocha}.ini     (include= in fuzzel.ini)
#   swaylock  swaylock/theme           -> themes/{latte,mocha}         (turned into flags by lock.sh)
#   kitty     kitty/current-theme.conf -> themes/catppuccin-{latte,mocha}.conf
#
# The zsh prompt reads the recorded theme itself (.p10k.zsh, reloaded by a precmd hook in
# .zshrc). Neovim is switched only while it is on a catppuccin flavour, so a different
# colorscheme picked with <Leader>ft is left alone.
set -u

cfg=${XDG_CONFIG_HOME:-$HOME/.config}
state=${XDG_STATE_HOME:-$HOME/.local/state}
statefile=$state/desktop-theme

current=latte
[ -r "$statefile" ] && [ "$(cat "$statefile")" = mocha ] && current=mocha

case "${1:-toggle}" in
    toggle) if [ "$current" = latte ]; then theme=mocha; else theme=latte; fi ;;
    latte | mocha) theme=$1 ;;
    apply) theme=$current ;;
    *) echo "usage: ${0##*/} [toggle|latte|mocha|apply]" >&2; exit 2 ;;
esac

mkdir -p "$state"
printf '%s\n' "$theme" > "$statefile"

# ── Point every app at the theme's files ─────────────────────────────────────
# Relative targets, resolved from the link's own directory.
link() { ln -sfn "$2" "$cfg/$1"; }
link sway/theme.conf          "themes/$theme.conf"
link waybar/theme.css         "themes/$theme.css"
link mako/theme               "themes/$theme"
link fuzzel/theme.ini         "themes/$theme.ini"
link swaylock/theme           "themes/$theme"
link kitty/current-theme.conf "themes/catppuccin-$theme.conf"
# fuzzel and swaylock read their files on every launch; nothing further to do for them.

# ── Recolour what is already running ─────────────────────────────────────────
# sway: apply the window colours directly. Not `swaymsg reload`: that re-runs every
# exec_always (restarting waybar, kanshi and the wallpaper slideshow), and the theme's
# `output * bg` line would cover the current wallpaper. That line only matters at startup.
grep '^client\.' "$cfg/sway/theme.conf" | while IFS= read -r line; do
    swaymsg -q "$line"
done

pkill -USR2 -x waybar   # reload style.css
makoctl reload
pkill -USR1 -x kitty    # every kitty window re-reads kitty.conf

# Neovim: the next start reads its persisted colorscheme (see ~/.config/nvim/lua/theme.lua);
# running instances are switched over their RPC sockets.
nvim_state=$state/nvim/colorscheme
nvim_current=$(cat "$nvim_state" 2>/dev/null || echo catppuccin)
case "$nvim_current" in
    catppuccin*)
        mkdir -p "$state/nvim"
        printf '%s\n' "catppuccin-$theme" > "$nvim_state"
        for sock in "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"/nvim.*.0; do
            [ -S "$sock" ] || continue
            running=$(timeout 2 nvim --server "$sock" --remote-expr 'g:colors_name' 2>/dev/null) || continue
            case "$running" in
                catppuccin*) timeout 2 nvim --server "$sock" \
                    --remote-expr "execute('colorscheme catppuccin-$theme')" >/dev/null 2>&1 ;;
            esac
        done
        ;;
esac

# GTK/libadwaita apps and browsers follow this through xdg-desktop-portal-gtk.
if [ "$theme" = mocha ]; then scheme=prefer-dark; else scheme=prefer-light; fi
gsettings set org.gnome.desktop.interface color-scheme "$scheme" 2>/dev/null

# Shown after `makoctl reload`, so the notification itself is already in the new colours.
if [ "$theme" = mocha ]; then name="Catppuccin Mocha (dark)"; else name="Catppuccin Latte (light)"; fi
notify-send -a theme-switch -t 1500 "Theme" "$name" 2>/dev/null
exit 0
