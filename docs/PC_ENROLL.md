# PC enrollment — blank disk to student laptop

## Server persist (1)

Enroll body includes `platform` and `image_slug`.
`src/enroll_pc.zig` — `normalizePlatform`, `insert_device_sql`, `bind_image_sql`.
Seed slugs in `sql/images.sql`.

Wire in the live enroll handler (`main.zig` / db layer when present):

1. `platform = normalizePlatform(body.platform)`
2. INSERT device with that platform
3. if `image_slug` len &gt; 0: `bind_image_sql`

## Console (2)

Static page: `web/enroll_pc.html` → serve as `GET /enroll/pc`.
`POST /enroll/pc` creates `enrollment_tokens` row and shows token + which USB folder to copy (`agent-pc/linux` or `agent-pc/windows`). Zip download is optional follow-on.

## Autounattend (3)

`agent-pc/windows/Autounattend.xml` — en-US, wipe disk 0, EFI+MSR+Windows, local `parent` / `student`, hide MSA OOBE, FirstLogon enroll + task.
**Change `ChangeMeParent!` / `ChangeMeStudent!` before imaging.**

## Windows policy (4)

Poll `applyPolicy` → `Apply-Policy.ps1 -PolicyJson …` writes `C:\ProgramData\ZigMDM\policy.json`.
AppLocker / firewall / school-hours rules are the next hardening slice.
