#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root."
  exit 1
fi

LOGFILE="/var/log/lxc-update.log"

echo "Starting updates: $(date)" >> "$LOGFILE"
echo "------------------------------------------" >> "$LOGFILE"

# Step 1: Update the Proxmox node (Host is always Debian-based)
echo "Updating Proxmox node..." | tee -a "$LOGFILE"
apt update && apt upgrade -y >> "$LOGFILE" 2>&1

# Step 2: Get a list of all LXC container IDs
CONTAINERS=$(pct list | awk 'NR>1 {print $1}')

for CTID in $CONTAINERS; do
    # Exclude specific container IDs
    if [ "$CTID" -eq 210 ]; then
        echo "Skipping container $CTID (excluded)." | tee -a "$LOGFILE"
        continue
    fi

    if pct status "$CTID" | grep -q "status: running"; then
        echo "Updating container ID: $CTID" | tee -a "$LOGFILE"

        # Auto-detect OS and run the appropriate update command
        # We use a subshell via pct exec to check for the package manager
        pct exec "$CTID" -- sh -c '
            if command -v apk >/dev/null 2>&1; then
                echo "OS: Alpine Linux"
                apk update && apk upgrade
            elif command -v apt-get >/dev/null 2>&1; then
                echo "OS: Debian/Ubuntu"
                export DEBIAN_FRONTEND=noninteractive
                apt-get update && apt-get dist-upgrade -y
            elif command -v dnf >/dev/null 2>&1; then
                echo "OS: RHEL/CentOS/Fedora"
                dnf update -y
            elif command -v pacman >/dev/null 2>&1; then
                echo "OS: Arch Linux"
                pacman -Syu --noconfirm
            elif command -v zypper >/dev/null 2>&1; then
                echo "OS: openSUSE"
                zypper refresh && zypper update -y
            else
                echo "Unknown OS: Could not find a supported package manager."
                exit 1
            fi
        ' >> "$LOGFILE" 2>&1

        if [ $? -eq 0 ]; then
            echo "Container $CTID: Success" | tee -a "$LOGFILE"
        else
            echo "Container $CTID: Failed (Check $LOGFILE for details)" | tee -a "$LOGFILE"
        fi
    else
        echo "Container $CTID is not running. Skipping." | tee -a "$LOGFILE"
    fi
    echo "------------------------------------------" | tee -a "$LOGFILE"
done

echo "All updates completed: $(date)" >> "$LOGFILE"
