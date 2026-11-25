# UPS and backups (Nov 25, 2026)

Hardware: CyberPower CP1500PFCLCD (1500 VA / 1000 W, pure sine wave) and a Seagate 8 TB Expansion desktop drive.

## 1. Plug in (during the planned power-down)
- **Battery outlets on the UPS:** Jarvis, tradingserver, the UniFi gateway, the hub-room switch, and the PA PC.
  Together they draw about 150–350 W, so the battery covers short outages and gives Jarvis time to shut down.
- **Surge-only outlets:** the monitors, the TV and the Seagate drive's power brick.
- **UPS USB cable → Jarvis** (only one machine can read the UPS; Jarvis is the one that shuts itself down).
- **Seagate USB → Jarvis.**
- The Xfinity gateway is upstairs and not on this UPS, so an outage also drops the internet; the desk keeps its saved
  state and resumes when power and internet return (owner decision 13).

## 2. Set up the drive (on Jarvis, at the screen, once)
This erases the new drive.
1. Disk Utility → View → Show All Devices → select the **Seagate** disk (top level) → Erase:
   name `JarvisTM`, format **APFS**, scheme **GUID Partition Map**.
2. With `JarvisTM` selected, click **+** (Add APFS Volume): name `HubData`, format APFS. This shares the drive's space
   and later holds tradingserver's nightly desk backups.
3. If macOS asks "Use for Time Machine?", choose **Decide later**; the script sets it.

## 3. Run the script (on Jarvis, Terminal, as epondboys)
```
sudo -u jarvis -H git clone -q https://github.com/epondboys-dot/server-hub.git /tmp/sh-backup && cp -R /tmp/sh-backup/jarvis-backup ~/ && bash ~/jarvis-backup/setup-backups-and-ups.sh
```

## Known gaps
- **FileVault:** after a power cut Jarvis turns itself back on but waits at the FileVault password, so Jarvis (Discord
  bot, Ollama) stays off until someone types it. Owner decision to make: keep FileVault (safer if the Mac is stolen) or
  turn it off for unattended recovery.
- **tradingserver** cannot read the UPS. It loses power when the battery runs out and resumes on its own when power is
  back, if its firmware is set to power on after a power loss (step below, optional).
- **Desk runtime backups** need a live-safe backup in the desk code (today's tool needs the desk stopped). That is a
  Jarvis task: `plan trading add a live-safe nightly runtime backup ...`.

## Optional: tradingserver powers on after a power cut (2014 Mac mini on Linux)
On tradingserver: `sudo setpci -s 0:1f.0 0xa4.b=0` sets the Intel chipset to boot when power returns. It resets at
every boot, so it needs a small boot service; ask Claude to add it once the restart is done.
