param([Parameter(Mandatory=$true)][string]$PolicyJson)
$Root = 'C:\ProgramData\ZigMDM'
New-Item -ItemType Directory -Force -Path $Root | Out-Null
Set-Content -Path (Join-Path $Root 'policy.json') -Value $PolicyJson
$p = $PolicyJson | ConvertFrom-Json
$mode = $p.mode
# Student ACL: deny Users modify on agent folder
$acl = Get-Acl $Root
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule('Users','Modify','ContainerInherit,ObjectInherit','None','Deny')
$acl.AddAccessRule($rule)
Set-Acl $Root $acl
# Firewall profile: school/exam = public-like tight; else leave
if ($mode -eq 'school' -or $mode -eq 'exam') {
  netsh advfirewall set allprofiles firewallpolicy blockinbound,allowoutbound | Out-Null
}
Write-Output "policy stored mode=$mode"
