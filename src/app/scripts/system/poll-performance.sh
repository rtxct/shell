#!/usr/bin/env sh
# ============================================================================
# File: scripts/system/poll-performance.sh
# Purpose: Collects live GPU, CPU (aggregate + per-core), and Memory breakdown
#          usage, frequency, and temperature metrics for the TopRightBar
#          Caelestia + btop performance panel.
# Output Format:
#   CPU <user> <nice> <system> <idle> <iowait> <irq> <softirq> <steal>
#   CORE <idx> <user> <nice> <system> <idle> <iowait> <irq> <softirq> <steal> <freq_khz>
#   CPU_INFO <freq_khz> <max_khz> <load1> <load5> <load15> <procs>|<model_name>
#   CPU_TEMP <celsius>
#   GPU <NVIDIA|GENERIC|INTEL|NONE> ...
#   GPU_NAME <model_name>
#   MEM <total_kib> <avail_kib> <free_kib> <cached_kib> <buffers_kib> <swap_total_kib> <swap_free_kib>
#   MEM_TEMP <celsius>
# ============================================================================

# 1. Aggregate CPU & per-core stat counters from /proc/stat + per-core cpufreq
awk '
    /^cpu / {
        printf "CPU %s %s %s %s %s %s %s %s\n", $2, $3, $4, $5, $6, $7, $8, $9
    }
    /^cpu[0-9]+ / {
        idx = substr($1, 4)
        freq_file = "/sys/devices/system/cpu/cpu" idx "/cpufreq/scaling_cur_freq"
        freq = 0
        if ((getline f < freq_file) > 0) {
            freq = f + 0
        }
        close(freq_file)
        printf "CORE %s %s %s %s %s %s %s %s %s %d\n", idx, $2, $3, $4, $5, $6, $7, $8, $9, freq
    }
' /proc/stat 2>/dev/null

# 1b. CPU model, average/max frequency, and loadavg
cpu_model=$(awk -F': ' '/^model name/ {print $2; exit}' /proc/cpuinfo 2>/dev/null)
cpu_cur_khz=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null)
cpu_max_khz=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 2>/dev/null)
load_line=$(awk '{printf "%s %s %s %s", $1, $2, $3, $4}' /proc/loadavg 2>/dev/null)
echo "CPU_INFO ${cpu_cur_khz:-0} ${cpu_max_khz:-0} ${load_line:-0 0 0 0/0}|${cpu_model:-CPU}"

# 2. CPU temperature (°C) from hwmon (coretemp / k10temp / zenpower / cpu_thermal) or thermal_zone
cpu_temp=""
for h in /sys/class/hwmon/hwmon*; do
    [ -f "$h/name" ] || continue
    name=$(cat "$h/name" 2>/dev/null)
    case "$name" in
        coretemp|k10temp|zenpower|cpu_thermal|acpitz)
            if [ -f "$h/temp1_input" ]; then
                val=$(cat "$h/temp1_input" 2>/dev/null)
                if [ -n "$val" ] && [ "$val" -gt 0 ] 2>/dev/null; then
                    cpu_temp=$(awk "BEGIN {printf \"%.1f\", $val / 1000}")
                    [ "$name" != "acpitz" ] && break
                fi
            fi
            ;;
    esac
done

if [ -z "$cpu_temp" ]; then
    for tz in /sys/class/thermal/thermal_zone*; do
        [ -f "$tz/type" ] && [ -f "$tz/temp" ] || continue
        tname=$(cat "$tz/type" 2>/dev/null)
        case "$tname" in
            x86_pkg_temp|TCPU|cpu*)
                val=$(cat "$tz/temp" 2>/dev/null)
                if [ -n "$val" ] && [ "$val" -gt 0 ] 2>/dev/null; then
                    cpu_temp=$(awk "BEGIN {printf \"%.1f\", $val / 1000}")
                    break
                fi
                ;;
        esac
    done
fi
cpu_temp="${cpu_temp:-0}"
echo "CPU_TEMP $cpu_temp"

# 3. GPU usage, clocks, & temperature (NVIDIA, AMD/DRM gpu_busy_percent, Intel i915/xe RC6 + RPS)
gpu_printed=0
if [ -d /sys/module/nvidia ] && command -v nvidia-smi >/dev/null 2>&1; then
    nv_out=$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,clocks.current.graphics,clocks.max.graphics,name --format=csv,noheader,nounits 2>/dev/null | head -n 1)
    if [ -n "$nv_out" ]; then
        nv_usage=$(echo "$nv_out" | awk -F',' '{gsub(/ /,"",$1); print $1}')
        nv_temp=$(echo "$nv_out" | awk -F',' '{gsub(/ /,"",$2); print $2}')
        nv_cur=$(echo "$nv_out" | awk -F',' '{gsub(/ /,"",$3); print $3}')
        nv_max=$(echo "$nv_out" | awk -F',' '{gsub(/ /,"",$4); print $4}')
        nv_name=$(echo "$nv_out" | awk -F',' '{sub(/^ +/,"",$5); print $5}')
        echo "GPU NVIDIA ${nv_usage:-0} ${nv_temp:-$cpu_temp} ${nv_cur:-0} ${nv_max:-1000}"
        echo "GPU_NAME ${nv_name:-NVIDIA GPU}"
        gpu_printed=1
    fi
