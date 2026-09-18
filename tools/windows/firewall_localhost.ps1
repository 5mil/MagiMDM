# Optional: block inbound 8787 from non-loopback. Run elevated if you choose to use it.
# Default bind is already 127.0.0.1 — this is defense in depth.
$ErrorActionPreference = "Stop"
Get-NetFirewallRule -DisplayName "MagiMDM-8787" -ErrorAction SilentlyContinue | Remove-NetFirewallRule
New-NetFirewallRule -DisplayName "MagiMDM-8787" -Direction Inbound -Protocol TCP -LocalPort 8787 -Action Block -Profile Any | Out-Null
Write-Host "Inbound TCP 8787 blocked. Loopback clients still work."
