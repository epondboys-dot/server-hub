// Jarvis agent tasks: plan first, act only after an owner approves.
//
//   plan <project> <request>  Claude Code reads the project (read-only tools only: it cannot change anything)
//                             and replies with a step-by-step plan.
//   approve <id>              Claude Code carries out that plan in a separate copy
//                             (~/work/<id>, branch jarvis/<id>). It can edit files, run tests and commit
//                             there. It cannot push: Jarvis's GitHub token is read-only and push is blocked.
//   cancel <id> | discard <id> | tasks
//
// The owner reviews the branch on their PC and pushes it themselves. Nothing reaches GitHub without them.
'use strict';
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawn, execFileSync } = require('child_process');

const HOME = os.homedir();
const PROJECTS_DIR = path.join(HOME, 'projects');
const WORK_DIR = path.join(HOME, 'work');
const STATE_DIR = path.join(HOME, 'hub', 'tasks');
const STATE_FILE = path.join(STATE_DIR, 'tasks.json');

const PROJECTS = {
  trading: 'ai-daytrading-bot', 'trading-bot': 'ai-daytrading-bot', 'ai-daytrading-bot': 'ai-daytrading-bot', desk: 'ai-daytrading-bot',
  retro: 'retro-game-platform', arcade: 'retro-game-platform', 'retro-game-platform': 'retro-game-platform', rewind: 'retro-game-platform',
  crease: 'the-crease', 'the-crease': 'the-crease',
  x3: 'x3-discord-admin-ai', 'x3-discord-admin-ai': 'x3-discord-admin-ai', gym: 'x3-discord-admin-ai',
  sixes: 'lax-sixes', 'lax-sixes': 'lax-sixes', lax: 'lax-sixes', lacrosse: 'lax-sixes', unreal: 'lax-sixes',
  'rewind-arcade': 'retro-game-platform', platform: 'retro-game-platform', 'trading-desk': 'ai-daytrading-bot',
};
// Where each project's agents work. Anything not listed runs here on Jarvis (~/projects, ~/work).
// Sixes stays on the PA PC (owner, Nov 23): Jarvis reaches it over the hub network with a key that can only run
// the PA PC worker script (plan, do, discard). Builds and the Unreal editor are never run by agents.
const REMOTE = { 'lax-sixes': 'pa-pc' };
function machineFor(repo, cfg) {
  if (REMOTE[repo] !== 'pa-pc') return null;
  return { id: 'pa-pc', name: 'PA PC', host: cfg.PA_PC_HOST || '10.10.10.87', user: cfg.PA_PC_USER || 'ebutc',
    key: path.join(HOME, '.ssh', 'jarvis_worker_ed25519') };
}

const TRADING_RULES = 'This is the Trading Desk repository. Follow AGENTS.md and docs/OWNER_DECISIONS.md strictly. ' +
  'Never start, stop or move the desk; never touch a runtime folder, HARD_OFF.json or owner runtime files; ' +
  'never add order execution, live trading or a funded account; never put credentials anywhere.';

const CREASE_NOTE = 'This is The Crease. Run its checks with crease-test (tests), crease-test lint and crease-test types; ' +
  'they use the shared Python 3.12 environment. It is not deployed: never contact live services or add credentials.';

const RETRO_NOTE = 'This is Rewind Arcade. Run its checks with retro-test (unit), retro-test build and retro-test browser. ' +
  'Never deploy, never run the Deploy/Publish/Enable/Invite scripts, never contact the live store, Cloudflare or Supabase.';

const X3_PY = '/Users/jarvis/projects/x3-discord-admin-ai/.venv/bin/python';
const X3_NOTE = `This is the X3 Digital HQ Discord admin bot (Python). Run its tests with: ${X3_PY} -m unittest discover -s tests. ` +
  'Never start the bot, never contact Discord or Gemini, never add or print tokens or keys.';
const SIXES_NOTE = 'This is the Sixes lacrosse game (Unreal Engine 5.8) in the owner\'s working folder on the PA PC, which holds uncommitted work: ' +
  'read CLAUDE.md and the latest Docs first and preserve existing local edits. Never change .vsconfig or .slnx. You have no shell: ' +
  'make code and text edits only. Jarvis backs the folder up before and after, and the owner starts builds separately (`build sixes`); ' +
  'finish by saying exactly what to build or pad-test to check your change.';
function projectNote(repo) {
  return { 'ai-daytrading-bot': TRADING_RULES, 'the-crease': CREASE_NOTE, 'retro-game-platform': RETRO_NOTE,
    'x3-discord-admin-ai': X3_NOTE, 'lax-sixes': SIXES_NOTE }[repo] || '';
}

const PLAN_TOOLS = ['Read', 'Glob', 'Grep'];
const PLAN_BLOCKED = ['Edit', 'Write', 'NotebookEdit', 'Bash'];
const DO_TOOLS = ['Read', 'Glob', 'Grep', 'Edit', 'Write',
  'Bash(git status:*)', 'Bash(git diff:*)', 'Bash(git log:*)', 'Bash(git add:*)', 'Bash(git commit:*)',
  'Bash(node --test:*)', 'Bash(node --check:*)', 'Bash(npm test:*)', 'Bash(npm run test:*)',
  'Bash(crease-test:*)', 'Bash(/Users/jarvis/bin/crease-test:*)', 'Bash(retro-test:*)', 'Bash(/Users/jarvis/bin/retro-test:*)',
  `Bash(${X3_PY} -m unittest:*)`];
