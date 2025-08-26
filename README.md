# SysAdmin-Tools
A collection of Linux Bash scripts for automation, system administration, and DevOps labs.
# 🐧 Linux Bash Scripts Collection

A collection of **Linux Bash scripts** for system administration, automation, and DevOps labs.  
Maintained by **Abdelilah LAMHAMDI**.

---

## 📌 Project Overview
This repository contains practical scripts that can be used on any Linux server to analyze and manage system resources.  
The goal is to provide **ready-to-use**, **well-documented**, and **portable** scripts.

---

## 🚀 Scripts Available

### 1. `server-stats.sh`
🔎 A script to analyze **basic server performance stats**.

**Features:**
- ✅ Total CPU usage (percentage)
- ✅ Total memory usage (used vs free, percentage)
- ✅ Total disk usage (used vs free, percentage)
- ✅ Top 5 processes by CPU usage
- ✅ Top 5 processes by memory usage  
- 🎯 *Stretch goals*: OS version, uptime, load average, logged-in users, failed login attempts

**Usage:**
```bash
chmod +x server-stats.sh
./server-stats.sh
