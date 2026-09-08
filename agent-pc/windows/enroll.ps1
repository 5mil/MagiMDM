# MagiMDM Windows first-boot enroll + poll stub.
# Called from Autounattend FirstLogonCommands as SYSTEM.
$ErrorActionPreference = 'Stop'
$Root = 'C:\ProgramData\ZigMDM'
New-Item -ItemType Directory -Force -Path $Root | Out-Null
$EnvFile = Join-Path $Root 'enroll.env'
if (Test-Path $EnvFile) {
  Get-Content $EnvFile | ForEach-Object {
    if ($_ -match '^\s*#' -or $_ -notmatch '=') { return }
    $k, $v = $_.Split('=', 2)
    Set-Item -Path "Env:$k" -Value $v.Trim()
  }
}
$Mdm = $env:MDM_URL
if (-not $Mdm) { $Mdm = 'http://127.0.0.1:8788' }
$Token = $env:TOKEN
$Slug = $env:IMAGE_SLUG
if (-not $Slug) { $Slug = 'windows11-student' }
$State = Join-Path $Root 'device.env'

function Enroll {
  $body = @{
    token = $Token
    name = $env:COMPUTERNAME
    platform = 'windows'
    os_version = [string][System.Environment]::OSVersion.Version
    agent_version = '0.1.0-windows'
    image_slug = $Slug
  } | ConvertTo-Json -Compress
  $resp = Invoke-RestMethod -Method Post -Uri "$Mdm/api/agent/enroll" -ContentType 'application/json' -Body $body
  "UUID=$($resp.uuid)" | Set-Content $State
}

function Poll {
  $uuid = (Get-Content $State | Where-Object { $_ -like 'UUID=*' }).Split('=')[1]
  $body = @{ uuid = $uuid; agent_version = '0.1.0-windows'; extras = @{ image = $Slug } } | ConvertTo-Json -Compress
  Invoke-RestMethod -Method Post -Uri "$Mdm/api/agent/poll" -ContentType 'application/json' -Body $body | Out-Null
}

if (-not (Test-Path $State)) { Enroll }
if (-not (Test-Path $State)) { exit 1 }
Poll
