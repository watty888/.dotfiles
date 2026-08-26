#!/bin/sh
# Rotate the sway background through the images in ~/Pictures/Wallpapers.
#
# Started from .config/sway/config with exec_always, so a sway reload restarts
# it. The pidfile below kills the previous instance first — without it every
# reload stacks another timer and the wallpaper starts flipping several times
# per interval.
#
# Backgrounds are set with `swaymsg output "*" bg`, which leaves sway owning
# the swaybg process and swapping it atomically. Spawning swaybg directly
# would orphan one process per switch, and killing those orphans by hand is
# what makes most wallpaper scripts flicker between images.

set -eu

DIR="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"
INTERVAL="${WALLPAPER_INTERVAL:-86400}"   # seconds; 24 hours
MODE="${WALLPAPER_MODE:-fill}"          # swaybg scaling mode

PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/wallpaper-slideshow.pid"

sleep_pid=''

cleanup() {
	[ -z "$sleep_pid" ] || kill "$sleep_pid" 2>/dev/null || true
	rm -f "$PIDFILE"
}
# The handler must exit explicitly. A bare `trap 'cleanup' TERM` installs a
# handler that returns into the loop, which makes the script outlive the very
# SIGTERM the reload path sends it.
trap 'cleanup; exit 0' INT TERM
trap cleanup EXIT

# Sleep in the background and wait on it. A foreground `sleep` makes the shell
# defer the trap until the sleep returns, so a replaced instance would keep
# driving the background for up to a full interval before noticing it is dead.
nap() {
	sleep "$1" &
	sleep_pid=$!
	wait "$sleep_pid" 2>/dev/null || true
	sleep_pid=''
}

# Pids get recycled, so a stale pidfile must not shoot an unrelated process.
is_slideshow() {
	tr '\0' ' ' < "/proc/$1/cmdline" 2>/dev/null | grep -q 'wallpaper-slideshow'
}

if [ -r "$PIDFILE" ]; then
	old=$(cat "$PIDFILE" 2>/dev/null || true)
	case "$old" in
		'' | *[!0-9]*) ;;
		*)
			if [ "$old" != "$$" ] && is_slideshow "$old"; then
				kill "$old" 2>/dev/null || true
				# Confirm it is gone before taking over, otherwise both
				# instances drive the background until the old one catches up.
				i=0
				while [ "$i" -lt 50 ] && kill -0 "$old" 2>/dev/null; do
					sleep 0.1
					i=$((i + 1))
				done
				if kill -0 "$old" 2>/dev/null; then
					kill -9 "$old" 2>/dev/null || true
				fi
			fi
			;;
	esac
fi
echo $$ > "$PIDFILE"

# swaybg reads whatever gdk-pixbuf supports; this is the useful subset.
list_images() {
	find -L "$DIR" -maxdepth 1 -type f \
		\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
		-o -iname '*.webp' -o -iname '*.bmp' -o -iname '*.gif' \) |
		sort
}

last=''
warned=0

while :; do
	images=$(list_images | shuf)

	if [ -z "$images" ]; then
		# Warn once, then keep polling: the directory may be filled later.
		[ "$warned" -eq 1 ] || echo "wallpaper-slideshow: no images in $DIR" >&2
		warned=1
		nap "$INTERVAL"
		continue
	fi
	warned=0

	# Each pass walks a fresh shuffle, so every image shows once per cycle
	# instead of random draws repeating some and starving others. If the
	# shuffle happens to open on the image the last cycle ended with, rotate
	# it to the back so the same picture never sits through two intervals.
	if [ -n "$last" ] && [ "$(printf '%s\n' "$images" | head -1)" = "$last" ] &&
		[ "$(printf '%s\n' "$images" | wc -l)" -gt 1 ]; then
		images=$(printf '%s\n%s\n' "$(printf '%s\n' "$images" | tail -n +2)" "$last")
	fi

	# Heredoc rather than a pipe: a piped `while` runs in a subshell, and
	# $last would not survive back into the next cycle.
	while IFS= read -r img; do
		[ -n "$img" ] || continue
		if ! swaymsg -q output "*" bg "$img" "$MODE" 2>/dev/null; then
			# sway is gone (session ended) — nothing left to set.
			exit 0
		fi
		last="$img"
		nap "$INTERVAL"
	done <<-EOF
		$images
	EOF
done
