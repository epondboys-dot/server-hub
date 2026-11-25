'use strict';
// Jarvis's own knowledge base: everything the hub has learned about its projects, kept on this Mac only.
//  - learn():  nightly (and after each agent task). Reads each read-only clone in ~/projects (docs, rules, build
//    status, handoffs, recent commits), Jarvis's finished tasks and briefings; splits them into passages; embeds new
//    passages with the local nomic-embed-text model; and writes a "skill card" per project with the local model
//    (what it is, how to run and test it, its rules, where it stands, what changed). Nothing leaves this machine.
//  - search(q) / answer(q): finds the closest passages and answers from them with sources, for Discord `ask` and chat.
// Read-only toward the projects: it never edits, commits or pushes. Secrets are never read or stored: env/key files
// are skipped and anything that looks like a token is masked before storage.
// CLI:  node knowledge.js learn [--cards] | ask "<question>" | stats
const fs = require('fs'), path = require('path'), os = require('os'), crypto = require('crypto');
const { execFileSync } = require('child_process');
const { DatabaseSync } = require('node:sqlite');

const HOME = os.homedir();
const PROJECTS = process.env.KB_PROJECTS || path.join(HOME, 'projects');
const KB_DIR = process.env.KB_DIR || path.join(HOME, 'hub', 'knowledge');
const TASKS_FILE = path.join(HOME, 'hub', 'tasks', 'tasks.json');
const BRIEFINGS = path.join(HOME, 'hub', 'briefings');
const OLLAMA = process.env.OLLAMA_URL || 'http://127.0.0.1:11434';
const EMBED_MODEL = process.env.KB_EMBED_MODEL || 'nomic-embed-text';
const CHAT_MODEL = process.env.OLLAMA_MODEL || 'qwen3:30b';
const SKIP_DIRS = new Set(['.git', 'node_modules', '.venv', 'venv', 'dist', 'build', '__pycache__', '.next', 'coverage', 'vendor', 'Binaries', 'Intermediate', 'Saved', 'DerivedDataCache', 'qa', 'runtime', '.pytest_cache', '.mypy_cache']);
const TEXT_EXT = new Set(['.md', '.txt']);
const KEY_FILES = /^(AGENTS|CLAUDE|README|HANDOFF|BUILD_PLAN|PROJECT_BRIEF|CODEX_NEXT|OWNER_DECISIONS)\b/i;
const SECRET_FILE = /(^\.env|\.env$|secret|credential|\.key$|\.pem$|config\.env|token)/i;
const MAX_FILE = 200 * 1024, CHUNK = 1400, OVERLAP = 200;

if (!/^https?:\/\/(127\.0\.0\.1|localhost)(:\d+)?$/.test(OLLAMA)) throw new Error('OLLAMA_URL must point at this machine');
fs.mkdirSync(path.join(KB_DIR, 'skills'), { recursive: true });

// Mask anything that looks like a credential before it is stored or shown.
const mask = s => String(s)
  .replace(/\b(sk|pk|rk|ghp|gho|github_pat|xox[abp]|AIza)[-_A-Za-z0-9]{16,}/g, '[masked]')
  .replace(/\b[MN][A-Za-z\d]{23,}\.[\w-]{6}\.[\w-]{27,}\b/g, '[masked]')
  .replace(/\b(eyJ[\w-]{10,}\.[\w-]{10,}\.[\w-]{10,})\b/g, '[masked]')
  .replace(/((?:api[_-]?key|token|secret|password)\s*[=:]\s*)\S{8,}/gi, '$1[masked]');
const sha = s => crypto.createHash('sha256').update(s).digest('hex');

function db() {
  const d = new DatabaseSync(path.join(KB_DIR, 'kb.sqlite'));
  d.exec('PRAGMA busy_timeout = 60000; PRAGMA journal_mode = WAL;'); // nightly run and a Discord `learn` may overlap
  d.exec(`CREATE TABLE IF NOT EXISTS chunks (hash TEXT PRIMARY KEY, project TEXT, source TEXT, heading TEXT, text TEXT, embedding BLOB, seen TEXT);
          CREATE INDEX IF NOT EXISTS chunks_project ON chunks(project);
          CREATE TABLE IF NOT EXISTS meta (key TEXT PRIMARY KEY, value TEXT);`);
  return d;
}

