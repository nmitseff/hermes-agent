# Does Windows PowerShell 5.1 Move-Item leave a PARTIAL tree when a file in
# the source directory is held open (AV scan / lingering post-install child)?
# Same-volume and cross-volume legs.
param([string]$DestRoot)
$ErrorActionPreference = 'Continue'
$src = Join-Path $env:TEMP ("mv-src-" + [guid]::NewGuid().ToString('N'))
foreach ($rel in 'cmd\git.exe', 'etc\hosts', 'mingw64\libexec\git-core\git-remote-http.exe',
                 'mingw64\libexec\git-core\git-remote-https.exe', 'usr\bin\bash.exe') {
    $p = Join-Path $src $rel
    New-Item -ItemType Directory -Force (Split-Path $p) | Out-Null
    [IO.File]::WriteAllText($p, 'x')
}
$dest = Join-Path $DestRoot ("mv-dest-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force $DestRoot | Out-Null
$held = Join-Path $src 'mingw64\libexec\git-core\git-remote-https.exe'
$h = [IO.File]::Open($held, 'Open', 'Read', 'Read')   # no FILE_SHARE_DELETE, like an AV scan
$err = ''
try { Move-Item -LiteralPath $src -Destination $dest -ErrorAction Stop } catch { $err = $_.Exception.Message }
$h.Close()
$r = [ordered]@{
    src_vol = (Split-Path -Qualifier $src); dest_vol = (Split-Path -Qualifier $dest)
    error = $err
    dest_git = (Test-Path (Join-Path $dest 'cmd\git.exe'))
    dest_https = (Test-Path (Join-Path $dest 'mingw64\libexec\git-core\git-remote-https.exe'))
    src_left = (Test-Path $src)
}
"RESULT move " + ($r | ConvertTo-Json -Compress)
