# Jarvis worker on the PA PC (v3, Nov 25, 2026). The ONLY thing Jarvis's SSH key can run here (forced command in
# C:\ProgramData\ssh\administrators_authorized_keys). Installed to C:\ProgramData\jarvis-worker\ (admin-owned).
# Owner decision (Nov 25): agents work in the Sixes working folder itself, and the PC can build and push, as automated
# as possible, with the owner confirming builds and pushes from Discord.
#   <action> <Tn> <repo> <agent>, prompt on stdin for plan/do:
#   plan       read-only plan against the working folder as it is now (uncommitted work included)
#   do         checkpoint "before", the agent edits the working folder, checkpoint "after"
#   checkpoint back up the working folder (committed + uncommitted, minus .vsconfig/.slnx) to a new GitHub branch
#              checkpoint/pa-<time>, WITHOUT changing the folder, the index or the current branch
#   build      the project's Build_DevelopmentEditor.bat (Jarvis asks the owner to confirm first)
#   push       push the current branch to GitHub; never force, so it refuses if GitHub has newer work
#   status     branch, ahead/behind, changed files, last checkpoint
#   discard    remove an old v1 task copy (G:\AI-Projects\_jarvis-work\<Tn>)
#   selfupdate replace this script with pa-pc-worker/jarvis-worker.ps1 from server-hub main ON GITHUB (fetched here with
#              this PC's own GitHub sign-in, never sent by Jarvis), after a syntax check; the old copy is kept as .prev
#   tools      update Claude Code and Codex on this PC
# 'Continue' on purpose: Windows PowerShell turns any stderr line from git/claude into a terminating error under
# 'Stop' (git prints progress there even on success). Failures are checked through exit codes instead.
$ErrorActionPreference = 'Continue'
# GitHub sign-in: over SSH, Windows cannot open the owner's saved GitHub login (Credential Manager needs a desktop
# sign-in), so the worker uses its own fine-grained token (lax-sixes read/write, server-hub read only), kept in an
# admin-only file by setup-pa-pc-worker.ps1. The owner's own Git on the desktop is untouched.
$env:GCM_INTERACTIVE = 'never'; $env:GIT_TERMINAL_PROMPT = '0'
# (Passed on every git call: an empty helper drops the desktop-only one, then the worker's own file is used.
#  PowerShell deletes environment variables set to '', so this cannot go through GIT_CONFIG_* variables.)
$GitAuth = if (Test-Path 'C:\ProgramData\jarvis-worker\git-credentials') {
  @('-c', 'credential.helper=', '-c', 'credential.helper=store --file=C:/ProgramData/jarvis-worker/git-credentials')
} else { @() }
$OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$Repos = @{
  'lax-sixes'  = @{ Path = 'G:\AI-Projects\lax-sixes'; Build = 'Lax Video Game\Build_DevelopmentEditor.bat'; Exclude = @(':(exclude,glob)**/.vsconfig', ':(exclude,glob)**/*.slnx') }
  # The Crease (owner, Nov 27): its working folder here; `build` runs its test suite in the folder's own Python environment.
  'the-crease' = @{ Path = 'G:\AI-Projects\content-engine-the-crease'; Test = '.venv\Scripts\python.exe'; TestArgs = @('-m', 'pytest', '-q', '-x', '--no-header'); Exclude = @() }
}
$WorkRoot = 'G:\AI-Projects\_jarvis-work'
$Log = Join-Path $WorkRoot 'worker.log'
New-Item -ItemType Directory -Force $WorkRoot | Out-Null
function Note($m) { Add-Content -Path $Log -Value ("{0} {1}" -f (Get-Date -Format s), $m) }
function Fail($m, $code = 2) { Note "FAILED: $m"; [Console]::Error.WriteLine($m); exit $code }

