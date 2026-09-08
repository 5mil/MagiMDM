# PC enrollment — blank disk to student laptop

Parent starts with empty storage. MagiMDM builds the machine during enroll.

## Shared flow (Linux + Windows)

1. Parent creates enrollment token + assigns policy (`SchoolDay`).
2. Parent picks an **image** slug.
3. USB installer (PXE later) wipes the target disk and lays down that OS.
4. Image writes enroll config + starts the PC agent.
5. Agent `POST /api/agent/enroll` then poll/ack like Android.
6. Status `pending` → `enrolled`. Audit `image.apply`, `device.enroll`.

Installer owns the disk. No leftover student OS.

## API

```
POST /api/agent/enroll
{
  "token": "…",
  "name": "hostname",
  "platform": "linux" | "windows",
  "model": "optional",
  "os_version": "Debian 12" | "Windows 11",
  "agent_version": "0.1.0-linux" | "0.1.0-windows",
  "image_slug": "linux-debian12-student" | "windows11-student"
}

POST /api/agent/poll   { uuid, agent_version, extras }
POST /api/agent/ack    existing command ack
```

`devices.platform` must be stored as sent. `image_slug` → `device_images`.

## Images

| slug | OS |
|------|----|
| `linux-debian12-student` | Debian 12 + agent unit |
| `windows11-student` | Win11 Pro + agent service |

`seed_json` holds hostname prefix, packages/apps, `student_user`, `admin_user`.

## Commands

| type | payload |
|------|---------|
| `applyImage` | `{ "slug": "…" }` |
| `reimage` | parent-only; reboot into installer |
| `applyPolicy` | policy JSON |

Student account cannot stop the agent service.

## Linux

`agent-pc/linux/` — `enroll.env`, systemd unit, poll loop.
Installer: Debian preseed/autoinstall writes `/etc/zigmdm/enroll.env`.

## Windows

`agent-pc/windows/` — `enroll.ps1` + `ZigMdmAgent` scheduled task / service.

USB layout:

```
USB\
  Autounattend.xml      # wipe + install Win11 Pro
  zigmdm\
    enroll.ps1
    enroll.env.example  # MDM_URL, TOKEN, IMAGE_SLUG
```

`Autounattend.xml` FirstLogonCommands runs `enroll.ps1` as SYSTEM.
Script enrolls, writes `C:\ProgramData\ZigMDM\device.env`, registers a 60s poll task.
Policy apply on Windows (AppLocker, firewall, school hours) is the slice after enroll works.

OOBE must skip consumer Microsoft account. Local `parent` (admin) + `student` (standard).

## Console (next UI)

**Enroll PC** → platform Linux|Windows → image → token → download USB pack.
