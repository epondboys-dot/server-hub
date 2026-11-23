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
};

const TRADING_RULES = 'This is the Trading Desk repository. Follow AGENTS.md and docs/OWNER_DECISIONS.md strictly. ' +
  'Never start, stop or move the desk; never touch a runtime folder, HARD_OFF.json or owner runtime files; ' +
  'never add order execution, live trading or a funded account; never put credentials anywhere.';

const CREASE_NOTE = 'This is The Crease. Run its checks with crease-test (tests), crease-test lint and crease-test types; ' +
  'they use the shared Python 3.12 environment. It is not deployed: never contact live services or add credentials.';

const RETRO_NOTE = 'This is Rewind Arcade. Run its checks with retro-test (unit), retro-test build and retro-test browser. ' +
  'Never deploy, never run the Deploy/Publish/Enable/Invite scripts, never contact the live store, Cloudflare or Supabase.';

const PLAN_TOOLS = ['Read', 'Glob', 'Grep'];
const PLAN_BLOCKED = ['Edit', 'Write', 'NotebookEdit', 'Bash'];
const DO_TOOLS = ['Read', 'Glob', 'Grep', 'Edit', 'Write',
  'Bash(git status:*)', 'Bash(git diff:*)', 'Bash(git log:*)', 'Bash(git add:*)', 'Bash(git commit:*)',
  'Bash(node --test:*)', 'Bash(node --check:*)', 'Bash(npm test:*)', 'Bash(npm run test:*)',
  'Bash(crease-test:*)', 'Bash(/Users/jarvis/bin/crease-test:*)', 'Bash(retro-test:*)', 'Bash(/Users/jarvis/bin/retro-test:*)'];
const BLOCKED = ['Bash(git push:*)', 'Bash(git remote:*)', 'Bash(curl:*)', 'Bash(wget:*)', 'Bash(rm -rf:*)',
  'Bash(sudo:*)', 'WebFetch', 'WebSearch'];

let state = { next: 1, tasks: {} };
try { state = JSON.parse(fs.readFileSync(STATE_FILE, 'utf8')); } catch {}
function save() {
  fs.mkdirSync(STATE_DIR, { recursive: true });
  fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
}

let running = null; // { id, child }