fi

if [ "$gpu_printed" -eq 0 ]; then
    for busy_file in /sys/class/drm/card*/device/gpu_busy_percent; do
        if [ -f "$busy_file" ]; then
            busy_val=$(cat "$busy_file" 2>/dev/null | head -n 1)
            gpu_temp=""
            for gh in "${busy_file%/gpu_busy_percent}"/hwmon/hwmon*/temp1_input; do
                if [ -f "$gh" ]; then
                    gval=$(cat "$gh" 2>/dev/null)
                    if [ -n "$gval" ] && [ "$gval" -gt 0 ] 2>/dev/null; then
                        gpu_temp=$(awk "BEGIN {printf \"%.1f\", $gval / 1000}")
                        break
                    fi
                fi
            done
            echo "GPU GENERIC ${busy_val:-0} ${gpu_temp:-$cpu_temp} 0 1000"
            gpu_printed=1
            break
        fi
    done
fi

if [ "$gpu_printed" -eq 0 ]; then
    for rc6_file in /sys/class/drm/card*/gt/gt0/rc6_residency_ms; do
        if [ -f "$rc6_file" ]; then
            gt_dir="${rc6_file%/rc6_residency_ms}"
            rc6_ms=$(cat "$rc6_file" 2>/dev/null | head -n 1)
            up_ms=$(awk '{printf "%.0f", $1 * 1000}' /proc/uptime 2>/dev/null)
            act_freq=$(cat "$gt_dir/rps_act_freq_mhz" 2>/dev/null | head -n 1)
            cur_freq=$(cat "$gt_dir/rps_cur_freq_mhz" 2>/dev/null | head -n 1)
            max_freq=$(cat "$gt_dir/rps_max_freq_mhz" 2>/dev/null | head -n 1)
            min_freq=$(cat "$gt_dir/rps_min_freq_mhz" 2>/dev/null | head -n 1)
            igpu_temp=""
            for tz in /sys/class/thermal/thermal_zone*; do
                [ -f "$tz/type" ] && [ -f "$tz/temp" ] || continue
                tname=$(cat "$tz/type" 2>/dev/null)
                if [ "$tname" = "TCPU_PCI" ] || [ "$tname" = "x86_pkg_temp" ]; then
                    val=$(cat "$tz/temp" 2>/dev/null)
                    if [ -n "$val" ] && [ "$val" -gt 0 ] 2>/dev/null; then
                        igpu_temp=$(awk "BEGIN {printf \"%.1f\", $val / 1000}")
                        break
                    fi
                fi
            done
            echo "GPU INTEL ${rc6_ms:-0} ${up_ms:-0} ${act_freq:-0} ${max_freq:-1000} ${igpu_temp:-$cpu_temp} ${cur_freq:-0} ${min_freq:-100}"
            gpu_printed=1
            break
        fi
    done
fi

if [ "$gpu_printed" -eq 0 ]; then
    echo "GPU NONE 0 $cpu_temp 0 1000"
fi

if command -v lspci >/dev/null 2>&1; then
    gname=$(lspci 2>/dev/null | awk -F': ' '/VGA compatible controller|3D controller|Display controller/ {print $2; exit}')
    [ -n "$gname" ] && echo "GPU_NAME $gname"
fi

# 4. Memory breakdown from /proc/meminfo
awk '
    /^MemTotal:/     { total = $2 }
    /^MemAvailable:/ { avail = $2 }
    /^MemFree:/      { free = $2 }
    /^Cached:/       { cached = $2 }
    /^Buffers:/      { buffers = $2 }
    /^SwapTotal:/    { swaptotal = $2 }
    /^SwapFree:/     { swapfree = $2 }
    END {
        printf "MEM %d %d %d %d %d %d %d\n", total, avail, free, cached, buffers, swaptotal, swapfree
    }
' /proc/meminfo 2>/dev/null

# 5. Memory / system board temperature (°C) from SPD/JC42/NVMe/thermal_zone
mem_temp=""
for h in /sys/class/hwmon/hwmon*; do
    [ -f "$h/name" ] || continue
    name=$(cat "$h/name" 2>/dev/null)
    case "$name" in
        spd5118|jc42|dimm|nvme)
            if [ -f "$h/temp1_input" ]; then
                val=$(cat "$h/temp1_input" 2>/dev/null)
                if [ -n "$val" ] && [ "$val" -gt 0 ] 2>/dev/null; then
                    mem_temp=$(awk "BEGIN {printf \"%.1f\", $val / 1000}")
                    break
                fi
            fi
            ;;
    esac
done

if [ -z "$mem_temp" ]; then
    for tz in /sys/class/thermal/thermal_zone*; do
        [ -f "$tz/type" ] && [ -f "$tz/temp" ] || continue
        tname=$(cat "$tz/type" 2>/dev/null)
        case "$tname" in
            SEN1|acpitz)
                val=$(cat "$tz/temp" 2>/dev/null)
                if [ -n "$val" ] && [ "$val" -gt 0 ] 2>/dev/null; then
                    mem_temp=$(awk "BEGIN {printf \"%.1f\", $val / 1000}")
                    break
                fi
                ;;
        esac
    done
fi
echo "MEM_TEMP ${mem_temp:-$cpu_temp}"