const BLOCKED = ['Bash(git push:*)', 'Bash(git remote:*)', 'Bash(curl:*)', 'Bash(wget:*)', 'Bash(rm -rf:*)',
  'Bash(sudo:*)', 'WebFetch', 'WebSearch'];

let state = { next: 1, tasks: {} };
try { state = JSON.parse(fs.readFileSync(STATE_FILE, 'utf8')); } catch {}
// A restart stops whatever was running: mark those tasks interrupted so they can be resumed.
const interruptedAtStart = [];
for (const t of Object.values(state.tasks || {})) {
  if (t.status === 'working' || t.status === 'planning') { t.status = t.plan ? 'interrupted' : 'failed'; t.error = 'Jarvis restarted while this task was running'; interruptedAtStart.push(t.id); }
}
function save() {
  fs.mkdirSync(STATE_DIR, { recursive: true });
  fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
}

let running = null; // { id, child }
// One agent job at a time. Anything asked for while one runs waits in a queue and starts by itself afterwards,
// so a new message never stops or disturbs the job in progress.
let active = null; // label of the job in progress (covers the gaps between agent processes)
const queue = [];
const busy = () => active || (running && running.id);
async function exclusive(label, reply, fn) {
  if (busy()) {
    queue.push({ label, reply, fn });
    return reply(`Queued (#${queue.length}) behind ${busy()}. I'll start it by myself when that finishes.`);
  }
  active = label;
  try { return await fn(); } finally {
    active = null;
    const next = queue.shift();
    if (next) setImmediate(() => exclusive(next.label, next.reply, next.fn).catch(e => next.reply(`Queued job failed: ${e.message}`)));
  }
}
const pendingConfirm = new Map(); // owner -> { action: 'build'|'push', at }

function git(cwd, args) {
  return execFileSync('git', ['-C', cwd, ...args], { encoding: 'utf8', timeout: 60000, stdio: ['ignore', 'pipe', 'pipe'] }).trim();
}

// Bring the hub's copy up to date with GitHub before planning or working, so a task never starts from old code.
// Fast-forward only: if the copy has local changes or has drifted, stop and say so instead of guessing.
function refresh(src) {
  git(src, ['fetch', '--quiet', 'origin']);
  const head = git(src, ['rev-parse', '--abbrev-ref', 'HEAD']);
  git(src, ['merge', '--ff-only', '--quiet', `origin/${head}`]);
  return git(src, ['log', '-1', '--format=%h %s']);
}

function runClaude(cfg, cwd, args, timeoutMs, id) {
  return runProc(cfg.CLAUDE_BIN || '/opt/homebrew/bin/claude', cfg, cwd, args, timeoutMs, id, 'Claude Code');
}

// Codex keeps its ChatGPT sign-in in ~/.codex, so it works from the background service.
async function runCodex(cfg, cwd, prompt, write, timeoutMs, id) {
  const outFile = path.join(os.tmpdir(), `jarvis-codex-${id}-${Date.now()}.txt`);
  const args = ['exec', '--skip-git-repo-check', '-s', write ? 'workspace-write' : 'read-only', '-o', outFile, prompt];
  const stdout = await runProc(cfg.CODEX_BIN || '/opt/homebrew/bin/codex', cfg, cwd, args, timeoutMs, id, 'Codex');
  let last = '';
  try { last = fs.readFileSync(outFile, 'utf8').trim(); fs.unlinkSync(outFile); } catch {}
  return last || stdout;
}

// ---- automatic agent choice ----
// Owner, Nov 23: Jarvis picks the agent itself. Claude Code first (the stronger planner); Codex when Claude is
// resting after hitting its usage limit, or as an automatic retry when Claude fails for that reason (and the reverse).
// A word like --codex or --claude in the request still forces one. Plain questions go to the local model, not here.
const LIMIT_RE = /usage limit|rate.?limit|limit reached|hit your .{0,20}limit|limit\s*[·.,-]?\s*resets|quota|too many requests|\b429\b|out of (credits|usage)|try again (in|at|later)/i;
const COOLDOWN_MS = 3 * 60 * 60 * 1000;
function restingUntil(agent) { return (state.resting && state.resting[agent]) || 0; }
function rest(agent) { state.resting = state.resting || {}; state.resting[agent] = Date.now() + COOLDOWN_MS; save(); }
function pickOrder(preferred) {
  if (preferred) return [preferred];
  const order = ['claude', 'codex'];
  return order.sort((a, b) => (restingUntil(a) > Date.now()) - (restingUntil(b) > Date.now()));
}
const NAMES = { claude: 'Claude Code', codex: 'Codex' };
async function runAuto(order, cfg, cwd, prompt, write, timeoutMs, id, note, remote) {
  let lastError;
  for (const agent of order) {
    try {
      const out = remote ? await runRemote(remote, agent, cfg, prompt, write, timeoutMs, id) : await runAgent(agent, cfg, cwd, prompt, write, timeoutMs, id);
      return { agent, out };
    } catch (e) {
      lastError = e;
      if (LIMIT_RE.test(e.message)) { rest(agent); if (note) await note(`${NAMES[agent]} is at its usage limit; switching.`); continue; }
      throw Object.assign(e, { agent });
    }
  }
  throw lastError || new Error('No agent available');
}

