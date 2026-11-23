#!/usr/bin/env node
// The Brain, Phase 0: read-only daily briefing.
// Reads each project's git state and status files and writes briefings/YYYY-MM-DD.md.
// It never writes inside project folders, never runs git commands that change anything,
// and never opens files that look like credentials (it only reports their names).
'use strict';
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const HUB = path.resolve(__dirname, '..');
const REGISTRY = path.join(HUB, 'projects.json');
const OUT_DIR = path.join(HUB, 'briefings');
const SECRET_NAME = /(api.?key|passkey|password|passwd|secret|token|credential)/i;
const SAFE_SECRET_NAME = /\.(example|sample|template)$|\.(md|js|ts|py|cjs|mjs|ps1|cmd|bat|html|svg)$/i;

function git(dir, args) {
  try {
    return execFileSync('git', ['-c', 'safe.directory=*', '-c', 'core.fileMode=false',
      '--no-optional-locks', '-C', dir, ...args],
      { encoding: 'utf8', timeout: 20000, stdio: ['ignore', 'pipe', 'ignore'],
        env: { ...process.env, GIT_OPTIONAL_LOCKS: '0', GIT_TERMINAL_PROMPT: '0' } }).trimEnd();
  } catch { return null; }
}

function resolveDir(p) {
  if (!p) return null;
  if (path.isAbsolute(p) || /^[A-Za-z]:[\\/]/.test(p)) return p;
  return path.resolve(HUB, p);
}

function versionSort(a, b) {
  return a.localeCompare(b, undefined, { numeric: true, sensitivity: 'base' });
}

function matchFiles(dir, pattern) {
  const rel = pattern.replace(/\\/g, '/');
  const folder = path.join(dir, path.dirname(rel));
  const base = path.basename(rel);
  if (!base.includes('*')) {
    const f = path.join(dir, rel);
    return fs.existsSync(f) ? [f] : [];
  }
  const re = new RegExp('^' + base.split('*').map(s => s.replace(/[.+?^${}()|[\]\\]/g, '\\$&')).join('.*') + '$', 'i');
  let names = [];
  try { names = fs.readdirSync(folder).filter(n => re.test(n)); } catch { return []; }
  return names.sort(versionSort).map(n => path.join(folder, n));
}

