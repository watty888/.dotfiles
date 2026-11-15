#!/bin/sh
# Do-not-disturb for mako, and its waybar indicator.
#
#   dnd.sh           waybar custom/dnd: a bell-off icon while mako is in
#                    do-not-disturb mode, nothing otherwise
#   dnd.sh toggle    switch do-not-disturb on/off   ($mod+Ctrl+n)
#   dnd.sh off       switch it off                  (click on the icon)
#
# toggle/off refresh the icon right away with signal 12. mako has no change
# events, so waybar also re-runs this once a minute, in case the mode was
# changed some other way or mako restarted.
#
# The toggle lives here rather than inline in the sway binding: a binding
# applied with swaymsg gets split at its ";" and silently fails.
set -u

refresh() { pkill -RTMIN+12 -x waybar; }   # signal 12 in waybar's config.jsonc

case ${1:-} in
    toggle) makoctl mode -t do-not-disturb >/dev/null; refresh; exit ;;
    off)    makoctl mode -r do-not-disturb >/dev/null; refresh; exit ;;
esac

if makoctl mode 2>/dev/null | grep -qx do-not-disturb; then
    jq -cn '{text: "󰂛", class: "dnd",
             tooltip: "Do not disturb: notifications are hidden, not lost\n(makoctl restore brings them back)\n\nClick or $mod+Ctrl+n to turn off"}'
else
    echo '{"text": ""}'
fi