function runAgent(agent, cfg, cwd, prompt, write, timeoutMs, id) {
  if (agent === 'codex') return runCodex(cfg, cwd, prompt, write, timeoutMs, id);
  const args = write
    ? ['-p', prompt, '--permission-mode', 'acceptEdits', '--allowedTools', ...DO_TOOLS, '--disallowedTools', ...BLOCKED, '--output-format', 'text']
    : ['-p', prompt, '--permission-mode', 'default', '--allowedTools', ...PLAN_TOOLS, '--disallowedTools', ...PLAN_BLOCKED, ...BLOCKED, '--output-format', 'text'];
  return runClaude(cfg, cwd, args, timeoutMs, id);
}

// Another machine: ssh with the worker key. That key can only run the worker script there, which takes
// "<plan|do|discard> <task id> <repo> <agent>" and reads the prompt from stdin. No shell, no other commands.
function sshArgs(m, command) {
  return ['-i', m.key, '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=15', '-o', 'ServerAliveInterval=30', '-o', 'StrictHostKeyChecking=accept-new', `${m.user}@${m.host}`, command];
}
function runRemote(m, agent, cfg, prompt, write, timeoutMs, id) {
  const repo = state.tasks[id] ? state.tasks[id].repo : '';
  return runProc('/usr/bin/ssh', cfg, HOME, sshArgs(m, `${write ? 'do' : 'plan'} ${id} ${repo} ${agent}`), timeoutMs, id, `${NAMES[agent]} on the ${m.name}`, prompt);
}

function runProc(bin, cfg, cwd, args, timeoutMs, id, label, input) {
  return new Promise((resolve, reject) => {
    const env = { ...process.env, HOME, PATH: '/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin' };
    if (cfg.CLAUDE_CODE_OAUTH_TOKEN && bin !== '/usr/bin/ssh') env.CLAUDE_CODE_OAUTH_TOKEN = cfg.CLAUDE_CODE_OAUTH_TOKEN;
    const child = spawn(bin, args, { cwd, env, stdio: [input === undefined ? 'ignore' : 'pipe', 'pipe', 'pipe'] });
    if (input !== undefined) { child.stdin.on('error', () => {}); child.stdin.end(input); }
    running = { id, child };
    let out = '', err = '';
    child.stdout.on('data', d => { out += d; });
    child.stderr.on('data', d => { err += d; });
    const timer = setTimeout(() => { child.kill('SIGTERM'); err += '\n(timed out)'; }, timeoutMs);
    child.on('error', e => { clearTimeout(timer); running = null; reject(e); });
    child.on('close', code => {
      clearTimeout(timer); running = null;
      if (code === 0) resolve(out.trim());
      else reject(new Error(`${label} stopped (code ${code}). ${(err || out).trim().slice(-600)}`));
    });
  });
}

function resolveProject(word) {
  const repo = PROJECTS[String(word || '').toLowerCase()];
  if (!repo) return null;
  if (REMOTE[repo]) return { repo, remote: REMOTE[repo], dir: HOME };
  const dir = path.join(PROJECTS_DIR, repo);
  return fs.existsSync(path.join(dir, '.git')) ? { repo, dir } : null;
}

function short(s, n = 80) { s = String(s).replace(/\s+/g, ' ').trim(); return s.length > n ? s.slice(0, n - 1) + '…' : s; }

const PROJECT_LIST = 'trading|retro|crease|x3|sixes';
const USAGE = [
  '**Agent tasks** (Claude Code or Codex; nothing reaches GitHub without you)',
  '- **Just talk to me.** "what\'s next on retro", "fix the login bug in x3", "take a look at the project": I work out the project (and remember it for follow-ups), read it with Claude Code or Codex, and bring back a plan. Say `go` to carry it out, or tell me what to change. Questions about a project ("how does scoring work in sixes?") get an answer from the files. Anything new while an agent works waits in line; nothing gets interrupted. `stop` stops the running job.',
  '- `work on <anything>` / `look <project> <question>`: the same, spelled out',
  '- `plan <project> <what you want>`: read-only; replies with a plan and a task id. Jarvis picks Claude Code or Codex itself (switches when one hits its limit); add `--claude` or `--codex` to choose',
  '- `approve <id>`: carry out that plan in a separate copy on branch `jarvis/<id>`; commits there, never pushes',
  '- `tasks`: recent tasks · `cancel <id>`: stop a running task · `discard <id>`: delete its copy and branch',
  '- Projects: trading, retro, crease, x3 (on Jarvis) · sixes (on the PA PC, in its working folder, backed up to GitHub before and after)',
  '- Sixes: `sixes status` · `checkpoint sixes` (backup, also nightly at 02:00) · `build sixes` · `push sixes` (both ask you to confirm)',
].join('\n');

