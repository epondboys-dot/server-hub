# PA PC worker: Jarvis runs Sixes work, backups, builds and pushes on the PA PC (v2, Nov 25, 2026)

Owner decisions: Sixes stays on the PA PC (Nov 23); agents work in its own working folder, and the PC builds and
pushes, as automated as possible, with the owner confirming builds and pushes from Discord (Nov 25).

Jarvis opens SSH to the PA PC with a key that can run **only** `jarvis-worker.ps1` (no shell, no forwarding):

| Discord | What happens on the PA PC | Confirm? |
|---|---|---|
| `plan sixes ...` / `work on the lacrosse game ...` | agent reads the working folder as it is now (uncommitted work included), replies with a plan | no (read-only) |
| `approve T#` | GitHub backup, agent edits the working folder (no shell, never .vsconfig/.slnx), GitHub backup again; reply has the diff and an undo command | the approve |
| `checkpoint sixes` (and nightly at 02:00) | backs up the whole working folder to a new GitHub branch `checkpoint/pa-<time>` without changing the folder, the index or the branch | no |
| `sixes status` | branch, ahead/behind GitHub, changed files, last backup | no |
| `build sixes` | runs `Build_DevelopmentEditor.bat` (SixesGameEditor, Win64 Development), posts success/failure and the errors | `confirm build` |
| `push sixes` | pushes the current branch, fast-forward only (never force; refuses if GitHub has newer work) | `confirm push` |

Tested on the PA PC, Nov 25: wrong commands refused; `status` and `checkpoint` work (first backup
`checkpoint/pa-20261125-141931`: 50 files, about 3,000 lines of uncommitted WO45 to WO54 work, folder and index
unchanged, no .vsconfig/.slnx); Codex reachable (usage-limited at the time). Not yet tested here: an agent edit
(Claude Code needs signing in on the PA PC) and a build through the worker.

**Rigs are out of sync:** the PA PC branch is 11 commits behind GitHub (Nov 12 to 13 commits) and has two weeks of
uncommitted work. `push sixes` will refuse until the two are reconciled; the checkpoint branches keep the PA work safe.

## Setup
1. On Jarvis (Terminal, as epondboys): make the worker key and share its public half for a minute:
   ```
   sudo -u jarvis ssh-keygen -t ed25519 -N "" -C jarvis-worker -f /Users/jarvis/.ssh/jarvis_worker_ed25519 && mkdir -p /tmp/wk && sudo cat /Users/jarvis/.ssh/jarvis_worker_ed25519.pub > /tmp/wk/jarvis_worker_ed25519.pub && cd /tmp/wk && python3 -m http.server 8999
   ```
2. On the PA PC, PowerShell **as Administrator**:
   `powershell -ExecutionPolicy Bypass -File G:\AI-Projects\server-hub\pa-pc-worker\setup-pa-pc-worker.ps1`
   Then press Ctrl+C on Jarvis. Also sign Claude Code in once on the PA PC: normal PowerShell, `claude`, `/login`,
   your Claude subscription, `/exit`.
3. Test from Jarvis: `sudo -u jarvis ssh -i /Users/jarvis/.ssh/jarvis_worker_ed25519 -o StrictHostKeyChecking=accept-new ebutc@10.10.10.87 "status T0 lax-sixes -"`
4. Give the PA PC a fixed address in UniFi (10.10.10.87). If it changes, add `PA_PC_HOST=<address>` to
   `/Users/jarvis/.jarvis-bot.env`.

Turn it off on the PA PC any time: `Stop-Service sshd; Set-Service sshd -StartupType Disabled`.
After editing `jarvis-worker.ps1`, rerun the setup script so the admin-owned copy in C:\ProgramData is updated.
