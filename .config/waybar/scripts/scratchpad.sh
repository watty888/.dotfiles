#!/bin/sh
# waybar custom/scratchpad: count of windows hidden in the sway scratchpad, as
# waybar JSON lines. Hidden entirely when the scratchpad is empty; hover lists
# what's in it.
#
# Replaces waybar's built-in sway/scratchpad module because that one can't
# leave a window out: btop lives in the scratchpad permanently (see
# ~/.config/sway/config.d/scratchpad.conf), so it would always count, and the
# indicator would never go away. Windows matching SKIP aren't counted.
#
# Event-driven: `swaymsg -t subscribe` delivers one line per window event;
# only the ones that can change the scratchpad (new, close, move, floating)
# trigger a recount. Title and focus changes, by far the most frequent, are
# ignored without doing any work.
set -u

SKIP='sysmon-btop'   # app_ids to leave out, as a jq regex

emit() {
    swaymsg -t get_tree | jq -c --arg skip "^($SKIP)$" '
        [.. | objects | select(.name? == "__i3_scratch") | .floating_nodes[]
         | .. | objects | select(.pid?)
         | select((.app_id // "") | test($skip) | not)
         | "\(.app_id // .window_properties.class // "?"): \(.name // "")"] as $w
        | if ($w | length) == 0 then {text: "", class: "empty"}
          else {text: "\($w | length)", tooltip: ($w | join("\n")),
                class: "occupied"} end'
}

# swaymsg runs as our own background job feeding a FIFO, not as the left side
# of a pipe, so we hold its PID: waybar only signals this script when it exits
# or reloads, and a pipeline would leave the subscriber orphaned.
fifo=${XDG_RUNTIME_DIR:-/tmp}/waybar-scratchpad.$$.fifo
rm -f "$fifo"
mkfifo "$fifo" || exit 1
swaymsg -t subscribe -m '["window"]' > "$fifo" 2>/dev/null &
follower=$!
trap 'kill "$follower" 2>/dev/null; rm -f "$fifo"' EXIT
trap 'exit 0' TERM INT HUP

emit
while read -r line; do
    case $line in
        '{ "change": "new"'* | '{ "change": "close"'* | \
        '{ "change": "move"'* | '{ "change": "floating"'*) emit ;;
    esac
done < "$fifo"
