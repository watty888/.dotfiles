#!/bin/sh
# waybar custom/arch: Arch logo plus pending-update count, as waybar JSON.
#
# checkupdates (pacman-contrib) syncs a throwaway copy of the package
# databases, so it never causes a partial upgrade the way `pacman -Sy` would.
# paru -Qua asks the AUR. Either one failing (offline, AUR down) is treated
# as "nothing known" rather than an error, so the logo just stays plain.
#
# Re-run on demand with: pkill -RTMIN+8 waybar   (signal 8 in config.jsonc)
set -u

logo=$(printf '\357\214\203')   # U+F303 nf-linux-archlinux

repo=$(checkupdates 2>/dev/null)
aur=$(paru -Qua 2>/dev/null)

count() { [ -n "$1" ] && printf '%s\n' "$1" | wc -l || echo 0; }
nr=$(count "$repo")
na=$(count "$aur")
total=$((nr + na))

if [ "$total" -eq 0 ]; then
    jq -cn --arg t "$logo" \
        '{text: $t, class: "uptodate", tooltip: "System up to date\nRight-click: power menu"}'
    exit 0
fi

tip="$nr repo, $na AUR"
[ "$nr" -gt 0 ] && tip="$tip\n\n$(printf '%s\n' "$repo" | head -n 25)"
[ "$nr" -gt 25 ] && tip="$tip\n… and $((nr - 25)) more"
[ "$na" -gt 0 ] && tip="$tip\n\nAUR:\n$(printf '%s\n' "$aur" | head -n 15)"
tip="$tip\n\nClick: update · Right-click: power menu"

jq -cn --arg t "$logo $total" --arg tip "$(printf '%b' "$tip")" \
    '{text: $t, class: "updates", tooltip: $tip}'
