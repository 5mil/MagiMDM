# Download SQLite amalgamation into third_party/sqlite
$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$Dest = Join-Path $Root "third_party\sqlite"
New-Item -ItemType Directory -Force -Path $Dest | Out-Null
$Year = "2025"
$Ver = "35004000"
$Url = "https://www.sqlite.org/$Year/sqlite-amalgamation-$Ver.zip"
$Zip = Join-Path $Dest "sqlite.zip"
Write-Host "GET $Url"
Invoke-WebRequest -Uri $Url -OutFile $Zip
Expand-Archive -Path $Zip -DestinationPath $Dest -Force
$Inner = Get-ChildItem $Dest -Directory | Where-Object { $_.Name -like "sqlite-amalgamation-*" } | Select-Object -First 1
if (-not $Inner) { throw "amalgamation folder missing" }
Copy-Item (Join-Path $Inner.FullName "sqlite3.c") (Join-Path $Dest "sqlite3.c") -Force
Copy-Item (Join-Path $Inner.FullName "sqlite3.h") (Join-Path $Dest "sqlite3.h") -Force
Remove-Item $Zip -Force
Write-Host "ok $($Dest)\sqlite3.c"
