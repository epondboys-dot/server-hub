#!/usr/bin/env bash
# One-shot setup for the 2014 Mac mini (Late 2014, 1.4 GHz i5, 4 GB) as the Trading Desk's home, run once on a fresh
# Ubuntu Server 24.04 LTS install:   sudo bash setup-trading-desk-mac-mini-2014.sh
# It is safe to rerun. It does NOT clone the repo, move the desk runtime, start the desk, or set anything to start the
# desk automatically (owner decisions 5 and 10). Paper/research only.
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Run with sudo"; exit 1; }
OWNER="${SUDO_USER:-}"; [ -n "$OWNER" ] && [ "$OWNER" != root ] || { echo "Run with sudo from the owner's account, not as root"; exit 1; }
HOME_DIR="$(getent passwd "$OWNER" | cut -d: -f6)"
step() { echo; echo "==== $*"; }

step "1. Updates and base tools"
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -y full-upgrade
DEBIAN_FRONTEND=noninteractive apt-get -y install git curl ca-certificates gnupg ufw unattended-upgrades pciutils iproute2 smartmontools mbpfan htop
timedatectl set-timezone America/New_York

step "2. Automatic security updates"
dpkg-reconfigure -f noninteractive unattended-upgrades
cat > /etc/apt/apt.conf.d/20auto-upgrades <<'CONF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
CONF

step "3. Never sleep; Mac fan control"
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
systemctl enable --now mbpfan || echo "mbpfan did not start; check 'systemctl status mbpfan' (fans still run on firmware control)"

step "4. Turn back on after a power cut"
# Intel Mac minis: clearing this LPC register makes the firmware power on when AC returns. Must be reapplied each boot.
cat > /etc/systemd/system/mac-autopoweron.service <<'UNIT'
[Unit]
Description=Mac mini: power on after power loss
[Service]
Type=oneshot
ExecStart=/usr/bin/setpci -s 0:1f.0 0xa4.b=0
[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload; systemctl enable --now mac-autopoweron.service || echo "Power-on register not set; test by pulling the plug once the desk is NOT running"

step "5. Node.js 24 LTS (desk needs 24.19 or newer)"
if ! node --version 2>/dev/null | grep -q '^v24\.'; then
  curl -fsSL https://deb.nodesource.com/setup_24.x -o /tmp/nodesource_setup.sh
  bash /tmp/nodesource_setup.sh && DEBIAN_FRONTEND=noninteractive apt-get -y install nodejs
fi
node --version

step "6. Tailscale (remote access; the desk itself stays on 127.0.0.1)"
command -v tailscale >/dev/null || curl -fsSL https://tailscale.com/install.sh | sh
tailscale status >/dev/null 2>&1 || { echo "Sign in now: open the link printed below on your phone or PC."; tailscale up --ssh=false; }
tailscale ip -4 || true

step "7. Firewall: nothing comes in except SSH"
ufw --force reset >/dev/null
ufw default deny incoming; ufw default allow outgoing
ufw allow in on tailscale0 to any port 22 proto tcp comment 'SSH over Tailscale'
ufw allow from 192.168.0.0/16 to any port 22 proto tcp comment 'LAN SSH during setup - remove later'
ufw --force enable
ufw status verbose

step "8. SSH: keys only (when a key is already installed)"
if [ -s "$HOME_DIR/.ssh/authorized_keys" ]; then
  printf 'PasswordAuthentication no\nKbdInteractiveAuthentication no\nPermitRootLogin no\n' > /etc/ssh/sshd_config.d/10-keys-only.conf
  systemctl reload ssh
  echo "SSH now accepts keys only."
else
  echo "No SSH key in $HOME_DIR/.ssh/authorized_keys yet. From the Florida/PA PC run: ssh-copy-id $OWNER@<this-machine>, then rerun this script."
fi

step "9. Private desk runtime folder and WORKBENCH_RUNTIME_DIR"
RUNTIME="$HOME_DIR/trading-desk-runtime"
install -d -m 700 -o "$OWNER" -g "$OWNER" "$RUNTIME"
grep -q WORKBENCH_RUNTIME_DIR "$HOME_DIR/.profile" || echo "export WORKBENCH_RUNTIME_DIR=\"$RUNTIME\"" >> "$HOME_DIR/.profile"
echo "Runtime folder: $RUNTIME (empty until the owner moves the desk with backup-runtime.js; see linux/README.md)"

step "10. Disk health"
DISK="$(lsblk -dno NAME,TYPE | awk '$2=="disk"{print "/dev/"$1; exit}')"
smartctl -H "$DISK" || true
lsblk -dno NAME,ROTA,SIZE,MODEL | awk '{print "disk "$1": "($2=="1"?"spinning hard drive":"SSD")", "$3}'

echo; echo "Done. Next: clone the repo, move the runtime and run the doctor - see trading-bot/linux/README.md. Nothing was set to start the desk."
