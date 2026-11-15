#!/bin/sh
# waybar custom/tailscale: tailnet state plus inbound remote sessions, as JSON.
#
#   connected  dim icon; nothing to see
#   remote     highlighted with a count: someone is logged in remotely (SSH,
#              plus any machine-local source, see below)
#   down       tailscaled stopped, logged out or not running — the phone
#              can't reach the laptop until this is fixed
#
# Remote sessions come from logind (pam_systemd registers every sshd login with
# Remote=yes and the peer address), so a session shows up whether or not it
# has a TTY. Peer addresses are mapped to tailnet host names where possible.
#
# Machine-local session sources can be added without touching this file: if
# remote-sessions.local (next to this script) exists and is executable, each
# line it prints, "SERVICE ADDRESS", is counted as one more session. That file
# is untracked on purpose (listed in ~/.dotfiles/info/exclude).
#
# Re-run on demand with: pkill -RTMIN+9 waybar   (signal 9 in config.jsonc)
set -u

icon="󰖂"

if ! st=$(tailscale status --json 2>/dev/null); then
    jq -cn --arg t "$icon off" \
        '{text: $t, class: "down", tooltip: "tailscaled is not running\n\nsudo systemctl start tailscaled"}'
    exit 0
fi

backend=$(printf '%s' "$st" | jq -r '.BackendState')
if [ "$backend" != Running ]; then
    jq -cn --arg t "$icon off" --arg b "$backend" \
        '{text: $t, class: "down", tooltip: ("Tailscale: " + $b + "\n\nsudo tailscale up")}'
    exit 0
fi

# Inbound remote logins: "user via service from host" lines, host as tailnet
# name if known.
sessions=""
n=0
peer_name() {
    printf '%s' "$st" | jq -r --arg ip "$1" \
        '[.Peer[] | select(.TailscaleIPs | index($ip)) | .HostName][0] // $ip'
}
for id in $(loginctl list-sessions --no-legend | awk '{print $1}'); do
    # Properties come back in systemd's own order, not the -p order: key=value.
    info=$(loginctl show-session "$id" -p Remote -p RemoteHost -p Name -p Service) || continue
    prop() { printf '%s\n' "$info" | sed -n "s/^$1=//p"; }
    [ "$(prop Remote)" = yes ] || continue
    host=$(prop RemoteHost) user=$(prop Name) svc=$(prop Service)
    sessions="$sessions
  $user via $svc from $(peer_name "$host")"
    n=$((n + 1))
done

local_src=$(dirname "$0")/remote-sessions.local
if [ -x "$local_src" ]; then
    while read -r svc host; do
        [ -n "$svc" ] || continue
        sessions="$sessions
  $svc from $(peer_name "${host:-?}")"
        n=$((n + 1))
    done <<EOF
$("$local_src" 2>/dev/null)
EOF
fi

peers=$(printf '%s' "$st" | jq -r '
    .Peer[] | "  " + (if .Online then "● " else "○ " end) + .HostName
        + (if .Online then "" else "  (seen " + (.LastSeen | .[0:16] | sub("T"; " ")) + " UTC)" end)')
ip=$(printf '%s' "$st" | jq -r '.Self.TailscaleIPs[0]')

tip="Tailscale: connected, $ip

Peers:
$peers"
if [ "$n" -gt 0 ]; then
    tip="$tip

Remote sessions:$sessions"
    text="$icon 󰣀 $n"
    class=remote
else
    text="$icon"
    class=connected
fi
tip="$tip

Click: copy $ip"

jq -cn --arg t "$text" --arg tip "$tip" --arg c "$class" \
    '{text: $t, tooltip: $tip, class: $c}'
