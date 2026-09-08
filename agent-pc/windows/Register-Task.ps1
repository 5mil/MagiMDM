# Run once after enroll.ps1 succeeds (SYSTEM).
$script = 'C:\ProgramData\ZigMDM\enroll.ps1'
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `$script"
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 1) -RepetitionDuration ([TimeSpan]::MaxValue)
Register-ScheduledTask -TaskName 'ZigMdmAgent' -Action $action -Trigger $trigger -User 'SYSTEM' -RunLevel Highest -Force