async function ollama(route, body, timeoutMs = 600000) {
  const res = await fetch(OLLAMA + route, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body), signal: AbortSignal.timeout(timeoutMs) });
  if (!res.ok) throw new Error(`Ollama ${route} answered HTTP ${res.status}`);
  return res.json();
}
async function embed(texts) {
  const out = [];
  for (let i = 0; i < texts.length; i += 16) {
    const j = await ollama('/api/embed', { model: EMBED_MODEL, input: texts.slice(i, i + 16).map(t => t.slice(0, 6000)) });
    out.push(...j.embeddings);
  }
  return out;
}
async function generate(prompt, numCtx = 16384) {
  const j = await ollama('/api/chat', { model: CHAT_MODEL, stream: false, think: false, options: { num_ctx: numCtx, temperature: 0.2 },
    messages: [{ role: 'system', content: 'You write short, accurate notes for a private engineering knowledge base. Use only the material given. Say "not in the material" rather than guess. Never include secrets.' }, { role: 'user', content: prompt }] });
  let a = String(j.message?.content || ''); const c = a.lastIndexOf('</think>'); if (c !== -1) a = a.slice(c + 8);
  return a.replace(/<think>[\s\S]*?(<\/think>|$)/g, '').trim();
}

// ---------- collecting material ----------
function walk(dir, rel = '', out = []) {
  let entries; try { entries = fs.readdirSync(dir, { withFileTypes: true }); } catch { return out; }
  for (const e of entries) {
    if (e.name.startsWith('.') && e.name !== '.github') continue;
    const p = path.join(dir, e.name), r = rel ? `${rel}/${e.name}` : e.name;
    if (e.isDirectory()) { if (!SKIP_DIRS.has(e.name)) walk(p, r, out); continue; }
    if (!e.isFile() || SECRET_FILE.test(e.name)) continue;
    const ext = path.extname(e.name).toLowerCase();
    if (TEXT_EXT.has(ext) || e.name === 'package.json' || e.name === 'pyproject.toml' || e.name === 'requirements.txt') out.push({ abs: p, rel: r });
  }
  return out;
}
function splitPassages(text) {
  // split on markdown headings first, then by size with a little overlap
  const parts = [], lines = text.split('\n'); let heading = '', buf = [];
  const flush = () => { const t = buf.join('\n').trim(); if (t) parts.push({ heading, text: t }); buf = []; };
  for (const line of lines) { if (/^#{1,4}\s/.test(line)) { flush(); heading = line.replace(/^#+\s*/, '').slice(0, 120); } buf.push(line); }
  flush();
  const out = [];
  for (const p of parts) for (let i = 0; i < p.text.length; i += CHUNK - OVERLAP) { out.push({ heading: p.heading, text: p.text.slice(i, i + CHUNK) }); if (i + CHUNK >= p.text.length) break; }
  return out;
}
function git(repo, args) { try { return execFileSync('git', ['-C', repo, ...args], { encoding: 'utf8', timeout: 30000, stdio: ['ignore', 'pipe', 'ignore'] }).trim(); } catch { return ''; } }

function projectMaterial(name, repo) {
  const items = [];
  for (const f of walk(repo)) {
    let st; try { st = fs.statSync(f.abs); } catch { continue; }
    if (st.size > MAX_FILE) continue;
    let text; try { text = fs.readFileSync(f.abs, 'utf8'); } catch { continue; }
    if (f.rel === 'package.json' || f.rel.endsWith('/package.json')) { try { const j = JSON.parse(text); text = `package ${j.name} ${j.version}\nscripts:\n` + Object.entries(j.scripts || {}).map(([k, v]) => `- ${k}: ${v}`).join('\n'); } catch {} }
    items.push({ source: f.rel, text: mask(text), key: KEY_FILES.test(path.basename(f.rel)) || /BUILD_STATUS_|handoff/i.test(f.rel) });
  }
  const log = git(repo, ['log', '-60', '--date=short', '--format=%ad %h %s']);
  if (log) items.push({ source: 'git log (latest 60 commits)', text: mask(log), key: true });
  return items;
}
function taskMaterial() {
  try {
    const st = JSON.parse(fs.readFileSync(TASKS_FILE, 'utf8'));
    return Object.values(st.tasks || {}).filter(t => t.plan || t.result).map(t => ({ project: t.repo || 'hub', source: `Jarvis task ${t.id} (${t.status})`,
      text: mask(`Request: ${t.request}\nAgent: ${t.agent || ''}\nPlan:\n${t.plan || ''}\nResult:\n${t.result || t.error || ''}`).slice(0, 12000) }));
  } catch { return []; }
}
function briefingMaterial() {
  try { const f = path.join(BRIEFINGS, 'latest.md'); return [{ project: 'hub', source: 'latest daily briefing', text: mask(fs.readFileSync(f, 'utf8')).slice(0, 20000) }]; } catch { return []; }
}

// ---------- learning ----------
async function learn({ cards = true, log = console.log } = {}) {
  const d = db(), now = new Date().toISOString(), seen = new Set();
  const repos = fs.existsSync(PROJECTS) ? fs.readdirSync(PROJECTS).filter(n => fs.existsSync(path.join(PROJECTS, n, '.git'))) : [];
  const docs = [];
  for (const name of repos) for (const m of projectMaterial(name, path.join(PROJECTS, name))) docs.push({ project: name, ...m });
  docs.push(...taskMaterial(), ...briefingMaterial());
  for (const f of fs.existsSync(path.join(KB_DIR, 'skills')) ? fs.readdirSync(path.join(KB_DIR, 'skills')) : [])
    docs.push({ project: f.replace(/\.md$/, ''), source: `skill card ${f}`, text: fs.readFileSync(path.join(KB_DIR, 'skills', f), 'utf8') });

  const fresh = [], has = d.prepare('SELECT 1 FROM chunks WHERE hash = ?'), touch = d.prepare('UPDATE chunks SET seen = ? WHERE hash = ?');
  for (const doc of docs) for (const p of splitPassages(doc.text)) {
    const h = sha(`${doc.project}\n${doc.source}\n${p.text}`); if (seen.has(h)) continue; seen.add(h);
    if (has.get(h)) touch.run(now, h); else fresh.push({ h, project: doc.project, source: doc.source, heading: p.heading, text: p.text });
  }
  log(`${repos.length} projects, ${seen.size} passages, ${fresh.length} new to embed`);
  const ins = d.prepare('INSERT OR REPLACE INTO chunks (hash, project, source, heading, text, embedding, seen) VALUES (?, ?, ?, ?, ?, ?, ?)');
  for (let i = 0; i < fresh.length; i += 64) {
    const batch = fresh.slice(i, i + 64), vecs = await embed(batch.map(b => `${b.project} · ${b.source} · ${b.heading}\n${b.text}`));
    batch.forEach((b, k) => ins.run(b.h, b.project, b.source, b.heading, b.text, Buffer.from(new Float32Array(vecs[k]).buffer), now));
  }
  const gone = d.prepare('DELETE FROM chunks WHERE seen IS NOT ? ').run(now).changes; // passages whose source changed or disappeared
  log(`removed ${gone} outdated passages`);

  if (cards) for (const name of repos) {
    const key = projectMaterial(name, path.join(PROJECTS, name)).filter(m => m.key);
    const material = key.map(m => `--- ${m.source} ---\n${m.text.slice(0, 6000)}`).join('\n\n').slice(0, 40000);
    const tasks = taskMaterial().filter(t => t.project === name).slice(-5).map(t => `--- ${t.source} ---\n${t.text.slice(0, 2000)}`).join('\n\n');
    const fp = sha(material + tasks), metaKey = `card:${name}`, prev = d.prepare('SELECT value FROM meta WHERE key = ?').get(metaKey);
    if (prev && prev.value === fp) continue;
    log(`writing skill card for ${name}`);
    const card = await generate(`Write the skill card for the project "${name}" from the material below. Markdown, under 450 words, with these headings:
## What it is
## How to run and test it (exact commands from the material)
## Rules the agents must follow
## Where it stands now (latest version, open work, blockers)
## Recent changes (last 2 weeks of commits, plain words)
## Gotchas learned (from task results and handoffs)

${material}\n\n${tasks}`);
    fs.writeFileSync(path.join(KB_DIR, 'skills', `${name}.md`), `# ${name} skill card\n_Written by Jarvis's local model on ${now.slice(0, 10)} from the project's own docs; check the sources before acting._\n\n${mask(card)}\n`);
    d.prepare('INSERT OR REPLACE INTO meta (key, value) VALUES (?, ?)').run(metaKey, fp);
  }
  d.prepare('INSERT OR REPLACE INTO meta (key, value) VALUES (?, ?)').run('learnedAt', now);
  d.close(); return { projects: repos.length, passages: seen.size, embedded: fresh.length };
}

// ---------- asking ----------
function cosine(a, b) { let s = 0, na = 0, nb = 0; for (let i = 0; i < a.length; i++) { s += a[i] * b[i]; na += a[i] * a[i]; nb += b[i] * b[i]; } return s / (Math.sqrt(na * nb) || 1); }
async function search(question, k = 8) {
  const d = db(); const rows = d.prepare('SELECT project, source, heading, text, embedding FROM chunks').all(); d.close();
  if (!rows.length) return [];
  const [q] = await embed([question]);
  return rows.map(r => ({ ...r, score: cosine(q, new Float32Array(r.embedding.buffer, r.embedding.byteOffset, r.embedding.byteLength / 4)) }))
    .sort((a, b) => b.score - a.score).slice(0, k).map(({ embedding, ...r }) => r);
}
// Context block for chat: the best passages above a similarity floor, or '' when nothing relevant is known.
async function contextFor(question, k = 5, floor = 0.55) {
  try {
    const hits = (await search(question, k)).filter(h => h.score >= floor);
    return hits.length ? hits.map((h, i) => `[${i + 1}] ${h.project} · ${h.source}${h.heading ? ' · ' + h.heading : ''}\n${h.text}`).join('\n\n') : '';
  } catch { return ''; }
}
async function answer(question) {
  const hits = await search(question, 8);
  if (!hits.length) return 'The knowledge base is empty so far. It fills in after the first nightly learning run (`learn`).';
  const ctx = hits.map((h, i) => `[${i + 1}] ${h.project} · ${h.source}${h.heading ? ' · ' + h.heading : ''}\n${h.text}`).join('\n\n');
  const a = await generate(`Answer the question from these passages of our own project knowledge base. Cite passages like [2]. If they don't answer it, say so in one line.\n\nQuestion: ${question}\n\n${ctx}`, 16384);
  const sources = [...new Set(hits.slice(0, 5).map(h => `${h.project} · ${h.source}`))].map(s => `- ${s}`).join('\n');
  return `${a}\n\n_Sources:_\n${sources}`;
}
function stats() {
  const d = db(); const n = d.prepare('SELECT project, COUNT(*) n FROM chunks GROUP BY project ORDER BY n DESC').all();
  const at = d.prepare("SELECT value FROM meta WHERE key = 'learnedAt'").get(); d.close();
  const cards = fs.readdirSync(path.join(KB_DIR, 'skills')).filter(f => f.endsWith('.md'));
  return { learnedAt: at?.value || null, passages: n, skillCards: cards };
}

module.exports = { learn, search, answer, contextFor, stats, mask };

if (require.main === module) {
  const [cmd, ...rest] = process.argv.slice(2);
  (async () => {
    if (cmd === 'learn') console.log(await learn({ cards: !rest.includes('--no-cards') }));
    else if (cmd === 'ask') console.log(await answer(rest.join(' ')));
    else if (cmd === 'stats') console.log(JSON.stringify(stats(), null, 2));
    else { console.error('Usage: node knowledge.js learn [--no-cards] | ask "<question>" | stats'); process.exitCode = 2; }
  })().catch(e => { console.error(e.message); process.exitCode = 1; });
}