$cmd = "$env:SSH_ORIGINAL_COMMAND".Trim()
if ($cmd -notmatch '^(plan|do|checkpoint|build|push|status|discard|selfupdate|tools) (T\d{1,5}) ([a-z0-9-]{1,40}) (claude|codex|-)$') { Fail "Not an allowed worker command: '$cmd'" }
$action, $id, $repoName, $agent = $Matches[1], $Matches[2], $Matches[3], $Matches[4]
if (-not $Repos.ContainsKey($repoName)) { Fail "Unknown project '$repoName' on this machine" }
$P = $Repos[$repoName]; $repo = $P.Path
Note "$action $id $repoName $agent"
function G { $out = & git.exe @GitAuth -C $repo @args 2>&1; if ($LASTEXITCODE -ne 0) { throw "git $($args -join ' '): $($out -join ' ')" }; $out }

# Back up everything in the working folder to a new branch without touching the folder, index or branch:
# a private index starts from HEAD, takes every change (respecting .gitignore, minus local VS files), becomes a
# commit whose parent is HEAD, and only that commit is pushed under refs/heads/checkpoint/...
function Checkpoint($label) {
  $tmpIndex = Join-Path $env:TEMP "jarvis-index-$([guid]::NewGuid().ToString('N'))"
  $env:GIT_INDEX_FILE = $tmpIndex
  try {
    G read-tree HEAD | Out-Null
    G add -A -- . @($P.Exclude) | Out-Null
    $tree = (G write-tree | Select-Object -Last 1).Trim()
  } finally { Remove-Item Env:GIT_INDEX_FILE; Remove-Item $tmpIndex -Force -ErrorAction SilentlyContinue }
  $head = (G rev-parse HEAD | Select-Object -Last 1).Trim()
  $branch = (G rev-parse --abbrev-ref HEAD | Select-Object -Last 1).Trim()
  $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
  $msg = "PA rig checkpoint ($label) $stamp on $branch @ $($head.Substring(0,7)); working folder unchanged"
  $commit = (G -c user.name=Jarvis -c user.email=jarvis@localhost commit-tree $tree -p $head -m $msg | Select-Object -Last 1).Trim()
  $ref = "checkpoint/pa-$stamp"
  G push --quiet origin "${commit}:refs/heads/$ref" | Out-Null
  Note "checkpoint $ref $commit ($label)"
  return [pscustomobject]@{ Ref = $ref; Commit = $commit; Tree = $tree }
}

