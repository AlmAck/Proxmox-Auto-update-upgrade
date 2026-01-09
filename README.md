# Proxmox Multi-OS Updater

This script automates system updates on a **Proxmox host**, all **running LXC containers**, and all **running virtual machines (VMs)**, handling multiple Linux distributions transparently.

It is designed for homelabs and production environments where mixed guest operating systems are common.

---

## Features

- Updates the **Proxmox host** (Debian-based)
- Automatically updates **running LXC containers**
- Automatically updates **running VMs** (via QEMU Guest Agent)
- Detects the guest OS by available package manager
- Supports multiple Linux distributions
- Centralized logging
- Colorized console output
- Ability to exclude specific CTs/VMs

---

## Supported Guest Operating Systems

The script detects the OS by checking the available package manager:

| Distribution        | Package Manager | Command Used              |
|---------------------|-----------------|---------------------------|
| Alpine Linux        | `apk`           | `apk update && apk upgrade` |
| Debian / Ubuntu     | `apt-get`       | `apt-get update && dist-upgrade` |
| RHEL / CentOS / Fedora | `dnf`       | `dnf update`              |
| Arch Linux          | `pacman`        | `pacman -Syu`             |
| openSUSE            | `zypper`        | `zypper refresh && update` |

If no supported package manager is found, the update for that guest fails gracefully.

---

## Requirements

### Proxmox Host

- Proxmox VE (Debian-based)
- Root privileges
- `pct` and `qm` commands available
- Network connectivity

### Virtual Machines

- **QEMU Guest Agent must be installed and running**
- Guest must be powered on
- SSH is *not* required

### Containers

- Container must be running
- Shell (`sh`) available inside the container

---

## Configuration

### Excluding Containers or VMs

Edit the following line in the script:

```
EXCLUDE_IDS=" 210 "
```

Add one or more CTIDs / VMIDs separated by spaces:

```
EXCLUDE_IDS=" 101 210 305 "
```

These IDs will be skipped.

---

## Logging

All output is logged to:

```
/var/log/proxmox-updater.log
```

The log includes:
- Host updates
- Per-CT updates
- Per-VM updates
- Package manager output
- Errors

Console output remains concise and human-readable.

---

## How It Works

1. Updates the **Proxmox host** using `apt-get`
2. Iterates through all **running LXC containers**
   - Executes update commands directly inside the container
3. Iterates through all **running VMs**
   - Uses `qm guest exec`
   - Extracts command output from JSON
   - Writes clean logs
4. Displays success or failure per guest

---

## Usage

1. Copy the script to the Proxmox host:
   ```
   /usr/local/sbin/proxmox-updater.sh
   ```

2. Make it executable:
   ```
   chmod +x /usr/local/sbin/proxmox-updater.sh
   ```

3. Run as root:
   ```
   ./proxmox-updater.sh
   ```

---

## Automation (Optional)

You can schedule the script via cron:

```
0 3 * * 0 /usr/local/sbin/proxmox-updater.sh
```

Runs every Sunday at 03:00.

---

## Safety Notes

- Updates are **non-interactive**
- Reboots are **not triggered automatically**
- Always test in staging before production use
- Consider snapshotting critical VMs before running

---

## License

MIT License

Use at your own risk.
