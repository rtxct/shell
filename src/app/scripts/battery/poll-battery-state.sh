#!/usr/bin/env sh
# ============================================================================
# File: scripts/battery/poll-battery-state.sh
# Purpose: Queries battery status, capacity percentage, AC state, cycle count,
#          energy metrics (now, full, design), power rate, model, and technology
#          from Linux sysfs /sys/class/power_supply.
# Output Format (10 lines):
#   Line 1: Battery status (e.g. "Charging", "Discharging", "Not charging", "Full")
#   Line 2: Capacity percentage (e.g. "98")
#   Line 3: AC online flag ("1" if plugged in, "0" if running on battery)
#   Line 4: Cycle count (e.g. "231")
#   Line 5: Energy now in µWh (e.g. "32040000")
#   Line 6: Energy full in µWh (e.g. "32720000")
#   Line 7: Energy full design in µWh (e.g. "38000000")
#   Line 8: Power now in µW (e.g. "0")
#   Line 9: Model name (e.g. "L20M2PF0")
#   Line 10: Technology (e.g. "Li-poly")
# Dependencies: sh, cat
# ============================================================================
ac_online=0
for a in /sys/class/power_supply/*/online; do
    if [ -f "$a" ] && [ "$(cat "$a" 2>/dev/null)" = "1" ]; then
        ac_online=1
        break
    fi
done

bat_status="Unknown"
bat_capacity="100"
cycle_count="0"
energy_now="0"
energy_full="0"
energy_full_design="0"
power_now="0"
model_name=""
technology=""

for b in /sys/class/power_supply/BAT*; do
    if [ -d "$b" ]; then
        bat_status=$(cat "$b/status" 2>/dev/null || echo "Unknown")
        bat_capacity=$(cat "$b/capacity" 2>/dev/null || echo "100")
        cycle_count=$(cat "$b/cycle_count" 2>/dev/null || echo "0")
        energy_now=$(cat "$b/energy_now" 2>/dev/null || echo "0")
        energy_full=$(cat "$b/energy_full" 2>/dev/null || echo "0")
        energy_full_design=$(cat "$b/energy_full_design" 2>/dev/null || echo "0")
        power_now=$(cat "$b/power_now" 2>/dev/null || echo "0")
        model_name=$(cat "$b/model_name" 2>/dev/null || echo "")
        technology=$(cat "$b/technology" 2>/dev/null || echo "")
        break
    fi
done

printf "%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n" \
    "$bat_status" "$bat_capacity" "$ac_online" "$cycle_count" \
    "$energy_now" "$energy_full" "$energy_full_design" "$power_now" \
    "$model_name" "$technology"