// "work on <plain words>": find the project (a project word in the text first, else the local model picks from the
// list), then start an ordinary read-only plan there. The model only chooses a project name; it cannot run anything.
async function routeProject(text, cfg) {
  const words = text.toLowerCase().match(/[a-z0-9-]+/g) || [];
  const named = words.map(w => PROJECTS[w]).find(Boolean);
  if (named) return Object.keys(PROJECTS).find(k => PROJECTS[k] === named);
  try {
    const res = await fetch((cfg.OLLAMA_URL || 'http://127.0.0.1:11434') + '/api/chat', { method: 'POST', headers: { 'Content-Type': 'application/json' }, signal: AbortSignal.timeout(120000),
      body: JSON.stringify({ model: cfg.OLLAMA_MODEL || 'qwen3:30b', stream: false, think: false, format: 'json', options: { temperature: 0 },
        messages: [{ role: 'system', content: 'Pick which project a request is about. Projects: trading (AI trading desk, paper trading, market map, Alpaca), retro (Rewind Arcade browser game store), crease (The Crease lacrosse highlight video engine), x3 (X3 gym Discord admin bot), sixes (Sixes lacrosse video game in Unreal Engine). Answer JSON {"project": "<one of trading|retro|crease|x3|sixes|none>"}.' },
          { role: 'user', content: text }] }) });
    const p = JSON.parse((await res.json()).message.content).project;
    return PROJECTS[p] ? p : null;
  } catch { return null; }
}

