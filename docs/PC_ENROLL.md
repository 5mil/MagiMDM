# PC enrollment — blank disk to student laptop

Homeschool path: parent starts with empty storage, MagiMDM builds the machine during enroll.

## Flow

1. Parent creates an enrollment token bound to policy `SchoolDay` (or AfterHours).
2. Parent picks an **image** (`linux-debian12-student` first).
3. Laptop boots installer media (USB now; PXE later) that only talks to this console.
4. Installer wipes the target disk, lays down OS, copies `agent-pc`, writes `/etc/zigmdm/enroll.env` (`MDM_URL`, `TOKEN`).
5. First boot: agent enrolls (`platform=linux`), pulls policy, acks `applyImage` if queued.
6. Device status `pending` → `enrolled`. Audit: `image.apply`, `device.enroll`.

Blank slate means **installer owns the disk**. Do not dual-boot leftover student OS.

## Same APIs as phones

| Step | Endpoint |
|------|----------|
| Enroll | `POST /api/agent/enroll` `{ token, name, platform, model, os_version }` |
| Poll | `POST /api/agent/poll` `{ uuid, agent_version, extras }` |
| Ack | existing command ack |

`devices.platform` = `linux` | `windows` | `android`.

## Image record

`images` table: id, slug, os, arch, source_path (on MDM host / SAS), sha256, seed_json.

`seed_json` example:

```json
{
  "hostname_prefix": "student",
  "packages": ["firefox-esr", "libreoffice"],
  "block_packages": [],
  "agent_unit": "zigmdm-agent.service",
  "student_user": "student",
  "admin_user": "parent"
}
```

Packages files can live next to APKs on the SAS volume.

## Commands

| type | payload |
|------|---------|
| `applyImage` | `{ "slug": "linux-debian12-student" }` |
| `reimage` | same; agent schedules reboot into installer |
| `applyPolicy` | existing JSON |

Reimage is parent-only. Student user cannot disable the unit.

## Linux first cut (this repo)

- `agent-pc/linux/` — enroll + poll loop + systemd unit
- Installer hook later: Debian preseed / autoinstall that calls the same enroll env
- Windows image is a second milestone (Autopilot-like USB + Win32 service)

## Parent console (to add)

Devices list: platform badge. Action: **Enroll PC** → token + image + download USB script.
