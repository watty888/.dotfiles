#!/bin/sh
# waybar custom/headset: battery of connected Bluetooth headphones/headsets,
# as waybar JSON lines. Absent unless such a device is connected AND reports
# its battery; then a battery icon that follows the level, with the
# percentage added (and class warning/critical) once it runs low. Hover lists
# each device and its level.
#
# Batteries come from upower, which mirrors BlueZ's Battery1 interface. Not
# every headset reports one; those simply don't show up here (the volume pill
# still turns into the Bluetooth icon when audio goes to them).
#
# Event-driven: `upower --monitor` prints a line when any device is added,
# removed or changes, and each line triggers a re-read.
set -u

WARN=20 CRIT=10   # percent

# U+F093E..F0946: battery 10..90 with a Bluetooth badge; U+F0949: full.
icons="󰤾 󰤿 󰥀 󰥁 󰥂 󰥃 󰥄 󰥅 󰥆 󰥈"

emit() {
    # "percent<TAB>name" per Bluetooth audio device that reports a battery.
    rows=$(for dev in $(upower -e 2>/dev/null | grep '_dev_'); do
        upower -i "$dev" 2>/dev/null | awk '
            /^ +model:/      { sub(/^ +model: +/, ""); model = $0 }
            /^ +percentage:/ { gsub(/[^0-9.]/, "", $2); pct = int($2) }
            /^  [a-z-]+$/    { kind = $1 }
            END { if (kind ~ /^(headset|headphones|speakers|audio)/ && pct != "")
                      printf "%d\t%s\n", pct, (model != "" ? model : kind) }'
    done | sort -n)

    if [ -z "$rows" ]; then
        echo '{"text": ""}'
        return
    fi

    low=$(printf '%s\n' "$rows" | head -n 1 | cut -f1)   # the emptiest one
    idx=$(((low + 5) / 10 - 1))   # nearest of 10..90, full
    [ "$idx" -lt 0 ] && idx=0; [ "$idx" -gt 9 ] && idx=9
    icon=$(printf '%s\n' $icons | sed -n "$((idx + 1))p")

    if [ "$low" -le "$CRIT" ]; then class=critical text="$icon $low%"
    elif [ "$low" -le "$WARN" ]; then class=warning text="$icon $low%"
    else class=normal text="$icon"
    fi
    tip=$(printf '%s\n' "$rows" | awk -F'\t' '{ printf "%s%s: %d%%", (NR > 1 ? "\n" : ""), $2, $1 }')

    jq -cn --arg t "$text" --arg tip "$tip" --arg c "$class" \
        '{text: $t, tooltip: $tip, class: $c}'
}

[ "${1:-}" = once ] && { emit; exit 0; }

# upower runs as our own background job feeding a FIFO, so we hold its PID
# and can stop it when waybar stops us (a pipeline would orphan it).
fifo=${XDG_RUNTIME_DIR:-/tmp}/waybar-headset.$$.fifo
rm -f "$fifo"
mkfifo "$fifo" || exit 1
upower --monitor > "$fifo" 2>/dev/null &
follower=$!
trap 'kill "$follower" 2>/dev/null; rm -f "$fifo"' EXIT
trap 'exit 0' TERM INT HUP

emit
while read -r _; do
    emit
done < "$fifo"