async function handle(text, author, cfg, reply, ctx = {}) {
  const [verb, ...rest] = text.trim().split(/\s+/);
  const v = verb.toLowerCase();

  if (v === 'work' && (rest[0] || '').toLowerCase() === 'on') {
    const request = rest.slice(1).join(' ').trim();
    if (!request) return reply('Tell me what to work on, e.g. `work on the x3 bot: add a channel for speed tests`');
    const p = await routeProject(request, cfg);
    if (!p) return reply(`I couldn't tell which project that is. Send \`plan <${PROJECT_LIST}> ${short(request, 60)}\`.`);
    const where = REMOTE[PROJECTS[p]] ? 'the PA PC' : 'Jarvis';
    await reply(`That's **${p}** (${PROJECTS[p]}, runs on ${where}). Starting a read-only plan; nothing changes until you approve it.`);
    return handle(`plan ${p} ${request}`, author, cfg, reply, ctx);
  }

  // ---- Sixes on the PA PC: status, backups, builds, pushes (owner, Nov 25: as automated as possible) ----
  // checkpoint and status run straight away; build and push ask the owner to confirm (Unreal builds are approved
  // one at a time, Nov 23). The worker never force-pushes, so a push refuses if GitHub has newer work.
  const sixesOp = /^(?:(build|push|checkpoint)\s+sixes|sixes\s+(status)|confirm\s+(build|push))$/i.exec(text.trim());
  if (sixesOp) {
    const m = machineFor('lax-sixes', cfg);
    const run = async (op, timeoutMs) => {
      if (busy()) return reply(`Busy with ${busy()}. Try again when it finishes.`);
      try { return reply(await runProc('/usr/bin/ssh', cfg, HOME, sshArgs(m, `${op} T0 lax-sixes -`), timeoutMs, `sixes-${op}`, `the ${m.name} worker`, '')); }
      catch (e) { return reply(`Sixes ${op} on the ${m.name}: ${e.message}`); }
    };
    const [, ask, stat, conf] = sixesOp.map(x => x && x.toLowerCase());
    if (stat) return run('status', 60000);
    if (ask === 'checkpoint') { await reply('Backing up the Sixes working folder on the PA PC to GitHub (the folder is not changed).'); return run('checkpoint', 10 * 60000); }
    if (ask) {
      pendingConfirm.set(author, { action: ask, at: Date.now() });
      return reply(ask === 'build' ? 'Build Sixes on the PA PC now (SixesGameEditor, Win64 Development, about 5 to 30 minutes)? Type `confirm build` within 5 minutes.'
        : 'Push the PA PC\'s current Sixes branch to GitHub (fast-forward only; it refuses if GitHub has newer work)? Type `confirm push` within 5 minutes.');
    }
    const p = pendingConfirm.get(author);
    if (!p || p.action !== conf || Date.now() - p.at > 5 * 60000) return reply(`Nothing to confirm. Type \`${conf} sixes\` first.`);
    pendingConfirm.delete(author);
    if (conf === 'build') { await reply('Building Sixes on the PA PC. I\'ll post the result here.'); return run('build', 120 * 60000); }
    return run('push', 10 * 60000);
  }

  if (v === 'agents') {
    return reply(['claude', 'codex'].map(a => `- ${NAMES[a]}: ${restingUntil(a) > Date.now() ? `resting until ${new Date(restingUntil(a)).toLocaleTimeString('en-US')}` : 'ready'}`).join('\n') +
      '\n- Local model (Ollama): answers plain questions');
  }
  if (v === 'tasks') {
    if (queue.length) await reply(`Waiting in line: ${queue.map(q => q.label).join(', ')}`);
    const list = Object.values(state.tasks).sort((a, b) => b.n - a.n).slice(0, 8);
    if (!list.length) return reply('No tasks yet.\n\n' + USAGE);
    return reply(list.map(t => `- **${t.id}** [${t.status}] ${t.agent || 'claude'} · ${t.repo}: ${short(t.request)}`).join('\n'));
  }

  if (v === 'plan' || v === 'look') {
    let forced = null;
    const words = rest.filter(w => {
      if (/^--?codex$/i.test(w)) { forced = 'codex'; return false; }
      if (/^--?claude$/i.test(w)) { forced = 'claude'; return false; }
      return true;
    });
    const order = pickOrder(forced);
    let agent = order[0];
    const proj = resolveProject(words[0]);
    const request = words.slice(1).join(' ').trim();
    if (!proj || !request) return reply(`Usage: \`plan <${PROJECT_LIST}> <what you want>\``);
    const kind = v;
    return exclusive(`a ${kind} on ${proj.repo}`, reply, async () => {
    const machine = proj.remote ? machineFor(proj.repo, cfg) : null;
    const n = state.next++;
    const id = `T${n}`;
    let latest = machine ? `latest on the ${machine.name}` : null;
    if (!machine) {
      try { latest = refresh(proj.dir); } catch (e) {
        state.next--; save();
        return reply(`Couldn't update ${proj.repo} from GitHub first, so I didn't plan: ${String(e.stderr || e.message).trim().slice(0, 300)}`);
      }
    }
    const t = state.tasks[id] = { id, n, agent, kind, repo: proj.repo, machine: machine ? machine.id : 'jarvis', request, author, channel: ctx.channel || null, status: 'planning', created: new Date().toISOString(), plannedOn: latest };
    if (ctx.channel) { state.focus = state.focus || {}; state.focus[ctx.channel] = proj.repo; }
    save();
    await reply(`**${id}** ${kind === 'look' ? 'looking into' : 'planning on'} ${proj.repo}${machine ? ` (on the ${machine.name})` : ''} with ${NAMES[agent]}${forced ? '' : ' (picked automatically)'} (read-only). This can take a few minutes.`);
    const prompt = kind === 'look' ? [
      'The owner asked a question about this project from their phone. Answer it by reading the project files.',
      'Read any AGENTS.md, CLAUDE.md and README first and follow their rules.',
      projectNote(proj.repo),
      'Do not change anything. Answer plainly in under 250 words, naming the files you relied on.',
      'End with one line starting "Suggested next step:" if there is an obvious one.',
      `Question: ${request}`,
    ].filter(Boolean).join('\n') : [
      'You are planning a change for the owner, who will approve it from their phone.',
      'Read any AGENTS.md, CLAUDE.md and README first and follow their rules.',
      projectNote(proj.repo),
      'If the request is open-ended (for example "what is next" or "keep going"), first read the project\'s status, plan,',
      'handoff and work-order documents and recent commits, say in two lines where the project stands, then plan the single most',
      'valuable next step that can be done safely without the owner at the keyboard.',
      'Do not change anything. Reply with: a one-line summary; numbered steps; the files you would change;',
      'the tests you would run; and any risks or questions. Keep it under 300 words, plain text.',
      `Request: ${request}`,
    ].filter(Boolean).join('\n');
    try {
      const res = await runAuto(order, cfg, proj.dir, prompt, false, 10 * 60 * 1000, id, reply, machine);
      agent = t.agent = res.agent; t.plan = res.out;
      t.status = kind === 'look' ? 'answered' : 'planned';
      save();
      if (kind === 'look') return reply(`**${id}** (${proj.repo}, ${NAMES[agent]})\n${t.plan}\n\nTell me what you'd like done next and I'll plan it.`);
      return reply(`**${id} plan** (${proj.repo}, ${NAMES[agent]})\n${t.plan}\n\nTo carry it out say \`go\` (or \`approve ${id}\`). To change it, just tell me what to change. Nothing changes until then.`);
    } catch (e) {
      t.status = 'failed'; t.error = e.message; save();
      return reply(`**${id}** ${kind === 'look' ? 'lookup' : 'planning'} failed: ${e.message}`);
    }
    });
  }

  if (v === 'approve') {
    const t = state.tasks[String(rest[0] || '').toUpperCase()];
    if (!t) return reply('Usage: `approve <id>` (see `tasks`)');
    if (!['planned', 'interrupted'].includes(t.status)) return reply(`${t.id} is ${t.status}; only a planned or interrupted task can be approved.`);
    if (t.status === 'interrupted') { // start the approved work over from a clean copy
      const src0 = path.join(PROJECTS_DIR, t.repo);
      try { git(src0, ['worktree', 'remove', '--force', path.join(WORK_DIR, t.id)]); } catch {}
      try { git(src0, ['worktree', 'prune']); } catch {}
      try { git(src0, ['branch', '-D', `jarvis/${t.id}`]); } catch {}
    }
    if (t.queued) return reply(`${t.id} is already queued.`);
    t.queued = true;
    return exclusive(`${t.id}`, reply, async () => { t.queued = false;
    const machine = machineFor(t.repo, cfg);
    if (machine) {
      // The worker on that machine makes the separate copy (branch jarvis/<id>), runs the agent and commits there.
      t.status = 'working'; t.approvedBy = author; t.approved = new Date().toISOString(); save();
      await reply(`**${t.id}** approved. Working in the Sixes folder on the ${machine.name}, with a GitHub backup before and after. This can take a while.`);
      const prompt = ['Carry out this plan, which the owner has approved. Stay within it; if something outside it is needed, stop and explain.',
        'Read any AGENTS.md, CLAUDE.md and README first and follow their rules.', projectNote(t.repo),
        'Leave your edits in the working folder; do not commit, push or change git settings (Jarvis backs up before and after).',
        'Finish with a short plain-text summary: what changed, anything the owner should check or build.',
        `Original request: ${t.request}`, `Approved plan:\n${t.plan}`].filter(Boolean).join('\n');
      try {
        const first = t.agent || 'claude', other = first === 'claude' ? 'codex' : 'claude';
        const res = await runAuto(restingUntil(first) > Date.now() ? [other, first] : [first, other], cfg, HOME, prompt, true, 45 * 60 * 1000, t.id, reply, machine);
        t.doneBy = res.agent; t.summary = res.out; t.status = 'done'; t.finished = new Date().toISOString(); save();
        return reply([`**${t.id} done** on the ${machine.name} (${t.repo}, ${NAMES[t.doneBy] || ''})`, t.summary, '',
          'Next: `build sixes` to compile it (you confirm), `sixes status`, or `push sixes` once it is committed and the rigs are in sync.'].join('\n'));
      } catch (e) {
        t.status = 'failed'; t.error = e.message; save();
        return reply(`**${t.id}** stopped on the ${machine.name}: ${e.message}\nAny edits it made are in the working folder; the "before" backup branch on GitHub has the state from just before it started.`);
      }
    }
    const src = path.join(PROJECTS_DIR, t.repo);
    const wt = path.join(WORK_DIR, t.id);
    const branch = `jarvis/${t.id}`;
    t.status = 'working'; t.approvedBy = author; t.approved = new Date().toISOString(); save();
    await reply(`**${t.id}** approved. Working in a separate copy on branch \`${branch}\`. This can take a while.`);
    try {
      fs.mkdirSync(WORK_DIR, { recursive: true });
      refresh(src);
      t.base = git(src, ['rev-parse', 'HEAD']);
      git(src, ['worktree', 'add', '-b', branch, wt, t.base]);
      const prompt = [
        'Carry out this plan, which the owner has approved. Stay within it; if something outside it is needed, stop and explain.',
        'Read any AGENTS.md, CLAUDE.md and README first and follow their rules, including their test and versioning steps.',
        projectNote(t.repo),
        'Run the project\'s tests if it has them. Commit your work to the current branch with a clear message if you can; if not, leave the changes and Jarvis will commit them. Never push or change git remotes.',
        'Finish with a short plain-text summary: what changed, test results, anything the owner should check.',
        `Original request: ${t.request}`,
        `Approved plan:\n${t.plan}`,
      ].filter(Boolean).join('\n');
      const first = t.agent || 'claude', other = first === 'claude' ? 'codex' : 'claude';
      const res = await runAuto(restingUntil(first) > Date.now() ? [other, first] : [first, other], cfg, wt, prompt, true, 30 * 60 * 1000, t.id, reply);
      t.doneBy = res.agent; t.summary = res.out;
      if (git(wt, ['status', '--porcelain'])) {
        git(wt, ['add', '-A']);
        git(wt, ['-c', 'user.name=Jarvis', '-c', 'user.email=jarvis@localhost', 'commit', '-q', '-m', `Jarvis ${t.id}: ${short(t.request, 60)}`]);
      }
      const log = git(wt, ['log', '--oneline', `${t.base}..HEAD`]) || '(no commits)';
      const stat = git(wt, ['diff', '--stat', `${t.base}..HEAD`]) || '(no file changes)';
      t.status = 'done'; t.finished = new Date().toISOString(); save();
      return reply([
        `**${t.id} done** (${t.repo}, ${NAMES[t.doneBy] || ''}, branch \`${branch}\`)`, t.summary, '',
        '```', log, stat.split('\n').slice(-12).join('\n'), '```',
        'Review and push it yourself from a PC:',
        '```', `git fetch epondboys@10.10.10.240:/Users/jarvis/work/${t.id} ${branch}:${branch}`, `git log -p ${t.base.slice(0, 7)}..${branch}`, `git push origin ${branch}`, '```',
        `Or \`discard ${t.id}\` to throw it away.`,
      ].join('\n'));
    } catch (e) {
      t.status = 'failed'; t.error = e.message; save();
      return reply(`**${t.id}** stopped: ${e.message}\nThe copy is kept at ~/work/${t.id}; \`discard ${t.id}\` removes it.`);
    }
    });
  }

  if (v === 'cancel') {
    const id = String(rest[0] || '').toUpperCase();
    if (!running || running.id !== id) return reply(`${id || 'That task'} is not running.`);
    running.child.kill('SIGTERM');
    return reply(`Stopping ${id}.`);
  }

  if (v === 'discard') {
    const t = state.tasks[String(rest[0] || '').toUpperCase()];
    if (!t) return reply('Usage: `discard <id>`');
    if (running && running.id === t.id) return reply(`${t.id} is running; \`cancel ${t.id}\` first.`);
    const machine = machineFor(t.repo, cfg);
    if (machine) {
      try { await runProc('/usr/bin/ssh', cfg, HOME, sshArgs(machine, `discard ${t.id} ${t.repo} -`), 60000, `discard-${t.id}`, `the ${machine.name} worker`, ''); }
      catch (e) { return reply(`Couldn't reach the ${machine.name} to discard ${t.id}: ${e.message}`); }
      t.status = 'discarded'; save();
      return reply(`${t.id} discarded on the ${machine.name}.`);
    }
    const src = path.join(PROJECTS_DIR, t.repo);
    try { git(src, ['worktree', 'remove', '--force', path.join(WORK_DIR, t.id)]); } catch {}
    try { git(src, ['branch', '-D', `jarvis/${t.id}`]); } catch {}
    t.status = 'discarded'; save();
    return reply(`${t.id} discarded.`);
  }

  return null; // not a task command
}

