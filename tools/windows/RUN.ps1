$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $Root
New-Item -ItemType Directory -Force -Path (Join-Path $Root "data") | Out-Null
$Exe = Join-Path $Root "zig-out\bin\zig-mdm.exe"
if (-not (Test-Path $Exe)) {
    Write-Error "No zig-mdm.exe — run tools\windows\BUILD.ps1"
}
Write-Host "MagiMDM Windows  http://127.0.0.1:8787/login"
Write-Host "Working directory $Root  (data\mdm.db stays here)"
& $Exe
