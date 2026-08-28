#!/bin/sh
# Lock wrapper: force the keyboard back to layout 0 (us) before locking.
#
# WHY: swaylock inherits whatever xkb group was active when the lock fired.
# With `xkb_layout "us,de,ru"`, locking while in Russian means every keystroke
# arrives as Cyrillic and the password can never match — the session is
# effectively unrecoverable from the lock screen. German is subtler but just as
# broken for a password containing y/z or punctuation.
#
# So: snapshot the current layout, switch every keyboard to index 0, lock, and
# restore the snapshot once swaylock exits. Combined with the `--locked` layout
# bindings in ../config, the lock screen always *starts* in us and can still be
# switched to de/ru with Alt+Shift if the password needs it.
#
# Used as $lock in ../config, so it covers all four swayidle paths (timeout,
# before-sleep, loginctl lock-session) and the $mod+Ctrl+l binding.
set -u

# Highest active index across all keyboards. The Alt+Shift binding drives
# `type:keyboard`, so they normally move in lockstep and this is just that
# shared value; max rather than first in case one device ever drifts (a
# keyboard hotplugged mid-session starts at 0 and would otherwise win).
saved=$(swaymsg -t get_inputs \
        | jq '[.[] | select(.type == "keyboard") | .xkb_active_layout_index] | max // 0')

swaymsg input type:keyboard xkb_switch_layout 0 >/dev/null

# -f: fork once the lock surface is actually up. swayidle's before-sleep hook
# waits on this command, and that wait is the only thing keeping the machine
# from suspending to an unlocked screen — do not background it instead.
swaylock -f

# Restore in a detached watcher so this script returns immediately (see above).
# swaylock -f orphans its own child, so there is no PID to wait on; polling for
# the process is the available option. Skipped entirely when we were already on
# us, which is the common case.
if [ "$saved" != "0" ]; then
    (
        while pgrep -x swaylock >/dev/null 2>&1; do
            sleep 1
        done
        swaymsg input type:keyboard xkb_switch_layout "$saved"
    ) >/dev/null 2>&1 &
fi
