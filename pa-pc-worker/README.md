# PA PC worker: Jarvis sends Sixes tasks to the PA PC (Nov 25, 2026)

Sixes stays on the PA PC (owner, Nov 23). In Discord, `plan sixes ...` or `work on the lacrosse game ...` makes
Jarvis open an SSH connection to the PA PC with a key that can run **only** `jarvis-worker.ps1`. The worker:
- `plan`: reads a throwaway copy of the latest GitHub version of the branch you are on, and replies with a plan.
- `do` (after `approve T#`): works in `G:\AI-Projects\_jarvis-work\T#` on branch `jarvis/T#`, commits there, replies
  with the summary and the commits. It never pushes, never touches your own working folder and its edits, and never
  runs builds, the Unreal editor, UAT/UBT or cooking. Builds stay yours, after review.
- `discard`: removes that copy and branch.
SSH is allowed in from Jarvis's address only. Tested locally on Nov 25: wrong commands refused; plan and discard
work; Codex answered (it was at its usage limit, which Jarvis detects and switches agents for).

## 1. On Jarvis (Terminal, as epondboys): make the worker key and share its public half for a minute
```
sudo -u jarvis ssh-keygen -t ed25519 -N "" -C jarvis-worker -f /Users/jarvis/.ssh/jarvis_worker_ed25519 && mkdir -p /tmp/wk && sudo cat /Users/jarvis/.ssh/jarvis_worker_ed25519.pub > /tmp/wk/jarvis_worker_ed25519.pub && cd /tmp/wk && python3 -m http.server 8999
```
Leave it running for step 2, then Ctrl+C. (Only the public key is shared; the private key never leaves Jarvis.)

## 2. On the PA PC (PowerShell **as Administrator**)
```
powershell -ExecutionPolicy Bypass -File G:\AI-Projects\server-hub\pa-pc-worker\setup-pa-pc-worker.ps1
```
Also on the PA PC, sign Claude Code in once so the worker can use it: open a normal PowerShell, run `claude`,
type `/login`, choose your Claude subscription, then `/exit`.

## 3. Test from Jarvis
```
sudo -u jarvis ssh -i /Users/jarvis/.ssh/jarvis_worker_ed25519 -o StrictHostKeyChecking=accept-new ebutc@10.10.10.87 "discard T0 lax-sixes -"
```
Expect `Discarded T0 on the PA PC.` Then in Discord: `plan sixes summarize the open work order in two lines`.

## Notes
- Give the PA PC a fixed address in UniFi (10.10.10.87) so Jarvis always finds it. If it changes, add
  `PA_PC_HOST=<new address>` to `/Users/jarvis/.jarvis-bot.env`.
- Turn it off any time on the PA PC: `Stop-Service sshd; Set-Service sshd -StartupType Disabled`.
- Claude Code on Windows has no Bash tool here; the worker commits the agent's edits itself.