switch ($action) {
  'selfupdate' {
    $env:GCM_INTERACTIVE = 'never'; $env:GIT_TERMINAL_PROMPT = '0'
    $src = 'C:\ProgramData\jarvis-worker\src'
    if (-not (Test-Path "$src\.git")) { $o = & git.exe @GitAuth clone -q --depth 1 https://github.com/epondboys-dot/server-hub.git $src 2>&1 }
    else { $o = & git.exe @GitAuth -C $src fetch -q --depth 1 origin main 2>&1; if ($LASTEXITCODE -eq 0) { $o = & git.exe @GitAuth -C $src reset -q --hard FETCH_HEAD 2>&1 } }
    if ($LASTEXITCODE -ne 0) { Fail "Couldn't get server-hub from GitHub on this PC: $($o -join ' ')" }
    $new = Join-Path $src 'pa-pc-worker\jarvis-worker.ps1'; $rev = (& git.exe @GitAuth -C $src rev-parse --short HEAD)
    if (-not (Test-Path $new)) { Fail "server-hub $rev has no pa-pc-worker\jarvis-worker.ps1" }
    $errs = $null; [void][System.Management.Automation.Language.Parser]::ParseFile($new, [ref]$null, [ref]$errs)
    if ($errs -and $errs.Count) { Fail "server-hub $rev worker has syntax errors; kept the current one: $($errs[0].Message)" }
    $self = $PSCommandPath
    $norm = { param($f) ((Get-Content -Raw $f) -replace "`r`n", "`n").Trim() }
    if ((& $norm $new) -eq (& $norm $self)) { Write-Output "PA PC worker already current (server-hub $rev)."; exit 0 }
    Copy-Item $self "$self.prev" -Force; Copy-Item $new $self -Force
    Note "selfupdate to server-hub $rev"
    Write-Output "PA PC worker updated to server-hub $rev (previous copy kept as jarvis-worker.ps1.prev)."; exit 0
  }
  'tools' {
    $msgs = @()
    if (Get-Command claude -ErrorAction SilentlyContinue) { $o = & claude update 2>&1; $msgs += "Claude Code: $((($o | Select-Object -Last 1) -as [string]).Trim())" }
    if (Get-Command codex.cmd -ErrorAction SilentlyContinue) { $o = & npm.cmd install -g --silent '@openai/codex@latest' 2>&1; $msgs += "Codex: $((& codex.cmd --version 2>&1 | Select-Object -Last 1))" }
    Write-Output ("PA PC tools: " + ($msgs -join '; ')); exit 0
  }
  'status' {
    G fetch --quiet origin | Out-Null
    $b = (G rev-parse --abbrev-ref HEAD | Select-Object -Last 1).Trim()
    $ab = (G rev-list --left-right --count "HEAD...origin/$b" | Select-Object -Last 1).Trim() -split '\s+'
    $changed = @(& git.exe @GitAuth -C $repo status --porcelain).Count
    $last = (& git.exe @GitAuth -C $repo ls-remote --heads origin 'checkpoint/pa-*' | ForEach-Object { ($_ -split "`t")[1] -replace '^refs/heads/', '' } | Sort-Object | Select-Object -Last 1)
    Write-Output "$(@{ 'lax-sixes' = 'Sixes'; 'the-crease' = 'The Crease' }[$repoName]) on the PA PC: branch $b, $($ab[0]) ahead / $($ab[1]) behind GitHub, $changed changed or new files. Last checkpoint: $(if ($last) { $last } else { 'none yet' })."
    exit 0
  }
  'checkpoint' { $c = Checkpoint 'requested'; Write-Output "Backed up to GitHub branch $($c.Ref) ($($c.Commit.Substring(0,7))). The working folder was not changed."; exit 0 }
  'push' {
    $b = (G rev-parse --abbrev-ref HEAD | Select-Object -Last 1).Trim()
    if ($b -notmatch '^[A-Za-z0-9._/-]+$' -or $b -eq 'HEAD') { Fail "Not on a named branch ($b); nothing pushed." }
    $out = & git.exe @GitAuth -C $repo push origin "HEAD:refs/heads/$b" 2>&1   # never --force
    if ($LASTEXITCODE -ne 0) { Fail "Push refused (nothing overwritten). GitHub likely has newer commits on $b; sync the rigs first.`n$($out -join "`n")" 4 }
    Write-Output "Pushed $b to GitHub (fast-forward only). Uncommitted changes are not part of a push; checkpoints back those up."
    exit 0
  }
  'build' {
    if ($P.Test) {   # projects without a compile step: run the test suite
      $py = Join-Path $repo $P.Test
      if (-not (Test-Path $py)) { Fail "Test runner not found: $py" }
      $logFile = Join-Path $WorkRoot ("test-{0}-{1}.log" -f $repoName, (Get-Date -Format 'yyyyMMdd-HHmmss'))
      $start = Get-Date
      Push-Location $repo; & $py @($P.TestArgs) *> $logFile; $code = $LASTEXITCODE; Pop-Location
      $mins = [math]::Round(((Get-Date) - $start).TotalMinutes, 1)
      $tail = Get-Content $logFile -Tail 15 | Where-Object { $_.Trim() }
      Note "test $repoName exit $code in $mins min ($logFile)"
      if ($code -ne 0) { Write-Output "TESTS FAILED after $mins min. Log: $logFile"; $tail | Select-Object -Last 12; exit 5 }
      Write-Output "TESTS PASSED in $mins min. Log: $logFile"; $tail | Select-Object -Last 2
      exit 0
    }
    $bat = Join-Path $repo $P.Build
    if (-not (Test-Path $bat)) { Fail "Build script not found: $bat" }
    $logFile = Join-Path $WorkRoot ("build-{0}-{1}.log" -f $id, (Get-Date -Format 'yyyyMMdd-HHmmss'))
    $start = Get-Date
    & cmd.exe /c "`"$bat`"" *> $logFile
    $code = $LASTEXITCODE; $mins = [math]::Round(((Get-Date) - $start).TotalMinutes, 1)
    $tail = Get-Content $logFile -Tail 25 | Where-Object { $_.Trim() }
    $errors = Select-String -Path $logFile -Pattern 'error [A-Z]+\d+|: error|Error:' | Select-Object -First 8 | ForEach-Object { $_.Line.Trim() }
    Note "build $id exit $code in $mins min ($logFile)"
    if ($code -ne 0) { Write-Output "BUILD FAILED after $mins min. Log: $logFile"; if ($errors) { $errors }; $tail | Select-Object -Last 10; exit 5 }
    Write-Output "BUILD SUCCEEDED in $mins min (SixesGameEditor, Win64 Development). Log: $logFile"; $tail | Select-Object -Last 4
    exit 0
  }
  'discard' {
    $wt = Join-Path $WorkRoot $id
    if (Test-Path $wt) { & git.exe @GitAuth -C $repo worktree remove --force $wt 2>&1 | Out-Null }
    & git.exe @GitAuth -C $repo worktree prune 2>&1 | Out-Null; & git.exe @GitAuth -C $repo branch -D "jarvis/$id" 2>&1 | Out-Null
    Write-Output "Removed any old copy for $id. The working folder was not changed."; exit 0
  }
}

# plan / do: the agent works on the working folder itself
$prompt = [Console]::In.ReadToEnd()
if (-not $prompt.Trim()) { Fail 'No prompt on stdin' }
$readTools = @('Read', 'Glob', 'Grep')
$blocked = @('Bash', 'WebFetch', 'WebSearch', 'NotebookEdit')   # no shell at all: building, pushing and git are the worker's job
function RunAgent($write) {
  Push-Location $repo
  try {
    if ($agent -eq 'codex') {
      $outFile = Join-Path $env:TEMP "jarvis-codex-$id-$([guid]::NewGuid().ToString('N')).txt"
      $res = $prompt | & codex.cmd exec --skip-git-repo-check -s $(if ($write) { 'workspace-write' } else { 'read-only' }) -o $outFile - 2>&1
      $code = $LASTEXITCODE
      $last = if (Test-Path $outFile) { Get-Content $outFile -Raw; Remove-Item $outFile -Force } else { '' }
      if ($code -ne 0) { [Console]::Error.WriteLine(($res | Out-String)); exit 3 }
      if ($last) { return $last } else { return ($res | Out-String) }
    }
    $tools = if ($write) { $readTools + @('Edit', 'Write') } else { $readTools }
    $deny = if ($write) { $blocked } else { $blocked + @('Edit', 'Write') }
    $res = $prompt | & claude.cmd -p --permission-mode $(if ($write) { 'acceptEdits' } else { 'default' }) --allowedTools @tools --disallowedTools @deny --output-format text 2>&1
    if ($LASTEXITCODE -ne 0) { [Console]::Error.WriteLine(($res | Out-String)); exit 3 }
    return ($res | Out-String)
  } finally { Pop-Location }
}

if ($action -eq 'plan') { Write-Output (RunAgent $false); exit 0 }

# do
$before = Checkpoint "before $id"
$summary = RunAgent $true
$after = Checkpoint "after $id"
Write-Output $summary
Write-Output '```'
& git.exe @GitAuth -C $repo diff --stat $before.Tree $after.Tree | Select-Object -Last 15
Write-Output '```'
if ($before.Tree -eq $after.Tree) { Write-Output 'No files changed.' }
Write-Output "Backups on GitHub: before = $($before.Ref), after = $($after.Ref). To undo this task: git restore --source $($before.Commit.Substring(0,10)) --worktree -- ."
Note "done $id"
exit 0