function git(cwd, args) {
  return execFileSync('git', ['-C', cwd, ...args], { encoding: 'utf8', timeout: 60000, stdio: ['ignore', 'pipe', 'pipe'] }).trim();
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

function runAgent(agent, cfg, cwd, prompt, write, timeoutMs, id) {
  if (agent === 'codex') return runCodex(cfg, cwd, prompt, write, timeoutMs, id);
  const args = write
    ? ['-p', prompt, '--permission-mode', 'acceptEdits', '--allowedTools', ...DO_TOOLS, '--disallowedTools', ...BLOCKED, '--output-format', 'text']
    : ['-p', prompt, '--permission-mode', 'default', '--allowedTools', ...PLAN_TOOLS, '--disallowedTools', ...PLAN_BLOCKED, ...BLOCKED, '--output-format', 'text'];
  return runClaude(cfg, cwd, args, timeoutMs, id);
}

function runProc(bin, cfg, cwd, args, timeoutMs, id, label) {
  return new Promise((resolve, reject) => {
    const env = { ...process.env, HOME, PATH: '/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin' };
    if (cfg.CLAUDE_CODE_OAUTH_TOKEN) env.CLAUDE_CODE_OAUTH_TOKEN = cfg.CLAUDE_CODE_OAUTH_TOKEN;
    const child = spawn(bin, args, { cwd, env, stdio: ['ignore', 'pipe', 'pipe'] });
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
  const dir = path.join(PROJECTS_DIR, repo);
  return fs.existsSync(path.join(dir, '.git')) ? { repo, dir } : null;
}

function short(s, n = 80) { s = String(s).replace(/\s+/g, ' ').trim(); return s.length > n ? s.slice(0, n - 1) + '…' : s; }

const USAGE = [
  '**Agent tasks** (Claude Code or Codex; nothing reaches GitHub without you)',
  '- `plan <project> <what you want>`: read-only; replies with a plan and a task id. Add `--codex` to use Codex instead of Claude Code',
  '- `approve <id>`: carry out that plan in a separate copy on branch `jarvis/<id>`; commits there, never pushes',
  '- `tasks`: recent tasks · `cancel <id>`: stop a running task · `discard <id>`: delete its copy and branch',
  `- Projects: trading, retro, crease`,
].join('\n');

async function handle(text, author, cfg, reply) {
  const [verb, ...rest] = text.trim().split(/\s+/);
  const v = verb.toLowerCase();

  if (v === 'tasks') {
    const list = Object.values(state.tasks).sort((a, b) => b.n - a.n).slice(0, 8);
    if (!list.length) return reply('No tasks yet.\n\n' + USAGE);
    return reply(list.map(t => `- **${t.id}** [${t.status}] ${t.agent || 'claude'} · ${t.repo}: ${short(t.request)}`).join('\n'));
  }

  if (v === 'plan') {
    let agent = 'claude';
    const words = rest.filter(w => {
      if (/^--?codex$/i.test(w)) { agent = 'codex'; return false; }
      if (/^--?claude$/i.test(w)) { agent = 'claude'; return false; }
      return true;
    });
    const proj = resolveProject(words[0]);
    const request = words.slice(1).join(' ').trim();
    if (!proj || !request) return reply('Usage: `plan <trading|retro|crease> <what you want>`');
    if (running) return reply(`Busy with ${running.id}. Try again when it finishes, or \`cancel ${running.id}\`.`);
    const n = state.next++;
    const id = `T${n}`;
    const t = state.tasks[id] = { id, n, agent, repo: proj.repo, request, author, status: 'planning', created: new Date().toISOString() };
    save();
    await reply(`**${id}** planning on ${proj.repo} with ${agent === 'codex' ? 'Codex' : 'Claude Code'} (read-only). This can take a few minutes.`);
    const prompt = [
      'You are planning a change for the owner, who will approve it from their phone.',
      'Read any AGENTS.md, CLAUDE.md and README first and follow their rules.',
      proj.repo === 'ai-daytrading-bot' ? TRADING_RULES : '',
      proj.repo === 'the-crease' ? CREASE_NOTE : '',
      proj.repo === 'retro-game-platform' ? RETRO_NOTE : '',
      'Do not change anything. Reply with: a one-line summary; numbered steps; the files you would change;',
      'the tests you would run; and any risks or questions. Keep it under 300 words, plain text.',
      `Request: ${request}`,
    ].filter(Boolean).join('\n');
    try {
      t.plan = await runAgent(agent, cfg, proj.dir, prompt, false, 10 * 60 * 1000, id);
      t.status = 'planned';
      save();
      return reply(`**${id} plan** (${proj.repo}, ${agent === 'codex' ? 'Codex' : 'Claude Code'})\n${t.plan}\n\nTo carry it out: \`approve ${id}\`. Nothing changes until then.`);
    } catch (e) {
      t.status = 'failed'; t.error = e.message; save();
      return reply(`**${id}** planning failed: ${e.message}`);
    }
  }

  if (v === 'approve') {
    const t = state.tasks[String(rest[0] || '').toUpperCase()];
    if (!t) return reply('Usage: `approve <id>` (see `tasks`)');
    if (t.status !== 'planned') return reply(`${t.id} is ${t.status}; only a planned task can be approved.`);
    if (running) return reply(`Busy with ${running.id}. Try again when it finishes.`);
    const src = path.join(PROJECTS_DIR, t.repo);
    const wt = path.join(WORK_DIR, t.id);
    const branch = `jarvis/${t.id}`;
    t.status = 'working'; t.approvedBy = author; t.approved = new Date().toISOString(); save();
    await reply(`**${t.id}** approved. Working in a separate copy on branch \`${branch}\`. This can take a while.`);
    try {
      fs.mkdirSync(WORK_DIR, { recursive: true });
      t.base = git(src, ['rev-parse', 'HEAD']);
      git(src, ['worktree', 'add', '-b', branch, wt, t.base]);
      const prompt = [
        'Carry out this plan, which the owner has approved. Stay within it; if something outside it is needed, stop and explain.',
        'Read any AGENTS.md, CLAUDE.md and README first and follow their rules, including their test and versioning steps.',
        t.repo === 'ai-daytrading-bot' ? TRADING_RULES : '',
        t.repo === 'the-crease' ? CREASE_NOTE : '',
        t.repo === 'retro-game-platform' ? RETRO_NOTE : '',
        'Run the project\'s tests if it has them. Commit your work to the current branch with a clear message if you can; if not, leave the changes and Jarvis will commit them. Never push or change git remotes.',
        'Finish with a short plain-text summary: what changed, test results, anything the owner should check.',
        `Original request: ${t.request}`,
        `Approved plan:\n${t.plan}`,
      ].filter(Boolean).join('\n');
      t.summary = await runAgent(t.agent || 'claude', cfg, wt, prompt, true, 30 * 60 * 1000, t.id);
      if (git(wt, ['status', '--porcelain'])) {
        git(wt, ['add', '-A']);
        git(wt, ['-c', 'user.name=Jarvis', '-c', 'user.email=jarvis@localhost', 'commit', '-q', '-m', `Jarvis ${t.id}: ${short(t.request, 60)}`]);
      }
      const log = git(wt, ['log', '--oneline', `${t.base}..HEAD`]) || '(no commits)';
      const stat = git(wt, ['diff', '--stat', `${t.base}..HEAD`]) || '(no file changes)';
      t.status = 'done'; t.finished = new Date().toISOString(); save();
      return reply([
        `**${t.id} done** (${t.repo}, branch \`${branch}\`)`, t.summary, '',
        '```', log, stat.split('\n').slice(-12).join('\n'), '```',
        'Review and push it yourself from a PC:',
        '```', `git fetch epondboys@10.10.10.240:/Users/jarvis/work/${t.id} ${branch}:${branch}`, `git log -p ${t.base.slice(0, 7)}..${branch}`, `git push origin ${branch}`, '```',
        `Or \`discard ${t.id}\` to throw it away.`,
      ].join('\n'));
    } catch (e) {
      t.status = 'failed'; t.error = e.message; save();
      return reply(`**${t.id}** stopped: ${e.message}\nThe copy is kept at ~/work/${t.id}; \`discard ${t.id}\` removes it.`);
    }
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
    const src = path.join(PROJECTS_DIR, t.repo);
    try { git(src, ['worktree', 'remove', '--force', path.join(WORK_DIR, t.id)]); } catch {}
    try { git(src, ['branch', '-D', `jarvis/${t.id}`]); } catch {}
    t.status = 'discarded'; save();
    return reply(`${t.id} discarded.`);
  }

  return null; // not a task command
}

module.exports = { handle, USAGE, isTaskCommand: t => /^(plan|approve|cancel|discard|tasks)\b/i.test(t.trim()) };
