#!/bin/sh
# Toggle a scratchpad app, launching it first if it has no window.
#   scratch-toggle.sh spotify|telegram|discord|thunar
#
# Bound in .config/sway/config.d/scratchpad.conf. The criteria here must match
# the for_window rules there, which are what put a freshly launched window into
# the scratchpad (and show it).
#
# Order of attempts:
#   1. window is in the scratchpad      -> show/hide it
#   2. window exists but isn't (tiled)  -> focus it
#   3. no window (not running, or only
#      sitting in the tray)             -> launch; single-instance apps like
#                                          Telegram/Discord just reopen their window
# swaymsg exits non-zero when the criteria match nothing or the command fails,
# which is what moves us down the list.

case $1 in
    spotify)  crit='[class="^Spotify$"]';                             cmd=spotify-launcher ;;
    telegram) crit='[app_id="^org\.telegram\.desktop$" title="^Telegram"]'; cmd=Telegram ;;
    discord)  crit='[app_id="^discord$"]';                            cmd=discord ;;
    thunar)   crit='[app_id="^thunar$" title=" - Thunar$"]';          cmd=thunar ;;
    *) echo "usage: $0 spotify|telegram|discord|thunar" >&2; exit 2 ;;
esac

swaymsg -q "$crit scratchpad show" 2>/dev/null && exit 0
swaymsg -q "$crit focus" 2>/dev/null && exit 0
exec $cmd
