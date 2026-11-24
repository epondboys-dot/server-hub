// Jarvis: Trading Desk controls (owner decisions 12 and 13).
//   desk status                        read-only
//   pause desk / resume desk           paper entries off / on (no confirmation)
//   stop desk, restart desk, start desk   ask first; `confirm <action>` within 5 minutes by the same owner
// The SSH key can only run these on tradingserver (forced command there), so even a bug here cannot clear
// hard-off, reset, change limits or keys, or touch real money.
'use strict';
const os = require('os');
const path = require('path');
const { execFile } = require('child_process');

const KEY = path.join(os.homedir(), '.ssh', 'jarvis_desk_ed25519');
const WINDOW_MS = 5 * 60 * 1000;
const CONFIRM = {
  stop: 'Full **Stop**: the desk tries to close every virtual position at current prices, then freezes fills. It keeps running; you reset it on the desk page.',
  restart: '**Restart** the desk program. It comes back exactly where it was (entries and pending orders kept).',
  start: '**Start** the desk service. It resumes its saved state. Refused while hard-off is latched.',
};
let pending = null; // { action, by, at }

function remote(cfg, command, timeoutMs) {
  const host = cfg.DESK_SSH_HOST || '100.111.197.47';
  return new Promise(resolve => execFile('/usr/bin/ssh',
    ['-i', KEY, '-o', 'BatchMode=yes', '-o', 'IdentitiesOnly=yes', '-o', 'ConnectTimeout=10', `epondboys@${host}`, command],
    { timeout: timeoutMs, maxBuffer: 1 << 20 },
    (error, stdout, stderr) => resolve({ ok: !error, out: String(stdout || '').trim(), err: String(stderr || '').trim() })));
}

function summarize(text) {
  try {
    const j = JSON.parse(text.slice(text.indexOf('{'), text.lastIndexOf('}') + 1));
    if ('running' in j) {
      if (!j.running) return `desk **not running**${j.hardOff ? ' · **hard-off latched**' : ''} · saved mode ${j.mode}${j.savedStop ? ' · Stop saved' : ''}`;
      const d = j.desk || {};
      return [`desk running (v${d.version})`, `mode ${d.mode}`, d.stopped ? '**Stopped**' : 'active',
        d.entriesEnabled ? 'entries **on**' : 'entries off', `${d.openVirtualPositions ?? '?'} open position(s)`].join(' · ');
    }
    if ('paused' in j) return 'Paper entries are **off**. Pending entries were cancelled; open positions stay.';
    if ('resumed' in j) return j.entriesEnabled ? 'Paper entries are **on**.' : 'Asked to resume, but entries are still off; check the desk page.';
    if ('stopped' in j) return `Desk **Stopped**${j.saved ? ' (saved)' : ''}. ${j.note || ''}`;
  } catch {}
  return text.split('\n').filter(Boolean).slice(-8).join('\n').slice(0, 1200);
}

const RX = /^(desk status|pause desk|resume desk|stop desk|restart desk|start desk|confirm (stop|restart|start)|cancel)$/i;
const isDeskCommand = t => RX.test(t.trim());

async function run(cfg, action, reply, timeoutMs = 60000) {
  const r = await remote(cfg, action, timeoutMs);
  const body = summarize(r.out || r.err);
  return reply(r.ok ? `**Trading Desk:** ${body}` : `**Not done.** ${body || 'The desk machine did not answer.'}`);
}

async function handle(text, author, cfg, reply) {
  const cmd = text.trim().toLowerCase();
  if (cmd === 'desk status') return run(cfg, 'status', reply, 30000);
  if (cmd === 'pause desk') return run(cfg, 'pause', reply);
  if (cmd === 'resume desk') return run(cfg, 'resume', reply);
  const ask = /^(stop|restart|start) desk$/.exec(cmd);
  if (ask) {
    pending = { action: ask[1], by: author, at: Date.now() };
    return reply(`${CONFIRM[ask[1]]}\nType \`confirm ${ask[1]}\` within 5 minutes, or \`cancel\`.`);
  }
  if (cmd === 'cancel') { const had = pending; pending = null; return reply(had ? `${had.action} cancelled.` : 'Nothing to cancel.'); }
  const confirm = /^confirm (stop|restart|start)$/.exec(cmd);
  if (confirm) {
    if (!pending || pending.action !== confirm[1] || Date.now() - pending.at > WINDOW_MS) { pending = null; return reply(`Nothing to confirm. Type \`${confirm[1]} desk\` first.`); }
    if (pending.by !== author) return reply('Only the owner who asked can confirm this.');
    pending = null;
    await reply(`Working on it: ${confirm[1]} desk…`);
    return run(cfg, confirm[1], reply, 180000);
  }
  return null;
}

const USAGE = '**Trading Desk**\n- `desk status`\n- `pause desk` / `resume desk`: paper entries off / on\n- `stop desk`, `restart desk`, `start desk`: each asks you to confirm first';

module.exports = { handle, isDeskCommand, USAGE };
