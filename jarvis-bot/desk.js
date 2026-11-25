// Jarvis: Trading Desk controls (owner decisions 12 and 13).
//   desk status, desk report, desk link   read-only (report: each open trade with P&L, orders, recent fills)
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

const money = v => v === null || v === undefined ? '?' : `${v < 0 ? '−' : ''}$${Math.abs(v).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
const signed = v => v === null || v === undefined ? '?' : `${v >= 0 ? '+' : '−'}$${Math.abs(v).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
const et = iso => iso ? new Date(iso).toLocaleString('en-US', { timeZone: 'America/New_York', month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' }) : '';
function formatReport(j) {
  if (!j.running) {
    const saved = Array.isArray(j.savedPositions) ? j.savedPositions : [];
    return `Desk **not running**${j.hardOff ? ' · **hard-off latched**' : ''}${j.savedStop ? ' · Stop saved' : ''}.\n` +
      (saved.length ? `Saved open positions (prices unknown while it is down): ${saved.map(p => p.symbol).join(', ')}` : 'No open positions saved.');
  }
  const head = [`v${j.version}`, `${j.mode} mode`, j.stopped ? '**Stopped**' : null, j.entriesEnabled ? 'entries **on**' : 'entries off', j.lossLatched ? '**daily loss limit hit**' : null, j.hardOff ? '**hard-off**' : null].filter(Boolean).join(' · ');
  const lines = [`${head}`, `Equity ${money(j.equity)} · today ${signed(j.todayPnl)} · cash ${money(j.cash)} · realized to date ${signed(j.realizedTotal)}`];
  lines.push(j.positions.length ? `**Open trades (${j.positions.length})**` : '**No open trades.**');
  for (const p of j.positions) lines.push(`- **${p.symbol}** ${p.quantity ?? ''} · cost ${money(p.cost)} → ${money(p.value)} (${signed(p.unrealized)}${p.unrealizedPct !== null ? `, ${p.unrealizedPct >= 0 ? '+' : ''}${p.unrealizedPct}%` : ''})${p.stop !== null ? ` · stop ${money(p.stop)}` : ''}${p.openedAt ? ` · opened ${et(p.openedAt)}` : ''}${p.priceMissing ? ` · no current price (${p.priceMissing})` : ''}`);
  if (j.pendingOrders.length) lines.push(`Pending: ${j.pendingOrders.map(o => `${o.side} ${o.symbol} ${o.quantity ?? ''}`).join(', ')}`);
  if (j.recentFills.length) lines.push(`Recent fills: ${j.recentFills.slice(0, 3).map(f => `${f.side} ${f.symbol} @ ${money(f.price)}${f.realized !== null ? ` (${signed(f.realized)})` : ''} ${et(f.at)}`).join(' · ')}`);
  if (j.valuationMissing) lines.push('Some prices are missing, so equity and P&L may be blank.');
  lines.push('Paper only (virtual money). Read-only report; nothing was changed.');
  return lines.join('\n');
}

// Live desk snapshot as text (for `desk report`, plain questions and for agents working on the trading project).
async function liveReport(cfg) {
  const r = await remote(cfg, 'report', 30000);
  try {
    const t = r.out; const j = JSON.parse(t.slice(t.indexOf('{'), t.lastIndexOf('}') + 1));
    if (j.report) return { ok: true, text: formatReport(j) };
  } catch {}
  // Older forced-command script on tradingserver (no `report` yet): fall back to the summary.
  const s = await remote(cfg, 'status', 30000);
  return { ok: s.ok, text: `${summarize(s.out || s.err) || 'The desk machine did not answer.'}${/REFUSED/.test(r.out) ? '\n(Per-trade detail needs the updated desk key script on tradingserver: rerun `desk-remote/setup-desk-remote.sh` there once.)' : ''}` };
}
const PHONE_URL = 'https://tradingserver.tail7f64e5.ts.net';

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

const RX = /^(desk report|desk link|desk page|desk status|pause desk|resume desk|stop desk|restart desk|start desk|confirm (stop|restart|start)|cancel)$/i;
const isDeskCommand = t => RX.test(t.trim());

async function run(cfg, action, reply, timeoutMs = 60000) {
  const r = await remote(cfg, action, timeoutMs);
  const body = summarize(r.out || r.err);
  return reply(r.ok ? `**Trading Desk:** ${body}` : `**Not done.** ${body || 'The desk machine did not answer.'}`);
}

async function handle(text, author, cfg, reply) {
  const cmd = text.trim().toLowerCase();
  if (cmd === 'desk status') return run(cfg, 'status', reply, 30000);
  if (cmd === 'desk report') { const r = await liveReport(cfg); return reply(`**Trading Desk**\n${r.text}`); }
  if (cmd === 'desk link' || cmd === 'desk page') return reply(`Phone desk page (Tailscale on, paired device): ${PHONE_URL}\nIt shows status and the market map and has Stop and hard-off. Full controls stay on the desk page at tradingserver.`);
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

const USAGE = '**Trading Desk**\n- `desk report`: each open trade with P&L, pending orders, recent fills · `desk link`: phone page\n- `desk status`\n- `pause desk` / `resume desk`: paper entries off / on\n- `stop desk`, `restart desk`, `start desk`: each asks you to confirm first';

module.exports = { handle, isDeskCommand, USAGE, liveReport, PHONE_URL };
