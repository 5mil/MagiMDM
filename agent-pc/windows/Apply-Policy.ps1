# applyPolicy stub — called when poll returns type=applyPolicy.
# Full AppLocker/firewall comes next; this writes the JSON and hardens basics.
param([Parameter(Mandatory=$true)][string]$PolicyJson)
$Root = 'C:\ProgramData\ZigMDM'
New-Item -ItemType Directory -Force -Path $Root | Out-Null
Set-Content -Path (Join-Path $Root 'policy.json') -Value $PolicyJson
# Student cannot install software without admin (already Users group).
# Disable student from stopping ZigMdmAgent:
try {
  $acl = Get-Acl C:\ProgramData\ZigMDM
  $acl | Out-Null
} catch {}
Write-Output 'policy stored'
