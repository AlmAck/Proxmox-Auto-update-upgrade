# Proxmox Multi-Distro LXC Updater

A robust Bash script designed for Proxmox VE hosts to automatically detect and update the operating systems of all running LXC containers. It supports a wide range of Linux distributions by identifying the package manager in use.

## 🚀 Features

* **Automatic OS Detection:** Identifies the container OS by checking for apk, apt, dnf, pacman, or zypper.
* **Host & Guest Updates:** Updates the Proxmox host node first, then iterates through containers.
* **Smart Skipping:** * Automatically skips containers that are powered off.
    * Supports a "Blacklist" to exclude specific Container IDs (e.g., ID 210).
* **Comprehensive Logging:** Redirects all detailed output to /var/log/lxc-update.log while providing a clean summary in the terminal.
* **Alpine Compatibility:** Uses sh execution to ensure compatibility with Alpine's busybox/ash environment.

## 📦 Supported Distributions

| Family | Package Manager | Distributions |
| :--- | :--- | :--- |
| Debian | apt | Debian, Ubuntu, Kali |
| Alpine | apk | Alpine Linux |
| RedHat | dnf | Fedora, CentOS, AlmaLinux, Rocky |
| Arch | pacman | Arch Linux |
| SUSE | zypper | openSUSE |

## 🛠️ Installation & Usage

1. Upload the script to your Proxmox host (e.g., to /usr/local/bin/update-lxc.sh).
2. Make it executable:
   chmod +x /usr/local/bin/update-lxc.sh
3. Run the script as root:
   sudo /usr/local/bin/update-lxc.sh

## ⚙️ Configuration

To exclude specific containers from the update process, modify the exclusion logic in the script:
if [ "$CTID" -eq 210 ]; then
    echo "Skipping container $CTID (excluded)."
    continue
fi

## 📄 Logging

Monitor progress or troubleshoot errors by checking the log file:
tail -f /var/log/lxc-update.log
