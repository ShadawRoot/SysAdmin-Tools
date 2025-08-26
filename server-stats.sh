#!/usr/bin/env bash
# server-stats.sh
# Author: Abdelilah LAMHAMDI
# Description: Basic server performance stats (CPU, memory, disk, top processes) + extras
# Usage: chmod +x server-stats.sh && ./server-stats.sh

set -euo pipefail

hr() { printf '%*s\n' "${COLUMNS:-80}" '' | tr ' ' '-'; }
title() { echo -e "\n$1"; hr; }

has_cmd() { command -v "$1" >/dev/null 2>&1; }

# ---------- CPU (total %) ----------
cpu_total_usage() {
  # Read /proc/stat twice and compute usage %
  read -r cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
  idle1=$((idle+iowait))
  nonidle1=$((user+nice+system+irq+softirq+steal))
  total1=$((idle1+nonidle1))
  sleep 1
  read -r cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
  idle2=$((idle+iowait))
  nonidle2=$((user+nice+system+irq+softirq+steal))
  total2=$((idle2+nonidle2))
  totald=$((total2-total1))
  idled=$((idle2-idle1))
  # Avoid division by zero
  if [ "$totald" -gt 0 ]; then
    awk -v totald="$totald" -v idled="$idled" 'BEGIN {printf "%.2f", (totald - idled) * 100 / totald}'
  else
    echo "0.00"
  fi
}

# ---------- Memory (Used/Free/%) ----------
mem_stats() {
  # Prefer /proc/meminfo (portable)
  total_kb=$(awk '/MemTotal:/ {print $2}' /proc/meminfo)
  avail_kb=$(awk '/MemAvailable:/ {print $2}' /proc/meminfo)
  used_kb=$((total_kb - avail_kb))
  pct=$(awk -v u="$used_kb" -v t="$total_kb" 'BEGIN {printf "%.2f", (u*100)/t}')
  # Human readable
  h() { awk -v k="$1" 'BEGIN {
      v=k*1024; s[1]="B"; s[2]="KB"; s[3]="MB"; s[4]="GB"; s[5]="TB";
      i=1; while (v>=1024 && i<5){v/=1024; i++} printf "%.2f %s", v, s[i]
  }'; }
  echo "$(h "$used_kb") used / $(h "$total_kb") total (${pct}%)"
}

# ---------- Disk (aggregate Used/Free/%) ----------
disk_stats() {
  if has_cmd df; then
    # Sum real filesystems (exclude tmpfs, devtmpfs, squashfs, overlay, ramfs)
    df -P -B1 | awk '
      NR>1 && $1 !~ /^(tmpfs|devtmpfs|squashfs|overlay|ramfs)$/ {
        total+=$2; used+=$3; avail+=$4
      }
      END {
        if (total>0) {
          pct=used*100/total
          # humanize
          hum = function(x){
            split("B KB MB GB TB PB",u," "); i=1;
            while (x>=1024 && i<6){x/=1024;i++}
            return sprintf("%.2f %s", x, u[i])
          }
          printf "%s used / %s total (%.2f%%)\n", hum(used), hum(total), pct
        } else {
          print "N/A"
        }
      }'
  else
    echo "df not found"
  fi
}

# ---------- Top processes ----------
top_cpu() {
  if has_cmd ps; then
    echo "PID   COMMAND               %CPU   %MEM"
    ps -eo pid,comm,%cpu,%mem --sort=-%cpu | awk 'NR==1{next} NR<=6 {printf "%-5s %-20s %5s %6s\n",$1,$2,$3,$4}'
  else
    echo "ps not found"
  fi
}

top_mem() {
  if has_cmd ps; then
    echo "PID   COMMAND               %MEM   %CPU"
    ps -eo pid,comm,%mem,%cpu --sort=-%mem | awk 'NR==1{next} NR<=6 {printf "%-5s %-20s %5s %6s\n",$1,$2,$3,$4}'
  else
    echo "ps not found"
  fi
}

# ---------- Stretch: OS, kernel, uptime, load, users, failed logins ----------
os_info() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "${PRETTY_NAME} (kernel $(uname -r))"
  else
    echo "$(uname -srm)"
  fi
}

uptime_human() {
  if has_cmd uptime; then
    # Prefer "uptime -p" if available
    if uptime -p >/dev/null 2>&1; then
      uptime -p | sed 's/^up //'
    else
      # Fallback rough parse
      awk '{print $1" hours (rough)"}' /proc/uptime
    fi
  else
    awk '{printf "%.2f hours\n", $1/3600}' /proc/uptime
  fi
}

load_avg() {
  awk '{printf "%s (1m)  %s (5m)  %s (15m)\n",$1,$2,$3}' /proc/loadavg
}

logged_in_users() {
  if has_cmd who; then
    count=$(who | wc -l)
    echo "$count user(s) logged in"
  else
    echo "N/A"
  fi
}

failed_logins() {
  if has_cmd lastb && [ -r /var/log/btmp ]; then
    echo "Recent failed logins (last 5):"
    lastb -n 5 2>/dev/null || echo "N/A"
  else
    echo "Failed login info: N/A (no lastb or no access to /var/log/btmp)"
  fi
}

# ---------- Print Report ----------
title "SERVER STATS - $(hostname) - $(date '+%Y-%m-%d %H:%M:%S %Z')"

title "Total CPU Usage"
echo "$(cpu_total_usage)%"

title "Total Memory Usage"
mem_stats

title "Total Disk Usage"
disk_stats

title "Top 5 Processes by CPU"
top_cpu

title "Top 5 Processes by Memory"
top_mem

title "Extra Info"
echo -n "OS: "; os_info
echo -n "Uptime: "; uptime_human
echo -n "Load Average: "; load_avg
echo -n "Users: "; logged_in_users
failed_logins