// ---- plain-language messages (owner, Nov 25: "I need to be able to do actions like this across all the projects") ----
// Every message that is not an exact command comes here first. The local model only classifies it (work / look / chat,
// which project); it cannot run anything. Work and look start the same read-only agent runs as `plan`, so nothing
// changes until the owner says go. Approval is never decided by the model: only an owner's plain yes/go counts.
const APPROVE_RE = /^(yes|yeah|yep|yup|go|go ahead|go for it|do it|approve|approved|ok go|ok do it|run it|send it|ship it|proceed|sounds good|lets do it|let's do it|lgtm)[.! ]*$/i;
const STOP_RE = /^(stop|cancel|stop it|cancel it|abort)[.! ]*$/i;
const NAME_OF = { 'ai-daytrading-bot': 'trading', 'retro-game-platform': 'retro', 'the-crease': 'crease', 'x3-discord-admin-ai': 'x3', 'lax-sixes': 'sixes' };
const pendingAsk = new Map(); // channel -> request waiting for "which project?"

function latestTask(channel, statuses, maxAgeMs = 6 * 3600 * 1000) {
  return Object.values(state.tasks).filter(t => t.channel === channel && statuses.includes(t.status) && Date.now() - Date.parse(t.created) < maxAgeMs)
    .sort((a, b) => b.n - a.n)[0] || null;
}

async function classify(text, cfg, history, focus, lastPlan) {
  const recent = (history || []).slice(-6).map(m => `${m.role === 'user' ? 'Owner' : 'Jarvis'}: ${short(m.content, 300)}`).join('\n');
  const sys = [
    'You route messages for Jarvis, the owner\'s hub assistant. Do not answer the message; only classify it.',
    'Projects: trading (AI trading desk: paper trading, market map, Alpaca), retro (Rewind Arcade, the retro/indie browser game platform and store),',
    'crease (The Crease lacrosse highlight video engine), x3 (X3 gym Discord admin bot), sixes (Sixes lacrosse video game in Unreal Engine).',
    'intent "work": the owner wants something done or decided in a project: build, add, fix, change, test, review, clean up, continue, "what\'s next", "keep going", "take a look and see what to do".',
    'intent "look": a question that needs reading a project\'s files or history to answer (how does X work, where is Y, what changed, what is the status of this project), with no request to change anything.',
    'intent "chat": anything else: general questions, greetings, opinions, questions about the hub machines, or announcing a topic with no request yet (e.g. "I want to work on retro" alone is chat, but it still names the project).',
    'project: the project it is about, using the conversation and the current focus for words like "it", "the project", "this"; "none" if unclear.',
    'revise: true only if the owner is changing or adding to the plan Jarvis just proposed instead of asking for something new.',
    'request: the owner\'s request restated as one self-contained sentence (resolve "it"/"that" from the conversation).',
    'Answer JSON only: {"intent":"work|look|chat","project":"trading|retro|crease|x3|sixes|none","revise":false,"request":"..."}',
  ].join('\n');
  const user = [`Current focus project: ${focus ? NAME_OF[focus] : 'none'}`,
    lastPlan ? `Plan Jarvis proposed most recently (${lastPlan.id}, ${NAME_OF[lastPlan.repo]}): ${short(lastPlan.plan, 500)}` : '',
    recent ? `Recent conversation:\n${recent}` : '', `New message: ${text}`].filter(Boolean).join('\n\n');
  const res = await fetch((cfg.OLLAMA_URL || 'http://127.0.0.1:11434') + '/api/chat', { method: 'POST', headers: { 'Content-Type': 'application/json' }, signal: AbortSignal.timeout(120000),
    body: JSON.stringify({ model: cfg.OLLAMA_MODEL || 'qwen3:30b', stream: false, think: false, format: 'json', options: { temperature: 0, num_ctx: 8192 },
      messages: [{ role: 'system', content: sys }, { role: 'user', content: user }] }) });
  if (!res.ok) throw new Error(`Ollama answered HTTP ${res.status}`);
  const j = JSON.parse((await res.json()).message.content);
  return { intent: ['work', 'look', 'chat'].includes(j.intent) ? j.intent : 'chat', project: PROJECTS[j.project] ? j.project : null,
    revise: j.revise === true, request: String(j.request || text).trim() || text };
}

// Returns true when the message was handled here (an agent task was started, approved, stopped or queued);
// false means it is ordinary conversation for the local model.
async function converse(text, author, cfg, reply, ctx = {}) {
  const channel = ctx.channel || 'dm';
  const t0 = text.trim();
  state.focus = state.focus || {};

  if (APPROVE_RE.test(t0)) {
    const t = latestTask(channel, ['planned']);
    if (!t) return false;
    return handle(`approve ${t.id}`, author, cfg, reply, ctx).then(() => true);
  }
  // "Go, and then ..." / "yes and also ...": approve the plan on the table first, then treat the rest as the next request
  // (it waits in line behind the approved work).
  const lead = /^(yes|yeah|yep|go|go ahead|do it|approve|approved|ok go|sounds good|lgtm)\b[\s,.!;:-]*(?:and|then|and then|also|after that|plus)\b[\s,]*(.+)$/is.exec(t0);
  if (lead) {
    const t = latestTask(channel, ['planned']);
    if (t) {
      const approved = handle(`approve ${t.id}`, author, cfg, reply, ctx); // starts now; the rest queues behind it
      await converse(lead[2], author, cfg, reply, { ...ctx, history: [...(ctx.history || []), { role: 'assistant', content: `Approved ${t.id}: ${short(t.plan, 400)}` }] });
      await approved;
      return true;
    }
  }
  if (STOP_RE.test(t0) && busy()) {
    if (running) { running.child.kill('SIGTERM'); await reply(`Stopping ${running.id}.`); }
    else await reply(`${busy()} is between steps; send \`tasks\` to see it.`);
    return true;
  }

  // Answer to "which project?"
  const waiting = pendingAsk.get(channel);
  if (waiting && PROJECTS[t0.toLowerCase()]) {
    pendingAsk.delete(channel);
    await handle(`${waiting.kind} ${t0.toLowerCase()} ${waiting.request}`, author, cfg, reply, ctx);
    return true;
  }

  // Cheap pre-check: is a project word in the message? Then it can set the focus even for chat.
  const words = t0.toLowerCase().match(/[a-z0-9-]+/g) || [];
  const named = words.map(w => PROJECTS[w]).find(Boolean);
  const focus = named || state.focus[channel] || null;
  const lastPlan = latestTask(channel, ['planned'], 2 * 3600 * 1000);
  let c;
  try { c = await classify(t0, cfg, ctx.history, focus, lastPlan); } catch (e) { console.error('classify failed:', e.message); return false; }
  const repo = PROJECTS[c.project] || focus;
  if (repo) { state.focus[channel] = repo; save(); }
  if (c.intent === 'chat') return false;

  if (!repo) {
    pendingAsk.set(channel, { kind: c.intent === 'look' ? 'look' : 'plan', request: c.request });
    await reply(`Which project is that for? Reply with one word: ${PROJECT_LIST.replace(/\|/g, ', ')}.`);
    return true;
  }
  const word = NAME_OF[repo];
  if (c.intent === 'work' && c.revise && lastPlan && lastPlan.repo === repo) {
    lastPlan.status = 'superseded'; save();
    await reply(`Revising ${lastPlan.id} (${word}) with that change.`);
    await handle(`plan ${word} ${lastPlan.request}. Revise the earlier plan below with this change from the owner: ${c.request}\nEarlier plan:\n${lastPlan.plan}`, author, cfg, reply, ctx);
    return true;
  }
  await reply(c.intent === 'look' ? `On it: looking into **${word}** (read-only).` : `On it: **${word}**. I'll read the project and bring back a plan; nothing changes until you say go.`);
  await handle(`${c.intent === 'look' ? 'look' : 'plan'} ${word} ${c.request}`, author, cfg, reply, ctx);
  return true;
}

function focusOf(channel) { return (state.focus || {})[channel || 'dm'] || null; }

// Nightly backup of the Sixes working folder (non-destructive; skipped quietly if the PA PC is off).
async function nightlySixesCheckpoint(cfg) {
  if (busy()) return null;
  try { return await runProc('/usr/bin/ssh', cfg, HOME, sshArgs(machineFor('lax-sixes', cfg), 'checkpoint T0 lax-sixes -'), 10 * 60000, 'sixes-nightly', 'the PA PC worker', ''); }
  catch (e) { return `Nightly Sixes backup skipped: ${e.message.slice(0, 200)}`; }
}

module.exports = { handle, converse, focusOf, USAGE, interruptedAtStart, nightlySixesCheckpoint, _test: { APPROVE_RE, PROJECTS, exclusive },
  isTaskCommand: t => new RegExp(`^look\\s+(${Object.keys(PROJECTS).join('|')})\\b`, 'i').test(t.trim()) || /^(plan|approve|cancel|discard|tasks|agents)\b|^work\s+on\b|^(build|push|checkpoint)\s+sixes$|^sixes\s+status$|^confirm\s+(build|push)$/i.test(t.trim()) };
