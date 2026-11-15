#!/bin/sh
# waybar custom/sysmon: one compact system-health indicator, as waybar JSON.
#
# Replaces the separate cpu / temperature / memory pills. The bar shows only
# an icon while everything is normal; a metric past its threshold adds its
# value and sets class "warning" or "critical" (coloured in style.css).
# Hover for the full breakdown; click for btop, right-click for htop.
set -u

# Thresholds, in percent / °C.
CPU_WARN=85  CPU_CRIT=97
MEM_WARN=85  MEM_CRIT=95
TEMP_WARN=80 TEMP_CRIT=90

# The GTX 1050's PCI address. nvidia-smi would wake a runtime-suspended dGPU
# (and drain the battery), so it is only queried when the card is already up.
GPU_PCI=/sys/bus/pci/devices/0000:01:00.0

# ── CPU: usage since the previous run (waybar runs us every interval) ──────
state=${XDG_RUNTIME_DIR:-/tmp}/waybar-sysmon.cpu
read -r _ u n s i w q sq st _ < /proc/stat
busy=$((u + n + s + q + sq + st))
total=$((busy + i + w))
cpu=0
if [ -r "$state" ] && read -r pbusy ptotal < "$state" && [ "$total" -gt "$ptotal" ]; then
    cpu=$((100 * (busy - pbusy) / (total - ptotal)))
fi
echo "$busy $total" > "$state"
read -r l1 l5 l15 _ < /proc/loadavg

# ── Memory and zram swap ────────────────────────────────────────────────────
eval "$(awk '/^(MemTotal|MemAvailable|SwapTotal|SwapFree):/ {
    sub(":", "", $1); print $1 "=" $2 }' /proc/meminfo)"
mem_used=$((MemTotal - MemAvailable))
mem=$((100 * mem_used / MemTotal))
swap_used=$((SwapTotal - SwapFree))
gib() { awk -v k="$1" 'BEGIN { printf "%.1f", k / 1048576 }'; }

# ── CPU package temperature ─────────────────────────────────────────────────
# Same absolute path the old temperature module used: hwmonN numbers move
# between boots, the coretemp device path does not. temp1 = "Package id 0".
temp=0
for f in /sys/devices/platform/coretemp.0/hwmon/hwmon*/temp1_input; do
    [ -r "$f" ] && temp=$(($(cat "$f") / 1000))
done

# ── dGPU ────────────────────────────────────────────────────────────────────
gpu_line="asleep"
if [ "$(cat "$GPU_PCI/power/runtime_status" 2>/dev/null)" = active ] &&
   g=$(nvidia-smi --query-gpu=temperature.gpu,utilization.gpu,memory.used,memory.total \
           --format=csv,noheader,nounits 2>/dev/null); then
    IFS=', ' read -r gt gu gm gmt <<EOF
$g
EOF
    gpu_line="${gt}°C · ${gu}% · ${gm}/${gmt} MiB"
fi

# ── Root filesystem ─────────────────────────────────────────────────────────
read -r d_used d_size d_pct <<EOF
$(df -h --output=used,size,pcent / | tail -n 1)
EOF

# ── Severity and bar text ───────────────────────────────────────────────────
level=0   # 0 normal, 1 warning, 2 critical
text="󰻠"
check() {  # value warn crit label
    if [ "$1" -ge "$3" ]; then lv=2
    elif [ "$1" -ge "$2" ]; then lv=1
    else return; fi
    [ "$lv" -gt "$level" ] && level=$lv
    text="$text $4"
}
check "$cpu"  "$CPU_WARN"  "$CPU_CRIT"  "${cpu}%"
check "$temp" "$TEMP_WARN" "$TEMP_CRIT" "󰔏 ${temp}°"
check "$mem"  "$MEM_WARN"  "$MEM_CRIT"  "󰍛 ${mem}%"

case $level in
    0) class=normal ;;
    1) class=warning ;;
    2) class=critical ;;
esac

tip=$(printf '%s\n' \
    "CPU    ${cpu}%   load ${l1} ${l5} ${l15}" \
    "Temp   ${temp}°C" \
    "RAM    $(gib "$mem_used") / $(gib "$MemTotal") GiB  (${mem}%)" \
    "zram   $(gib "$swap_used") / $(gib "$SwapTotal") GiB" \
    "Disk   ${d_used} / ${d_size}  (${d_pct})" \
    "dGPU   ${gpu_line}" \
    "" \
    "Click: btop · right-click: htop")

jq -cn --arg t "$text" --arg tip "$tip" --arg c "$class" \
    '{text: $t, tooltip: $tip, class: $c}'
