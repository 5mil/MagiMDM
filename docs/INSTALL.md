# MagiMDM install from scratch

House server for 1–10 student devices. No cloud IdP.
Repo: https://github.com/5mil/MagiMDM

Default listen: **http://127.0.0.1:8787** (`src/config.zig`). Some older notes say 8788 — use whatever the binary prints on startup.
Default login: **admin** / **changeme** (change immediately).

Related: [PARENT_GUIDE.md](./PARENT_GUIDE.md) · [RUNBOOK.md](./RUNBOOK.md) · [PC_ENROLL.md](./PC_ENROLL.md) · [COMMS.md](./COMMS.md) · [DEPLOY.md](./DEPLOY.md)

---

## 0. What you need

| Item | Why |
|------|-----|
| Mini-ITX (or any always-on PC) with a **large enough case for 3.5" SAS** | Server |
| SSD | OS + live SQLite |
| SAS HDD + LSI/Dell HBA in **IT mode** (optional but planned) | Backups, USB packs, APKs |
| Debian 12 or Ubuntu 22.04/24.04 | Server OS |
| Zig **0.16.x** | Build `zig-mdm` |
| `libsqlite3-dev` | `src/db.zig` |
| Spare Android phone | First student device |
| Spare laptop + USB stick | First PC image |
| Licensed Win11 Pro ISO only if you image Windows | Autounattend |

Student iPhones are not Device-Owner imaged by this project. The iOS app is for **parents**.

---

## 1. Install the server OS

1. Boot Debian/Ubuntu installer from USB.
2. Put `/` on the **SSD**. Do not put the live database on the SAS disk.
3. Create user `mdm` with sudo.
4. Enable SSH. Set timezone (`timedatectl set-timezone America/New_York` or yours).
5. `sudo apt update && sudo apt install -y git build-essential curl ca-certificates sqlite3 libsqlite3-dev caddy`

---

## 2. SAS disk (if you have one)

1. HBA in the Mini-ITX PCIe slot (IT firmware, not RAID).
2. Cable: SFF-8087 → SFF-8482 + Molex/SATA power. **Not** a motherboard SATA header.
3. `lsblk` — you should see a new disk.
4. Partition, `ext4`, mount `/srv/mdm`:

```bash
sudo mkdir -p /srv/mdm/{backups,packages}
# example fstab line after you know the UUID:
# UUID=....  /srv/mdm  ext4  defaults,nofail  0  2
```

Skip this section if you have no SAS drive yet. Backups can stay on the SSD until then.

---

## 3. Zig 0.16

```bash
cd /tmp
curl -L -o zig.tar.xz https://ziglang.org/download/0.16.0/zig-x86_64-linux-0.16.0.tar.xz
sudo mkdir -p /opt/zig
sudo tar -xJf zig.tar.xz -C /opt/zig --strip-components=1
echo 'export PATH=/opt/zig:$PATH' >> ~/.profile
. ~/.profile
zig version   # expect 0.16.0
```

Use the tarball that matches your CPU (`aarch64` on ARM boards).

---

## 4. Clone and build

```bash
sudo mkdir -p /var/lib/zigmdm
sudo chown $USER:$USER /var/lib/zigmdm
cd ~
git clone https://github.com/5mil/MagiMDM.git
cd MagiMDM
zig build
./zig-out/bin/zig-mdm
```

You should see something like:

`MagiMDM http://127.0.0.1:8787/login  db=data/mdm.db`

**If it fails**

| Error | Fix |
|-------|-----|
| `sqlite3.h` missing | `sudo apt install libsqlite3-dev` |
| `allocPrintSentinel` / `stream.writer` | Zig std renamed it — open `src/main.zig` and use `allocPrintZ` or the 0.16 writer API |
| `httpz` / `zqlite` missing | Current `build.zig` does **not** need those vendors |
| Port in use | Change `src/config.zig` `port` |

Leave the process running and from another machine on the LAN:

`curl -sI http://SERVER_LAN_IP:8787/login`

If that fails, the listener is bound to **127.0.0.1 only**. Edit `src/config.zig` `host` to `0.0.0.0`, rebuild, and firewall so only LAN/Tailscale can reach 8787.

---

## 5. First login

Browser: `http://127.0.0.1:8787/login`

- User: `admin`
- Password: `changeme`

You should land on `/` or `/home` (School / Free / Exam / Lock).

Change the password in SQLite after first success (until a settings page exists):

```bash
sqlite3 data/mdm.db "UPDATE users SET password_hash='PLACEHOLDER$YOUR_NEW_PASSWORD' WHERE username='admin';"
```

(`auth.zig` accepts `PLACEHOLDER$` plus the literal password.)

---

## 6. Run as a service

