# One-time setup on the PA PC so Jarvis can send Sixes tasks here. Run in an ADMIN PowerShell:
#   powershell -ExecutionPolicy Bypass -File G:\AI-Projects\server-hub\pa-pc-worker\setup-pa-pc-worker.ps1
# Before running: on Jarvis, make the worker key and share its PUBLIC half for a minute (README.md step 1).
# What it does:
#  1. installs and starts the Windows OpenSSH server (starts at boot)
#  2. allows SSH in from Jarvis's address only (10.10.10.240), nothing else
#  3. copies the worker script to C:\ProgramData\jarvis-worker (admin-owned, so agents can't change it)
#  4. adds Jarvis's key with a forced command: that key can run only the worker, no shell, no forwarding
# Safe to rerun.
param([string]$JarvisIp = '10.10.10.240', [string]$KeyUrl = 'http://10.10.10.240:8999/jarvis_worker_ed25519.pub')
$ErrorActionPreference = 'Stop'
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) { throw 'Run this in an Administrator PowerShell.' }

Write-Host '=== 1. OpenSSH server'
$cap = Get-WindowsCapability -Online -Name 'OpenSSH.Server*' | Select-Object -First 1
if ($cap.State -ne 'Installed') { Add-WindowsCapability -Online -Name $cap.Name | Out-Null }
Set-Service sshd -StartupType Automatic; Start-Service sshd
Write-Host "    sshd: $((Get-Service sshd).Status)"

Write-Host "=== 2. Firewall: SSH only from Jarvis ($JarvisIp)"
Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue | Disable-NetFirewallRule
Get-NetFirewallRule -Name 'Jarvis-Worker-SSH' -ErrorAction SilentlyContinue | Remove-NetFirewallRule
New-NetFirewallRule -Name 'Jarvis-Worker-SSH' -DisplayName 'SSH from Jarvis only (worker)' -Direction Inbound -Protocol TCP -LocalPort 22 -RemoteAddress $JarvisIp -Action Allow -Profile Any | Out-Null

Write-Host '=== 3. Worker script (admin-owned copy)'
$dir = 'C:\ProgramData\jarvis-worker'
New-Item -ItemType Directory -Force $dir | Out-Null
Copy-Item (Join-Path $PSScriptRoot 'jarvis-worker.ps1') (Join-Path $dir 'jarvis-worker.ps1') -Force
icacls $dir /inheritance:r /grant 'Administrators:(OI)(CI)F' 'SYSTEM:(OI)(CI)F' "${env:USERNAME}:(OI)(CI)RX" | Out-Null

Write-Host '=== 4. Jarvis key with a forced command'
$pub = (Invoke-WebRequest -UseBasicParsing $KeyUrl -TimeoutSec 20).Content.Trim()
if ($pub -notmatch '^ssh-ed25519 [A-Za-z0-9+/=]+( .*)?$') { throw "That doesn't look like an ed25519 public key: $pub" }
$force = "command=`"powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $dir\jarvis-worker.ps1`",no-port-forwarding,no-agent-forwarding,no-X11-forwarding,no-pty"
$auth = 'C:\ProgramData\ssh\administrators_authorized_keys'
$keep = if (Test-Path $auth) { Get-Content $auth | Where-Object { $_ -notmatch 'jarvis-worker' } } else { @() }
Set-Content -Path $auth -Value (@($keep) + "$force $pub") -Encoding ascii
icacls $auth /inheritance:r /grant 'Administrators:F' 'SYSTEM:F' | Out-Null
Restart-Service sshd
Write-Host "    key added for $((($pub -split ' ')[2]))"
Write-Host ''
Write-Host 'Done. Test from Jarvis (README.md step 3). Turn it off any time: Stop-Service sshd; Set-Service sshd -StartupType Disabled'
