# Parent runbook

Console: `https://mdm.home` (LAN). Parent account only.
Change `admin/changeme` on first login.

## New phone
Wipe → Device Owner enroll with token → assign SchoolDay.

## New laptop
`TOKEN=... MDM_URL=https://mdm.home ./tools/usb_pack.sh /tmp/usb windows` (or `linux`).
Copy pack onto installer USB. Boot laptop, let disk wipe. Device appears as pending → enrolled.

## Day buttons
School / Free / Exam / Lock on home.
Sick-day: AfterHours + note in audit.

## Missed check-in
If last_seen &gt; 2h during SchoolDay, treat as late. Second unmanaged phone is out of scope.

## Reimage
Queue `reimage` or boot the labeled USB.

## Backup
`deploy/backup.sh` → `/srv/mdm/backups` (SAS). 90-day keep.

## Passwords
Autounattend still has `ChangeMeParent!` / `ChangeMeStudent!` until you edit the XML.

## What this cannot stop
A second phone, a friend PC, or BIOS reset without firmware lock.
