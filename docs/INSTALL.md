# MagiMDM install from scratch

Self-hosted MDM for a small fleet (about 1–10 devices). No cloud IdP.
Repo: https://github.com/5mil/MagiMDM

Default listen: **http://127.0.0.1:8787** (`src/config.zig`). Trust whatever the binary prints (older notes said 8788).
Default login: **admin** / **changeme** — change immediately.

Also: [PARENT_GUIDE.md](./PARENT_GUIDE.md) · [RUNBOOK.md](./RUNBOOK.md) · [PC_ENROLL.md](./PC_ENROLL.md) · [COMMS.md](./COMMS.md) · [DEPLOY.md](./DEPLOY.md)

The steps below work on any machine that can run Linux, Zig 0.16, and SQLite. Hardware is not part of the required path.

---

## 0. Required (any host)

| Need | Why |
|------|-----|
| Linux (Debian/Ubuntu recommended; other distros fine) | Server OS |
| Zig **0.16.x** | Build `zig-mdm` |
| `libsqlite3` + headers (`libsqlite3-dev` on Debian) | `src/db.zig` |
| Git, a C toolchain | Clone and link libc |
| Disk for OS + `data/mdm.db` | Live database |

Optional later: a reverse proxy, extra disk for archives, student Android / PC agents, parent apps.

Student **iPhones** are not Device-Owner imaged here. The iOS project is a **parent** console client.

---

## Optional hardware profiles

Pick one. None of these change the software steps.

| Profile | Typical box | Notes |
|---------|-------------|-------|
| **A. Any spare PC** | Old desktop or laptop left on | Simplest. DB on internal SSD. |
| **B. Mini / SFF office PC** | Used OptiPlex / EliteDesk / ThinkCentre | Quiet, cheap. Micro/Tiny often lack PCIe if you add SAS later. |
| **C. Mini-ITX in a roomy case** | ITX board + case that takes 3.5" drives | Good if you already have a SAS disk. |
| **D. Mini-ITX + SAS archive** | Same + HBA (LSI 9211 / Dell H310 **IT mode**) | SAS is for `/srv/mdm` backups and packages, **not** the live DB. Do not plug SAS into a motherboard SATA port. |
| **E. VM or home NAS jail** | Proxmox / Incus / bhyve | Snapshot the VM. Give it a LAN IP. |
| **F. VPS** | Any small VPS | Only if you terminate TLS and lock SSH. Prefer Tailscale over a public 443. |

Suggested minimum for 1–10 devices: 1–2 CPU, 1–2 GB RAM, 8+ GB disk. More disk if you keep comms/audit years.

---

## 1. OS packages

Debian/Ubuntu:

```bash
sudo apt update
sudo apt install -y git build-essential curl ca-certificates sqlite3 libsqlite3-dev
```

Fedora: `sqlite-devel gcc git curl`. Arch: `sqlite base-devel git`.

Set timezone; enable SSH if the box is headless.

---

## 2. Zig 0.16

```bash
cd /tmp
# x86_64 example — use aarch64 tarball on ARM
curl -L -o zig.tar.xz https://ziglang.org/download/0.16.0/zig-x86_64-linux-0.16.0.tar.xz
sudo mkdir -p /opt/zig
sudo tar -xJf zig.tar.xz -C /opt/zig --strip-components=1
echo 'export PATH=/opt/zig:$PATH' >> ~/.profile
. ~/.profile
zig version
```

---

## 3. Clone and build

```bash
git clone https://github.com/5mil/MagiMDM.git
cd MagiMDM
zig build
./zig-out/bin/zig-mdm
```

Expect: `MagiMDM http://127.0.0.1:8787/login  db=data/mdm.db`

Current `build.zig` links **libsqlite3** only. You do not need httpz/zqlite vendor trees.

| Failure | Fix |
|---------|-----|
| `sqlite3.h` missing | Install sqlite headers |
| std API rename (`allocPrintSentinel`, writer) | Adjust `src/main.zig` for your 0.16 patch |
| Cannot reach from another device | `host` in `src/config.zig` is `127.0.0.1` — set `0.0.0.0`, rebuild, firewall to your LAN or VPN |

---

## 4. First login

Open http://127.0.0.1:8787/login — `admin` / `changeme`.

Until a settings page exists:

```bash
sqlite3 data/mdm.db "UPDATE users SET password_hash='PLACEHOLDER$YOUR_NEW_PASSWORD' WHERE username='admin';"
```

(`auth.zig` treats `PLACEHOLDER$` + literal password as valid.)

---

## 5. Optional extra disk for archives

If you use profile D (or any second disk):

- Mount it at `/srv/mdm` (or any path).
- Keep **`data/mdm.db` on the OS disk**.
- Point `ZIGMDM_BACKUP` at `/srv/mdm/backups` in `deploy/backup.sh`.
- Same path can hold USB packs and APKs.

Skip entirely if you only have one disk.

---

## 6. Run on boot

Copy the binary to `/usr/local/bin/zig-mdm`. Use `deploy/zig-mdm.service` with `WorkingDirectory` set to the clone (so `web/*.html` resolves). `systemctl enable --now zig-mdm`.

Daily backup (path as you like):

```bash
ZIGMDM_DB=/path/to/MagiMDM/data/mdm.db ZIGMDM_BACKUP=/path/to/backups ./deploy/backup.sh
```

---

## 7. Optional TLS

Put Caddy or nginx in front of `127.0.0.1:8787`. Sample: `deploy/Caddyfile`. Prefer LAN + Tailscale over a public port.

---

## 8. Policies before student devices

Edit `policies/SchoolDay.json` (and AfterHours, ExamLock): real numbers in `comms.allow_numbers`. Keep `mining.enabled` false.

---

## 9. Student Android (when you have a phone)

Wipe → Device Owner install of `agent/` → token + server URL → call-screening role → reboot test. See `agent/README.md` and [COMMS.md](./COMMS.md).

---

## 10. Student PC (when you have a spare machine)

```bash
TOKEN=… MDM_URL=http://SERVER:8787 ./tools/usb_pack.sh /tmp/usb linux
# or windows — change Autounattend passwords first
```

See [PC_ENROLL.md](./PC_ENROLL.md). The installer owns the disk.

---

## 11. Parent apps

`parent-app/android` and `parent-app/ios`. Same URL and parent account. An empty list means `GET /api/parent/devices` is still a stub in `main.zig`.

---

## 12. Smoke test

```bash
curl -s http://127.0.0.1:8787/login | head
TOKEN=dev MDM_URL=http://127.0.0.1:8787 python3 tools/mock_pc_agent.py
```

---

## Done when

The service starts, the password is not `changeme`, a backup file exists, and either the mock agent or a real device can enroll and poll.
