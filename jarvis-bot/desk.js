// Jarvis: Trading Desk status and owner-approved start (owner decision 12, November 23, 2026).
//   desk status        read-only, any time
//   start desk         asks for confirmation; nothing runs yet
//   confirm start      within 5 minutes, by the same owner: starts the desk the normal way
// The SSH key can only run 'status' or 'start' on tradingserver (forced command there), so even a bug here
// cannot reset, enable entries, change limits or clear hard-off. The desk always comes up Stopped.
'use strict';
const os = require('os');
const path = require('path');
const { execFile } = require('child_process');

const KEY = path.join(os.homedir(), '.ssh', 'jarvis_desk_ed25519');
const WINDOW_MS = 5 * 60 * 1000;
let pending = null; // { by, at }

function remote(cfg, command, timeoutMs) {
  const host = cfg.DESK_SSH_HOST || '100.111.197.47';
  return new Promise(resolve => execFile('/usr/bin/ssh',
    ['-i', KEY, '-o', 'BatchMode=yes', '-o', 'IdentitiesOnly=yes', '-o', 'ConnectTimeout=10', `epondboys@${host}`, command],
    { timeout: timeoutMs, maxBuffer: 1 << 20 },
    (error, stdout, stderr) => resolve({ ok: !error, code: error && error.code, out: String(stdout || '').trim(), err: String(stderr || '').trim() })));
}

function summarize(text) {
  try {
    const j = JSON.parse(text.slice(text.indexOf('{')));
    const d = j.desk || j;
    const bits = [];
    if ('running' in j) bits.push(j.running ? 'desk running' : 'desk not running');
    if (d.mode) bits.push(`mode ${d.mode}`);
    if ('stopped' in d) bits.push(d.stopped ? 'Stopped' : 'active');
    if ('entriesEnabled' in d) bits.push(d.entriesEnabled ? 'entries ENABLED' : 'entries disabled');
    if (d.startupFreeze) bits.push('frozen for review');
    if (bits.length) return bits.join(' · ');
  } catch {}
  const lines = text.split('\n').filter(Boolean);
  return lines.slice(-12).join('\n').slice(0, 1500);
}

const isDeskCommand = t => /^(desk status|start desk|confirm start|cancel start)$/i.test(t.trim());

async function handle(text, author, cfg, reply) {
  const cmd = text.trim().toLowerCase();
  if (cmd === 'desk status') {
    const r = await remote(cfg, 'status', 30000);
    return reply(r.ok ? `**Trading Desk:** ${summarize(r.out)}` : `Could not reach the desk: ${(r.err || r.out || 'no answer').slice(-300)}`);
  }
  if (cmd === 'start desk') {
    pending = { by: author, at: Date.now() };
    return reply('**Start the Trading Desk on tradingserver?** It comes up **Stopped**, entries disabled; you reset it yourself on the desk page. ' +
      'Refused if hard-off is latched or a desk is already running.\nType `confirm start` within 5 minutes, or `cancel start`.');
  }
  if (cmd === 'cancel start') { pending = null; return reply('Start cancelled.'); }
  if (cmd === 'confirm start') {
    if (!pending || Date.now() - pending.at > WINDOW_MS) { pending = null; return reply('Nothing to confirm. Type `start desk` first.'); }
    if (pending.by !== author) return reply('Only the owner who asked can confirm this start.');
    pending = null;
    await reply('Starting the desk on tradingserver…');
    const r = await remote(cfg, 'start', 180000);
    const out = (r.out + (r.err ? '\n' + r.err : '')).trim();
    if (r.ok) return reply(`**Desk started.** It is Stopped until you reset it on the desk page.\n\`\`\`\n${out.split('\n').slice(-6).join('\n').slice(0, 900)}\n\`\`\``);
    return reply(`**Desk not started.**\n\`\`\`\n${out.split('\n').slice(-10).join('\n').slice(0, 1200)}\n\`\`\`\nIf it mentions an unclean last run, the owner starts it at tradingserver with --accept-startup-freeze after reviewing.`);
  }
  return null;
}

const USAGE = '**Trading Desk**\n- `desk status`: read-only check\n- `start desk` then `confirm start`: start it after a reboot (comes up Stopped; refused while hard-off is latched)';

module.exports = { handle, isDeskCommand, USAGE };
