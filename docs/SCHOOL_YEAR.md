# School-year execution log

Repo can ship files. Hardware and live imaging stay on the Mini-ITX.

| Steps | In repo | Needs your hands |
|-------|---------|------------------|
| 1–12 console | templates, home, enroll_pc, backup, schedule | wire main.zig routes |
| 13–22 house server | systemd, Caddyfile, backup.sh | install OS, SAS, Caddy |
| 23–36 Android | existing agent + policy JSON | DO enroll on a real phone |
| 37–50 Linux PC | agent, apply-policy, nft, polkit, autoinstall notes | burn USB, test sudo lock |
| 51–68 Windows | Autounattend, enroll, Apply-Policy | licensed ISO, passwords |
| 69–78 year | policies + term_calendar | fill real dates |
| 79–88 parent UX | home.html big buttons | live route |
| 89–96 hardening | runbook honesty | router DNS, Tailscale |
| 97–100 loop | audit_export.sh | mid-year reimage drill |
