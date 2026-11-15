#!/bin/sh
# waybar custom/media: "now playing" from any MPRIS player, as waybar JSON.
#
# Replaces waybar's built-in mpris module, which falls back to "the first
# valid player" when the active one quits. With a browser around, that is an
# idle player in state Stopped, for which waybar skips updates, so the dead
# track's title stayed on the bar. Here every update picks afresh:
#
#   1. a player that is Playing (Spotify first if several are)
#   2. else one that is Paused (Spotify first)
#   3. else nothing: empty text, and waybar hides the module
#
# Event-driven: `playerctl --follow` stays on D-Bus and prints a line whenever
# any player's track or status changes, or a player appears or quits. Each
# line triggers one re-evaluation; nothing runs in between.
#
# The chosen player is remembered so the click actions hit the one shown.
#
#   media.sh                       follow, printing JSON lines (waybar exec)
#   media.sh once                  print the current JSON once and exit
#   media.sh play-pause|next|previous
#   media.sh show                  raise the player's window
set -u

state=${XDG_RUNTIME_DIR:-/tmp}/waybar-media.player

case ${1:-} in
    play-pause|next|previous)
        p=$(cat "$state" 2>/dev/null) || exit 0
        exec playerctl -p "$p" "$1" ;;
    show)
        p=$(cat "$state" 2>/dev/null) || exit 0
        case $p in
            spotify) exec ~/.config/sway/scripts/scratch-toggle.sh spotify ;;
            # Browsers and others: focus a window whose app_id or X11 class
            # contains the player's name (brave -> brave-browser, mpv -> mpv).
            *) name=${p%%.*}
               swaymsg -q "[app_id=\"(?i)$name\"] focus" 2>/dev/null ||
               swaymsg -q "[class=\"(?i)$name\"] focus" 2>/dev/null ;;
        esac
        exit 0 ;;
esac

sep=$(printf '\037')  # unit separator: unlike tab, read won't merge empty fields

# The bar text is Pango markup: escape what came from the player.
esc() { printf '%s' "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'; }

emit() {
    # One line per player that has metadata: status, full name
    # (brave.instanceN), title, artist, album. Players with nothing loaded
    # fail and are skipped.
    list=$(playerctl -a metadata --format \
        "{{status}}$sep{{playerInstance}}$sep{{title}}$sep{{artist}}$sep{{album}}" 2>/dev/null)

    pick() {  # status -> first matching line, spotify preferred
        printf '%s\n' "$list" | awk -F'\037' -v s="$1" '
            $1 == s && $2 ~ /^spotify/ { print; found = 1; exit }
            $1 == s && !first          { first = $0 }
            END { if (!found && first) print first }'
    }
    line=$(pick Playing)
    [ -n "$line" ] || line=$(pick Paused)

    if [ -z "$line" ]; then
        rm -f "$state"
        echo '{"text": "", "class": "none"}'
        return
    fi

    IFS="$sep" read -r status player title artist album <<EOF
$line
EOF
    printf '%s' "$player" > "$state"

    case ${player%%.*} in
        spotify)                           icon="󰓇" ;;
        brave|chromium|chrome|firefox*)    icon="󰖟" ;;
        mpv|vlc)                           icon="󰐹" ;;
        *)                                 icon="󰐊" ;;
    esac

    what=$(esc "$title")
    [ -n "$artist" ] && what="$what - $(esc "$artist")"

    if [ "$status" = Paused ]; then
        text="󰏤 <i>$what</i>"
        class=paused
    else
        text="$icon $what"
        class=playing
    fi

    tip=$(esc "$title")
    [ -n "$artist" ] && tip="$tip
$(esc "$artist")"
    [ -n "$album" ] && tip="$tip — $(esc "$album")"
    tip="$tip

${player%%.*} · $status
Click: play/pause · right: next · middle: show window"

    jq -cn --arg t "$text" --arg tip "$tip" --arg c "$class" --arg p "${player%%.*}" \
        '{text: $t, tooltip: $tip, class: [$c, $p]}'
}

if [ "${1:-}" = once ]; then emit; exit 0; fi

# Follow mode. playerctl prints a line per change (an empty one when a player
# quits); the content doesn't matter, each line just triggers a re-evaluation.
#
# playerctl runs as our own background job feeding a FIFO, not as the left
# side of a pipe, so we hold its PID: waybar only signals this script when it
# exits or reloads, and a pipeline would leave the follower orphaned.
# If playerctl dies by itself (D-Bus restart), read hits EOF and we exit;
# waybar restarts us after "restart-interval".
fifo=${XDG_RUNTIME_DIR:-/tmp}/waybar-media.$$.fifo
rm -f "$fifo"
mkfifo "$fifo" || exit 1
playerctl -a --follow metadata --format \
    "{{playerInstance}}$sep{{status}}$sep{{title}}$sep{{artist}}$sep{{album}}" \
    > "$fifo" 2>/dev/null &
follower=$!
trap 'kill "$follower" 2>/dev/null; rm -f "$fifo"' EXIT
trap 'exit 0' TERM INT HUP

emit
while read -r _; do
    emit
done < "$fifo"
