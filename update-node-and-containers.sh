#!/bin/bash

# --- Colors ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

LOGFILE="/var/log/proxmox-updater.log"
EXCLUDE_IDS=" 210 "

echo -e "${BLUE}Starting Proxmox Multi-OS Update...${NC}"
echo "Started: $(date)" >> "$LOGFILE"

# Update Host
echo -e "${YELLOW}[HOST]${NC} Updating..."
apt-get update && apt-get dist-upgrade -y >> "$LOGFILE" 2>&1

# Update LXCs (Direct Output)
for CTID in $(pct list | awk 'NR>1 {print $1}'); do
    [[ " $EXCLUDE_IDS " =~ " $CTID " ]] && continue
    if pct status "$CTID" | grep -q "status: running"; then
        echo -n -e "${YELLOW}[LXC $CTID]${NC} Updating... "
        echo "Updating [LXC $CTID]" >> "$LOGFILE"
        pct exec "$CTID" -- sh -c '
            if command -v apk >/dev/null; then apk update && apk upgrade;
            elif command -v apt-get >/dev/null; then apt-get update && apt-get dist-upgrade -y;
            else exit 1; fi' >> "$LOGFILE" 2>&1
        [ $? -eq 0 ] && echo -e "${GREEN}DONE${NC}" || echo -e "${RED}FAILED${NC}"
    fi
done

# Update VMs (Cleanup JSON Output)
for VMID in $(qm list | awk 'NR>1 {print $1}'); do
    [[ " $EXCLUDE_IDS " =~ " $VMID " ]] && continue
    if qm status "$VMID" | grep -q "status: running" && qm agent "$VMID" ping >/dev/null 2>&1; then
        echo -n -e "${BLUE}[VM $VMID]${NC} Updating... "
        echo "Updating [VM $VMID]" >> "$LOGFILE"
        
        # Capture JSON output and clean it for the log
        RAW_JSON=$(qm guest exec "$VMID" -- sh -c '
            if command -v apk >/dev/null; then apk update && apk upgrade;
            elif command -v apt-get >/dev/null; then apt-get update && apt-get dist-upgrade -y;
            else exit 1; fi' 2>&1)
        
        # EXTRACT text from JSON and convert \n to real newlines for the log
        echo "$RAW_JSON" | sed -n 's/.*"out-data" : "\(.*\)",/\1/p' | sed 's/\\n/\n/g' >> "$LOGFILE"
        
        if echo "$RAW_JSON" | grep -q '"exitcode" : 0'; then
            echo -e "${GREEN}DONE${NC}"
        else
            echo -e "${RED}FAILED${NC}"
        fi
    fi
done