function excerpt(file, maxLines = 8) {
  let text;
  try { text = fs.readFileSync(file, 'utf8'); } catch { return null; }
  const lines = text.split(/\r?\n/).map(l => l.trim()).filter(Boolean);
  const title = (lines[0] || '').replace(/^#+\s*/, '');
  const body = lines.slice(1).filter(l => !/^[-|]{3,}/.test(l)).slice(0, maxLines);
  return { title, body };
}

function age(ms) {
  const h = Math.round((Date.now() - ms) / 36e5);
  return h < 48 ? `${h} h ago` : `${Math.round(h / 24)} days ago`;
}

function scanSecretNames(dir) {
  const found = [];
  const walk = (d, depth) => {
    let entries = [];
    try { entries = fs.readdirSync(d, { withFileTypes: true }); } catch { return; }
    for (const e of entries) {
      if (e.name === '.git' || e.name === 'node_modules' || e.name === '.venv') continue;
      const full = path.join(d, e.name);
      if (e.isDirectory()) { if (depth < 1) walk(full, depth + 1); continue; }
      if (SECRET_NAME.test(e.name) && !SAFE_SECRET_NAME.test(e.name)) {
        const rel = path.relative(dir, full).replace(/\\/g, '/');
        const tracked = git(dir, ['ls-files', '--error-unmatch', rel]) !== null;
        found.push({ rel, tracked });
      }
    }
  };
  walk(dir, 0);
  return found;
}

function checkProject(p) {
  const r = { p, needs: [], lines: [] };
  const dir = resolveDir(p.path);
  if (!dir) { r.lines.push(`- Not set up on this machine yet${p.pending ? ` (${p.pending})` : ''}.`); return r; }
  if (!fs.existsSync(dir)) { r.lines.push(`- Folder not reachable from here: \`${p.path}\`.`); return r; }

  const head = git(dir, ['status', '--porcelain=v1', '-b']);
  if (head === null) {
    r.lines.push('- Not a Git repository, or Git could not read it.');
  } else {
    const [branchLine] = head.split('\n').filter(Boolean);
    // Count real edits only: ignore line-ending-only differences, include staged and new files.
    const list = a => (git(dir, a) || '').split('\n').filter(Boolean);
    const changes = [...new Set([
      ...list(['diff', '--ignore-cr-at-eol', '--numstat']).filter(l => !/^0\t0\t/.test(l)).map(l => l.split('\t')[2]),
      ...list(['diff', '--cached', '--name-only']),
      ...list(['ls-files', '--others', '--exclude-standard']),
    ])];
    const m = /^## (.+?)(?:\.\.\.(\S+))?(?: \[(.+)\])?$/.exec(branchLine || '') || [];
    const branch = m[1] || '?', upstream = m[2], track = m[3] || '';
    const ahead = +(/ahead (\d+)/.exec(track) || [0, 0])[1];
    const behind = +(/behind (\d+)/.exec(track) || [0, 0])[1];
    const last = git(dir, ['log', '-1', '--format=%h|%ct|%s']);
    const day = git(dir, ['log', '--since=24.hours', '--oneline']);
    const recent = day ? day.split('\n').filter(Boolean).length : 0;
    r.lines.push(`- Branch \`${branch}\`${upstream ? ` tracking \`${upstream}\`` : ' (no upstream)'}.`);
    if (last) {
      const [h, t, s] = last.split('|');
      r.lines.push(`- Last commit \`${h}\` ${age(+t * 1000)}: ${s}`);
    }
    r.lines.push(`- Commits in the last 24 hours: ${recent}.`);
    if (changes.length) {
      r.lines.push(`- Uncommitted changes: ${changes.length} file(s), e.g. ${changes.slice(0, 4).map(c => '`' + c + '`').join(', ')}.`);
      r.needs.push(`${changes.length} uncommitted file(s)`);
    }
    if (ahead) r.needs.push(`${ahead} commit(s) not pushed`);
    if (behind) r.needs.push(`${behind} commit(s) to pull (as of the last fetch)`);
    if (!upstream) r.needs.push('branch has no upstream on GitHub');
  }

  for (const s of p.status || []) {
    const files = matchFiles(dir, s.file);
    if (!files.length) continue;
    const f = files[files.length - 1];
    const rel = path.relative(dir, f).replace(/\\/g, '/');
    const mtime = fs.statSync(f).mtimeMs;
    if (s.show === 'lines') {
      const re = new RegExp(s.match, 'i');
      const hits = fs.readFileSync(f, 'utf8').split(/\r?\n/).filter(l => re.test(l));
      r.lines.push(`- **${s.label}** (\`${rel}\`):`);
      for (const h of hits.slice(0, 6)) {
        const cells = h.split('|').map(c => c.trim()).filter(Boolean);
        r.lines.push(`    - ${cells.slice(0, 2).join(': ')}${cells[3] ? ` - ${cells[3]}` : ''}`);
      }
    } else {
      const ex = excerpt(f, 5);
      if (!ex) continue;
      r.lines.push(`- **${s.label}** (\`${rel}\`, updated ${age(mtime)}): ${ex.title}`);
      for (const b of ex.body) r.lines.push(`    > ${b.length > 220 ? b.slice(0, 217) + '...' : b}`);
      if (/CODEX_NEXT/i.test(rel) && !/no open steps|\bdone\b/i.test(ex.title)) r.needs.push('open handoff steps in CODEX_NEXT');
    }
  }

  const secrets = scanSecretNames(dir);
  if (secrets.length) {
    const names = secrets.map(s => `\`${s.rel}\`${s.tracked ? ' (TRACKED BY GIT)' : ''}`).join(', ');
    r.lines.push(`- Files that look like credentials sitting in the folder: ${names}. Contents not read.`);
    r.needs.push(`${secrets.length} credential-looking file(s) to move into a password manager`);
    if (secrets.some(s => s.tracked)) r.needs.push('a credential-looking file is committed to Git');
  }
  return r;
}

function build() {
  const reg = JSON.parse(fs.readFileSync(REGISTRY, 'utf8'));
  const now = new Date();
  const date = now.toLocaleDateString('en-CA');
  const results = reg.projects.map(checkProject);
  const md = [];
  md.push(`# Daily briefing, ${date}`, '');
  md.push(`Generated ${now.toLocaleString('en-US')} on ${require('os').hostname()} by the Brain (Phase 0, read-only).`, '');
  md.push('## Needs you', '');
  const needy = results.filter(r => r.needs.length);
  if (!needy.length) md.push('Nothing flagged.');
  for (const r of needy) md.push(`- **${r.p.name}:** ${r.needs.join('; ')}.`);
  md.push('');
  for (const r of results) {
    md.push(`## ${r.p.name}`, '', ...r.lines, '');
  }
  md.push('---', 'Read-only: no project files were changed, no Git command that writes was run, and no credential file was opened.');
  return { date, text: md.join('\n'), needy };
}

async function postDiscord(b) {
  const url = process.env.BRIEFING_DISCORD_WEBHOOK;
  if (!url) return;
  const lines = [`**Daily briefing ${b.date}**`];
  if (!b.needy.length) lines.push('Nothing needs you today.');
  for (const r of b.needy) lines.push(`- ${r.p.name}: ${r.needs.join('; ')}`);
  lines.push('Full briefing is in server-hub/briefings.');
  const content = lines.join('\n').slice(0, 1900);
  try {
    const res = await fetch(url, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ content }) });
    console.log(res.ok ? 'Posted summary to Discord.' : `Discord post failed: HTTP ${res.status}`);
  } catch (e) { console.log(`Discord post failed: ${e.message}`); }
}

(async () => {
  const b = build();
  fs.mkdirSync(OUT_DIR, { recursive: true });
  const file = path.join(OUT_DIR, `${b.date}.md`);
  fs.writeFileSync(file, b.text);
  fs.writeFileSync(path.join(OUT_DIR, 'latest.md'), b.text);
  if (process.argv.includes('--print')) console.log(b.text);
  console.log(`Briefing written to ${file}`);
  await postDiscord(b);
})();
