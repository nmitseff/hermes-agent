# Real Get-PinnedGit from the given install.ps1 against a poisoned store
# entry (cmd\git.exe present, git-remote-https missing) - the reporter's state.
# Mode 'poisoned': plain poisoned tree.  Mode 'locked': poisoned tree with a
# file inside held open (no delete share) while Get-PinnedGit runs.
param([string]$Installer, [string]$Work, [string]$Mode)
$ErrorActionPreference = 'Continue'
. $Installer -HermesHome (Join-Path $Work 'home')
$env:HERMES_RUNTIME_DIR = Join-Path $Work 'tools'
$git = Get-PinnedGit
if (-not $git) { "RESULT pinned {`"stage`":`"first`",`"ok`":false}"; exit 1 }
$entry = Split-Path (Split-Path $git)
$helper = Join-Path $entry 'mingw64\libexec\git-core\git-remote-https.exe'
Remove-Item -LiteralPath $helper -Force
$h = $null
if ($Mode -eq 'locked') { $h = [IO.File]::Open((Join-Path $entry 'usr\bin\bash.exe'), 'Open', 'Read', 'Read') }
$err = ''
try { $again = Get-PinnedGit } catch { $err = $_.Exception.Message }
if ($h) { $h.Close() }
$clone = -1
if ($again -and (Test-Path -LiteralPath $again)) {
    $dst = Join-Path $Work ("clone-" + [guid]::NewGuid().ToString('N'))
    $p = Start-Process -FilePath $again -ArgumentList @('ls-remote', 'https://github.com/NousResearch/hermes-agent.git', 'HEAD') -NoNewWindow -PassThru -Wait `
        -RedirectStandardOutput "$dst.out" -RedirectStandardError "$dst.err"
    $clone = $p.ExitCode
    "ls-remote stderr: " + (Get-Content -Raw "$dst.err")
}
$r = [ordered]@{ mode = $Mode; returned = "$again"; error = $err; helper_back = (Test-Path -LiteralPath $helper); https_ls_remote_exit = $clone }
"RESULT pinned " + ($r | ConvertTo-Json -Compress)
