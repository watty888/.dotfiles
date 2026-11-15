#!/bin/sh
# waybar custom/recorder: red "REC m:ss" pill while a screen recording runs,
# nothing otherwise. Click stops the recording.
#
# Reads the state file written by ~/.config/sway/scripts/record.sh, which also
# sends signal 11 once a second while recording, so this runs only then (and
# once at startup); it never polls.
set -u

state=${XDG_RUNTIME_DIR:-/tmp}/screen-recording

if [ -r "$state" ] && read -r pid start file < "$state" && kill -0 "$pid" 2>/dev/null; then
    el=$(($(date +%s) - start))
    text=$(printf '● REC %d:%02d' $((el / 60)) $((el % 60)))
    jq -cn --arg t "$text" --arg f "${file#"$HOME"/}" \
        '{text: $t, class: "recording",
          tooltip: ("Recording to ~/" + $f + "\nClick or $mod+Shift+Ctrl+e to stop")}'
else
    echo '{"text": ""}'
fi
