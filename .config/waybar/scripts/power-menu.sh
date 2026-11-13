#!/bin/sh
# Right-click on the Arch logo: power menu via fuzzel's dmenu mode.
#
# "Reboot into Windows" uses grub-reboot, which sets GRUB's next_entry for the
# next boot only; grub.cfg clears it again on that boot, so Arch stays the
# default afterwards. grub-reboot writes /boot/grub/grubenv and so needs root;
# /etc/sudoers.d/50-grub-reboot-windows allows exactly this one command
# without a password. The entry title must match /etc/grub.d/40_custom.
set -u

windows_entry='Windows Boot Manager'

choice=$(printf '%s\n' \
    "󰌾  Lock" \
    "󰤄  Suspend" \
    "󰍃  Log out" \
    "󰜉  Reboot" \
    "󰖳  Reboot into Windows" \
    "󰐥  Shut down" \
    | fuzzel --dmenu --prompt "Power: " --lines 6 --width 28) || exit 0

case "$choice" in
    *Lock)      exec ~/.config/sway/scripts/lock.sh ;;
    *Suspend)   exec systemctl suspend ;;
    *"Log out") exec swaymsg exit ;;
    *Windows)
        if sudo -n /usr/bin/grub-reboot "$windows_entry"; then
            exec systemctl reboot
        else
            notify-send -u critical "Reboot into Windows failed" \
                "grub-reboot needs the sudoers rule in /etc/sudoers.d/50-grub-reboot-windows"
        fi ;;
    *Reboot)    exec systemctl reboot ;;
    *"Shut down") exec systemctl poweroff ;;
esac
