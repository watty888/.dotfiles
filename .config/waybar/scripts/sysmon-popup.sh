#!/bin/sh
# Clicks on the system-health pill (custom/sysmon).
#
#   sysmon-popup.sh btop    left-click: show/hide btop (graphs, temps, GPU,
#                           processes), kept running in the sway scratchpad
#   sysmon-popup.sh htop    right-click: toggle a floating htop for detailed
#                           process work, started fresh each time
#
# btop is started hidden at login by ~/.config/sway/config.d/scratchpad.conf
# (app_id "sysmon-btop") and keeps running, so its graphs have history when
# shown. If it was quit, a click launches it again and shows it.
#
# htop opens in kitty with app_id "sysmon-popup", which the sway config floats
# and centres. Clicking again while it's open closes it.
set -u

tool=${1:-btop}
case $tool in
    btop | htop) ;;
    *) echo "usage: ${0##*/} [btop|htop]" >&2; exit 2 ;;
esac

# New windows open beside the focused one. If that one sits inside a floating
# split container (a floating window that was split), the new window would land
# in that container, and sway applies `floating enable` / `move scratchpad` to
# the whole already-floating container instead. Focusing up to the container
# first makes the new window open on its own.
in_floating_split() {
    swaymsg -t get_tree | jq -e '[.. | objects | .floating_nodes?[]? | .nodes[]
        | .. | objects | select(.focused? == true)] | length > 0' >/dev/null
}
unsplit_focus() {
    i=0
    while [ $i -lt 5 ] && in_floating_split; do
        swaymsg -q focus parent
        i=$((i + 1))
    done
}

if [ "$tool" = htop ]; then
    swaymsg -q '[app_id="^sysmon-popup$"] kill' 2>/dev/null && exit 0
    unsplit_focus
    exec kitty --class sysmon-popup --title htop -o background_opacity=1 htop
fi

# ── btop: scratchpad toggle ──────────────────────────────────────────────────
crit='[app_id="^sysmon-btop$"]'

# none | hidden (in the scratchpad) | focused | shown (visible, not focused)
state() {
    swaymsg -t get_tree | jq -r '[.. | objects | select(.app_id? == "sysmon-btop")][0]
        | if . == null then "none"
          elif .visible != true then "hidden"
          elif .focused then "focused"
          else "shown" end'
}
show() {
    # Sized on every show, so it fits whichever output it appears on.
    swaymsg -q "$crit scratchpad show, resize set width 75 ppt height 80 ppt, move position center"
}

case $(state) in
    focused) swaymsg -q "$crit move scratchpad" ;;   # hide
    shown)   swaymsg -q "$crit focus" ;;             # bring it forward
    hidden)  show ;;
    none)
        # Not running (quit with q): start it. The sway rule moves it to the
        # scratchpad as it maps; show it once it's there.
        unsplit_focus
        setsid -f kitty --class sysmon-btop --title btop -o background_opacity=1 btop \
            >/dev/null 2>&1
        i=0
        while [ $i -lt 30 ]; do
            sleep 0.1
            [ "$(state)" = hidden ] && { show; break; }
            i=$((i + 1))
        done ;;
esac
