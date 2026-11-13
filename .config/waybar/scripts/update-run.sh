#!/bin/sh
# Left-click on the Arch logo: run a full upgrade in kitty, then refresh the
# count in waybar. The window stays open until Enter so errors can be read.
kitty --title "System update" sh -c '
    paru
    echo
    printf "Done. Press Enter to close."
    read _
'
pkill -RTMIN+8 waybar
