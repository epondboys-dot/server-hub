#!/usr/bin/env bash
# tradingserver (2014 Mac mini, Ubuntu): turn itself back on when power returns after an outage.
# The Intel chipset forgets this setting at every boot, so a small boot service re-applies it.
# Run on tradingserver as epondboys (asks for your password once). Safe to rerun.
set -euo pipefail
LPC="00:1f.0"
echo "=== 1. Check the chipset (expect an Intel LPC / ISA bridge at $LPC)"
DESC="$(lspci -s "$LPC" 2>/dev/null || true)"; echo "    ${DESC:-nothing at $LPC}"
echo "$DESC" | grep -qiE "ISA bridge|LPC" || { echo "Not the expected chipset; nothing was changed."; exit 1; }

echo "=== 2. Install the boot service"
sudo tee /etc/systemd/system/power-on-after-outage.service >/dev/null <<UNIT
[Unit]
Description=Power on automatically after a power failure (Mac mini chipset AFTERG3 setting)

[Service]
Type=oneshot
ExecStart=/usr/bin/setpci -s $LPC 0xa4.b=0

[Install]
WantedBy=multi-user.target
UNIT
sudo systemctl daemon-reload
sudo systemctl enable --now power-on-after-outage.service
echo "    register 0xa4 now: $(sudo setpci -s "$LPC" 0xa4.b)  (00 = power on after outage)"

echo "=== 3. What starts by itself at boot"
loginctl show-user "$USER" -p Linger
systemctl --user is-enabled trading-desk.service trading-desk-gateway.service || true
echo "Done. After an outage: power returns -> Mac mini turns on -> desk and phone page start and resume."