```bash
sudo cp zig-out/bin/zig-mdm /usr/local/bin/zig-mdm
sudo useradd --system --home /var/lib/zigmdm --shell /usr/sbin/nologin mdm || true
sudo mkdir -p /var/lib/zigmdm
sudo cp -a data /var/lib/zigmdm/ 2>/dev/null || true
# WorkingDirectory must be the repo (web/*.html) OR copy web/ next to the db.
sudo cp deploy/zig-mdm.service /etc/systemd/system/
# Edit the unit: WorkingDirectory=/home/YOU/MagiMDM  and User=YOU for the first week.
sudo systemctl daemon-reload
sudo systemctl enable --now zig-mdm
sudo systemctl status zig-mdm
```

Adjust `deploy/zig-mdm.service` if your binary still listens on 8787 (the sample file may say 8788).

Daily backup:

```bash
sudo cp deploy/backup.sh /usr/local/sbin/zigmdm-backup
sudo chmod +x /usr/local/sbin/zigmdm-backup
# crontab:
# 15 3 * * * ZIGMDM_DB=/home/YOU/MagiMDM/data/mdm.db ZIGMDM_BACKUP=/srv/mdm/backups /usr/local/sbin/zigmdm-backup
```

---

## 7. HTTPS on the LAN (Caddy)

`/etc/caddy/Caddyfile`:

```
mdm.home {
    bind 192.168.0.0/16 10.0.0.0/8 172.16.0.0/12 127.0.0.1
    reverse_proxy 127.0.0.1:8787
}
```

Add `mdm.home` to the server `/etc/hosts` and to each parent phone (or use the LAN IP). Do **not** open 443 on the router. Use Tailscale if you need the parent app away from home.

```bash
sudo systemctl enable --now caddy
```

---

## 8. Policy numbers (before any child phone)

Edit `policies/SchoolDay.json` (and AfterHours, ExamLock):

- Put **your** numbers in `comms.allow_numbers` (not `+15555550100`).
- Keep `mining.enabled` false.
- Leave `comms.logging` at `metadata` until you want SMS bodies.

Then update the DB row or re-insert from `sql/policies_school.sql`.

---

## 9. Enroll a student Android

1. Wipe the phone.
2. Build `agent/` in Android Studio (package `com.zigmdm.agent`).
3. Set it as **Device Owner** (see `agent/README.md`). A normal Play install is not enough.
4. Create a token on the console (or insert into `enrollment_tokens`).
5. Agent server URL = `http://LAN_IP:8787` or `https://mdm.home`.
6. Set the agent as the **call screening** app.
7. Confirm the device appears after poll; reboot; policy still there.
8. Call from a number not on the list — should reject. Your number — should ring.

If the child can uninstall the agent, it is not Device Owner. Wipe and repeat.

---

## 10. Enroll a student PC (blank disk)

```bash
cd ~/MagiMDM
# after POST /enroll/pc you get TOKEN=
TOKEN=thatvalue MDM_URL=http://LAN_IP:8787 ./tools/usb_pack.sh /tmp/usb linux
# or: ./tools/usb_pack.sh /tmp/usb windows
```

Copy `/tmp/usb` onto the installer stick.

**Windows:** edit `Autounattend.xml` passwords (`ChangeMeParent!` / `ChangeMeStudent!`) first. Licensed Win11 Pro USB. Disk 0 is wiped.

**Linux:** use `agent-pc/linux/autoinstall.yaml` as the installer user-data sketch.

Daily account = `student`. Admin = `parent`.

---

## 11. Parent apps (your phone)

- Android: `parent-app/android` in Android Studio, id `com.zigmdm.parent`.
- iPhone: copy `parent-app/ios` into an Xcode app.

URL + parent login. Buttons: School / Free / Exam / Lock.
Empty list means `GET /api/parent/devices` is still a stub (`[]`) — fill it when you extend `main.zig`.

---

## 12. Smoke test

```bash
# from the MagiMDM directory while the server runs
curl -s http://127.0.0.1:8787/login | head
TOKEN=dev MDM_URL=http://127.0.0.1:8787 python3 tools/mock_pc_agent.py
# should print enrolled … then poll
```

Also: `tools/audit_export.sh`, `tools/comms_export.sh`, `deploy/backup.sh`.

---

## 13. Done when

- [ ] `zig-mdm` starts on boot
- [ ] You can log in and the password is no longer `changeme`
- [ ] Backup file exists under `/srv/mdm/backups` or `data/`
- [ ] One Android Device Owner phone checks in
- [ ] Blocked call or mock poll shows up
- [ ] One spare laptop can be imaged from USB (optional same week)

Do not publish 443 to the internet. Do not put mining on student images. Do not expect WhatsApp/Signal bodies in the comms archive.
