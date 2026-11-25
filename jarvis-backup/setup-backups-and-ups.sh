#!/usr/bin/env bash
# Jarvis: Time Machine to the Seagate 8 TB, and safe shutdown on the CyberPower UPS (USB to Jarvis).
# Run on Jarvis as epondboys AFTER the drive is set up (see README.md here):   bash ~/jarvis-backup/setup-backups-and-ups.sh
# Safe to rerun. Erases nothing: it refuses unless a Time Machine volume named JarvisTM is already mounted.
set -euo pipefail
TM_VOL="/Volumes/JarvisTM"

echo "=== 1. Backup drive"
[ -d "$TM_VOL" ] || { echo "No $TM_VOL. Set the drive up first (README.md step 2), then rerun."; exit 1; }
diskutil info "$TM_VOL" | grep -E "File System Personality|Volume Name|Disk Size" || true

echo "=== 2. Time Machine (one sudo)"
sudo tmutil setdestination -a "$TM_VOL"
# Re-downloadable or bulky: Ollama models (~20 GB, pull again with ollama) and agent scratch worktrees.
for p in /Users/Shared/ollama/models /Users/jarvis/work; do [ -e "$p" ] && sudo tmutil addexclusion -p "$p" && echo "    excluded $p"; done
sudo tmutil enable
tmutil destinationinfo
sudo tmutil startbackup --auto && echo "    first backup started (it runs in the background; the first one takes a while)"

echo "=== 3. UPS (CyberPower over USB)"
if pmset -g ps | grep -qi "UPS"; then
  pmset -g ps
  # On UPS battery: shut Jarvis down cleanly when the UPS reports 30% left or 8 minutes left, whichever comes first.
  sudo pmset -u haltlevel 30 haltremain 8 haltafter 0
  echo "    shutdown on UPS: at 30% or 8 minutes left"
else
  echo "    macOS does not see the UPS yet. Check the USB cable from the UPS to Jarvis, then rerun."
fi
# Come back on when power returns. NOTE: FileVault still asks for the password at the login screen before Jarvis starts.
sudo pmset -a autorestart 1
pmset -g | grep -E "autorestart|haltlevel|haltremain" || true

echo
echo "Done. Check anytime:  tmutil latestbackup   |   pmset -g ps   |   pmset -g"
