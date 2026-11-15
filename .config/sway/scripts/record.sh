#!/bin/sh
# Screen recording with wf-recorder, with a live indicator in waybar.
#
#   record.sh start   pick a region with slurp (Esc cancels) and record it to
#                     ~/Videos/recording_<date>.mp4     ($mod+Shift+Ctrl+r)
#   record.sh stop    finish the recording               ($mod+Shift+Ctrl+e,
#                                                         or click the REC pill)
#
# While recording, `start` stays alive: it records the PID, start time and
# file in $XDG_RUNTIME_DIR/screen-recording for waybar's custom/recorder
# (scripts/recorder.sh), pokes waybar once a second so the timer ticks, and
# cleans up and reports the saved file when wf-recorder exits. Nothing runs
# when not recording.
#
# The privacy module can't flag this: wf-recorder captures through
# wlr-screencopy, not PipeWire.
set -u

state=${XDG_RUNTIME_DIR:-/tmp}/screen-recording
refresh() { pkill -RTMIN+11 -x waybar; }   # signal 11 in waybar's config.jsonc

case ${1:-} in
    start)
        if [ -s "$state" ] && kill -0 "$(cut -d' ' -f1 "$state")" 2>/dev/null; then
            notify-send -t 3000 "Already recording" "Stop it with \$mod+Shift+Ctrl+e or the REC pill."
            exit 0
        fi
        geom=$(slurp) || exit 0
        mkdir -p "$HOME/Videos"
        file=$HOME/Videos/recording_$(date +%F_%H-%M-%S).mp4

        wf-recorder -g "$geom" -f "$file" >/dev/null 2>&1 &
        pid=$!
        printf '%s %s %s\n' "$pid" "$(date +%s)" "$file" > "$state"

        # Tick the bar's timer while wf-recorder runs. `wait` (not a kill -0
        # loop) so the exited recorder is reaped instead of lingering as a
        # zombie that still "exists".
        ( while :; do refresh; sleep 1; done ) &
        ticker=$!
        wait "$pid"
        kill "$ticker" 2>/dev/null
        rm -f "$state"
        refresh

        if [ -s "$file" ]; then
            notify-send -t 5000 "Recording saved" "${file#"$HOME"/}"
        else
            rm -f "$file"
            notify-send -u critical "Recording failed" "wf-recorder produced no file."
        fi
        ;;
    stop)
        pkill -INT -x wf-recorder ;;
    *)
        echo "usage: ${0##*/} start|stop" >&2; exit 2 ;;
esac
