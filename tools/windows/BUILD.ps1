$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $Root
if (-not (Get-Command zig -ErrorAction SilentlyContinue)) {
    Write-Error "zig not on PATH. Install from https://ziglang.org/download/ and reopen the terminal."
}
$Amalgam = Join-Path $Root "third_party\sqlite\sqlite3.c"
if (-not (Test-Path $Amalgam)) {
    & (Join-Path $PSScriptRoot "fetch_sqlite.ps1")
}
zig build -Dbundle-sqlite=true -Doptimize=ReleaseSafe
Write-Host "built $($Root)\zig-out\bin\zig-mdm.exe"
