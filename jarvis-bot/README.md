# Jarvis Discord bot (Brain Phase 1, read-only)

Jarvis's private phone channel. Written November 20, 2026. It runs on the Mac mini `jarvis` as the standard user `jarvis`, starts at boot, and:

- answers **only the owner accounts** listed in `OWNER_DISCORD_ID` (BDev and epondboys, comma-separated); everyone else, and every other bot, is ignored
- `status`: uptime, disk, local AI (Ollama) health and models, whether `tradingserver` answers over Tailscale
- `briefing`: the "Needs you" list from a daily briefing file, if one is set
- anything else: asks the local model (`qwen3:30b` by default); nothing leaves the hub except the reply to you
- posts a morning summary at 07:30
- **cannot act**: no commands on request, no file changes, no sending elsewhere, no trading, no credential files except its own config

The code lives in `/opt/jarvis-bot`, owned by root, so the bot can't rewrite itself. The token lives only in `/Users/jarvis/.jarvis-bot.env` (owner `jarvis`, mode 600). Never in this repo, a note, a photo or a chat.

## 1. Discord (only you can do this part)

1. Go to <https://discord.com/developers/applications> → **New Application** → name it `Jarvis`.
2. **Bot** tab:
   - **Reset Token** → **Copy**. Keep it on your clipboard only until step 4; don't paste it anywhere else.
   - Turn **Public Bot** OFF.
   - Turn **Message Content Intent** ON. Save.
3. **OAuth2 → URL Generator**: scope **bot**; permissions **View Channels**, **Send Messages**, **Read Message History**. Open the URL and add Jarvis to **your private server** (make one just for you if needed, with a `#jarvis` channel).
4. In Discord: **Settings → Advanced → Developer Mode** ON. Right-click your own name → **Copy User ID**. Optionally right-click `#jarvis` → **Copy Channel ID**.

## 2. Install on Jarvis (admin account `epondboys`)

Copy this folder to Jarvis first. From the PA PC in PowerShell (asks for Jarvis's admin password):

```
scp -r G:\AI-Projects\server-hub\jarvis-bot epondboys@jarvis:~/
```

(Use Jarvis's IP instead of `jarvis` if the name doesn't resolve.) Then on Jarvis in Terminal:

```
sudo bash ~/jarvis-bot/install.sh
sudo nano /Users/jarvis/.jarvis-bot.env
```

In nano, fill in `DISCORD_BOT_TOKEN`, `OWNER_DISCORD_ID` and (optional) `JARVIS_CHANNEL_ID`. Save with Ctrl+O, Enter, then exit with Ctrl+X. Then start it:

```
sudo bash ~/jarvis-bot/install.sh
```

Jarvis posts "Jarvis is online" in your channel or DMs. Type `help`.

## Day to day

- Log: `sudo tail -n 50 /Users/jarvis/Library/Logs/jarvis-bot.log`
- Stop: `sudo launchctl bootout system/com.pondboys.jarvis-bot`
- Start or update after changes: `sudo bash ~/jarvis-bot/install.sh`
- New token (if it ever leaks): Developer Portal → Bot → Reset Token, put the new one in the env file, rerun the installer.

## Needs

- Ollama running (it runs in the admin account's login session; after a reboot, log in to `epondboys` once to unlock FileVault and start it).
- Node 24 at `/opt/homebrew/opt/node@24`.
- `jarvis` must stay a **Standard** account; the installer refuses to run if it's an admin.

## Later phases (not in this bot)

Gmail/Drive (Jarvis's own Google account, read-only and drafts only), iMessage (Jarvis's own Apple Account), dispatching work to project agents with tap-to-approve. See `../BRAIN_PLAN.md`.

## Agent tasks (added November 23, 2026)

Owners can ask Claude Code (your Claude subscription) or Codex (your ChatGPT subscription) to work on a project, with your approval in between. Claude Code is the default; add `--codex` to `plan` to use Codex (it runs in its own read-only or workspace-only sandbox with no network). Codex uses the ChatGPT sign-in saved in the jarvis account, so it needs no token:

- `plan <trading|retro|crease> <what you want>`: read-only (Read/Glob/Grep only). Replies with a plan and an id like `T1`.
- `approve T1`: carries out that plan in a separate copy, `/Users/jarvis/work/T1`, on branch `jarvis/T1`. It may edit, run tests and commit there. `git push` is blocked, and the GitHub token is read-only anyway.
- `tasks`, `cancel T1`, `discard T1`.

You review and push from a PC (the reply prints the exact commands):

    git fetch epondboys@10.10.10.240:/Users/jarvis/work/T1 jarvis/T1:jarvis/T1

One-time setup:

1. As the jarvis user at the Mac (not through sudo): `claude setup-token`, then `nano ~/.jarvis-bot.env` and paste it after `CLAUDE_CODE_OAUTH_TOKEN=`.
2. On Jarvis as epondboys, so PCs can fetch task branches from jarvis's folder: `git config --global --add safe.directory '*'`.
3. Rerun `sudo bash ~/jarvis-bot/install.sh`.

Tasks use your Claude plan's usage limits. One task runs at a time; planning times out after 10 minutes, approved work after 30.
