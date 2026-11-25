# Jarvis worker on the PA PC. The ONLY thing Jarvis's SSH key can run here (forced command in
# C:\ProgramData\ssh\administrators_authorized_keys). Installed to C:\ProgramData\jarvis-worker\ (admin-owned).
#   plan <Tn> <repo> <claude|codex>     read-only plan in a throwaway copy of the latest origin branch
#   do <Tn> <repo> <claude|codex>       carry out an approved plan in G:\AI-Projects\_jarvis-work\<Tn>, branch jarvis/<Tn>
#   discard <Tn> <repo> -               remove that copy and branch
# The prompt arrives on stdin. Never pushes, never touches the owner's own working copy, never runs builds,
# the Unreal editor, UAT/UBT or cooking (builds are the owner's, after review).
# 'Continue' on purpose: Windows PowerShell turns any stderr line from git/claude into a terminating error under 'Stop'
# (git prints progress there even on success). Failures are checked explicitly through exit codes instead.
$ErrorActionPreference = 'Continue'
$OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$Repos = @{ 'lax-sixes' = 'G:\AI-Projects\lax-sixes' }
$WorkRoot = 'G:\AI-Projects\_jarvis-work'
$Log = Join-Path $WorkRoot 'worker.log'
New-Item -ItemType Directory -Force $WorkRoot | Out-Null
function Note($m) { Add-Content -Path $Log -Value ("{0} {1}" -f (Get-Date -Format s), $m) }
function Fail($m) { Note "REFUSED/FAILED: $m"; [Console]::Error.WriteLine($m); exit 2 }

$cmd = "$env:SSH_ORIGINAL_COMMAND".Trim()
if ($cmd -notmatch '^(plan|do|discard) (T\d{1,5}) ([a-z0-9-]{1,40}) (claude|codex|-)$') { Fail "Not an allowed worker command: '$cmd'" }
$action, $id, $repoName, $agent = $Matches[1], $Matches[2], $Matches[3], $Matches[4]
if (-not $Repos.ContainsKey($repoName)) { Fail "Unknown project '$repoName' on this machine" }
$repo = $Repos[$repoName]
$wt = Join-Path $WorkRoot $id
$branch = "jarvis/$id"
Note "$action $id $repoName $agent"
function RunGit { $out = & git.exe -C $repo @args 2>&1; if ($LASTEXITCODE -ne 0) { throw "git $($args -join ' '): $out" }; $out }
function RemoveCopy($path, $br) {
  if (Test-Path $path) { & git.exe -C $repo worktree remove --force $path 2>&1 | Out-Null }
  & git.exe -C $repo worktree prune 2>&1 | Out-Null
  if ($br) { & git.exe -C $repo branch -D $br 2>&1 | Out-Null }
}

if ($action -eq 'discard') { RemoveCopy $wt $branch; Write-Output "Discarded $id on the PA PC."; exit 0 }

$prompt = [Console]::In.ReadToEnd()
if (-not $prompt.Trim()) { Fail 'No prompt on stdin' }
# Work from the latest GitHub version of the branch the owner is on; the owner's own folder and edits are untouched.
RunGit fetch --quiet origin | Out-Null
$base = (RunGit rev-parse --abbrev-ref HEAD).Trim()
$baseRef = "origin/$base"
& git.exe -C $repo rev-parse --verify --quiet $baseRef | Out-Null; if ($LASTEXITCODE -ne 0) { $baseRef = 'origin/HEAD' }

$readTools = @('Read', 'Glob', 'Grep')
# Only the git commands in $doTools are allowed at all; everything else (builds, the editor, shells) is refused
# because Claude Code in -p mode denies any tool that isn't on the allowed list. These are blocked explicitly too.
$blocked = @('Bash(git push:*)', 'Bash(git remote:*)', 'Bash(curl:*)', 'Bash(wget:*)', 'Bash(rm -rf:*)', 'Bash(msbuild:*)', 'Bash(powershell:*)', 'Bash(cmd:*)', 'WebFetch', 'WebSearch')
$doTools = $readTools + @('Edit', 'Write', 'Bash(git status:*)', 'Bash(git diff:*)', 'Bash(git log:*)', 'Bash(git add:*)', 'Bash(git commit:*)')

function RunAgent($dir, $write) {
  Push-Location $dir
  try {
    if ($agent -eq 'codex') {
      $outFile = Join-Path $env:TEMP "jarvis-codex-$id-$([guid]::NewGuid().ToString('N')).txt"
      $sandbox = if ($write) { 'workspace-write' } else { 'read-only' }
      $res = $prompt | & codex.cmd exec --skip-git-repo-check -s $sandbox -o $outFile - 2>&1
      $code = $LASTEXITCODE
      $last = if (Test-Path $outFile) { Get-Content $outFile -Raw; Remove-Item $outFile -Force } else { '' }
      if ($code -ne 0) { [Console]::Error.WriteLine(($res | Out-String)); exit 3 }
      if ($last) { return $last } else { return ($res | Out-String) }
    }
    $args2 = if ($write) { @('-p', '--permission-mode', 'acceptEdits', '--allowedTools') + $doTools + @('--disallowedTools') + $blocked }
             else { @('-p', '--permission-mode', 'default', '--allowedTools') + $readTools + @('--disallowedTools', 'Edit', 'Write', 'NotebookEdit', 'Bash') + $blocked }
    $res = $prompt | & claude.cmd @args2 --output-format text 2>&1
    if ($LASTEXITCODE -ne 0) { [Console]::Error.WriteLine(($res | Out-String)); exit 3 }
    return ($res | Out-String)
  } finally { Pop-Location }
}

if ($action -eq 'plan') {
  $tmp = Join-Path $WorkRoot "$id-plan"
  RemoveCopy $tmp $null
  RunGit worktree add --detach $tmp $baseRef | Out-Null
  try { Write-Output (RunAgent $tmp $false) } finally { RemoveCopy $tmp $null }
  exit 0
}

# do: a fresh copy on branch jarvis/<Tn> from the latest origin branch
RemoveCopy $wt $branch
RunGit worktree add -b $branch $wt $baseRef | Out-Null
$baseSha = (RunGit rev-parse $baseRef).Trim()
$summary = RunAgent $wt $true
$dirty = & git.exe -C $wt status --porcelain
if ($dirty) {
  & git.exe -C $wt add -A | Out-Null
  & git.exe -C $wt -c user.name=Jarvis -c user.email=jarvis@localhost commit -q -m "Jarvis ${id}: approved plan (agent: $agent)" | Out-Null
}
# never let local Visual Studio files ride along
$vs = & git.exe -C $wt diff --name-only "$baseSha..HEAD" | Where-Object { $_ -match '\.(vsconfig|slnx)$' }
if ($vs) { Write-Output "WARNING: these local Visual Studio files are in the commits and must be removed before pushing: $($vs -join ', ')" }
Write-Output $summary
Write-Output '```'
& git.exe -C $wt log --oneline "$baseSha..HEAD"
& git.exe -C $wt diff --stat "$baseSha..HEAD" | Select-Object -Last 12
Write-Output '```'
Write-Output "Base: $baseRef ($($baseSha.Substring(0,7))). Branch $branch is in $repo (copy at $wt)."
Note "done $id"
exit 0
