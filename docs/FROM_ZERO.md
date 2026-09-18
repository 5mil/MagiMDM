# MagiMDM — full install from zero

Repo: https://github.com/5mil/MagiMDM  
Default console: **http://127.0.0.1:8787/login**  
Default user: **admin** / **changeme** (change immediately)

This is the master path. Other docs are detail:
[INSTALL.md](./INSTALL.md) · [WINDOWS.md](./WINDOWS.md) · [USB_HOT.md](./USB_HOT.md) · [MOODLE.md](./MOODLE.md) · [PLATFORM.md](./PLATFORM.md) · [SCHOOL_NYS.md](./SCHOOL_NYS.md) · [PARENT_GUIDE.md](./PARENT_GUIDE.md) · [PC_ENROLL.md](./PC_ENROLL.md) · [COMMS.md](./COMMS.md)

---

## 0. What you are installing

| Piece | Process | Port | Required today? |
|-------|---------|------|-----------------|
| MagiMDM console | `zig-mdm` | 8787 | **Yes** |
| SQLite | file `data/mdm.db` | — | **Yes** |
| Moodle classroom | Docker | 8888 | No |
| Open edX | Tutor | 80 | No |
| Caddy | reverse proxy | 443 | No |
| Android Device Owner | on the phone | — | When you have a student phone |
| Student PC image | USB pack | — | When you have a spare laptop |
| Algebra War | served by zig-mdm | /algebra-war | Comes with console |

Pick **one** place to run the console first. Do not start Moodle or image a PC until login works.

---

## 1. Choose a host

| Path | Use when |
|------|----------|
| **A. WSL Ubuntu** on a Windows PC | Fastest test |
| **B. Native Windows** `zig-mdm.exe` | No WSL |
| **C. Ubuntu on the house PC** (e.g. old Dell XPS) | Always-on server |
| **D. Linux USB stick** | Carry the console |

A spare desktop left on Ethernet is the long-term box. WSL/Windows are for proving the build.

---

## 2A. WSL (recommended first test)

Windows PowerShell:

```powershell
wsl --install -d Ubuntu
# reboot if asked, then open Ubuntu
```

Inside Ubuntu:

```bash
sudo apt update
sudo apt install -y git build-essential curl xz-utils sqlite3 libsqlite3-dev python3

curl -L -o /tmp/zig.tar.xz https://ziglang.org/download/0.16.0/zig-x86_64-linux-0.16.0.tar.xz
sudo mkdir -p /opt/zig && sudo tar -xJf /tmp/zig.tar.xz -C /opt/zig --strip-components=1
echo 'export PATH=/opt/zig:$PATH' >> ~/.bashrc && source ~/.bashrc
zig version

git clone https://github.com/5mil/MagiMDM.git
cd MagiMDM
zig build
./zig-out/bin/zig-mdm
```

Windows browser: http://127.0.0.1:8787/login

If the tarball name 404s, list https://ziglang.org/download/ and use the current 0.16.x linux-x86_64 file.

---

## 2B. Native Windows

1. Install Zig 0.16 from https://ziglang.org/download/ — add to PATH.
2. Git for Windows.
3. PowerShell:

```powershell
git clone https://github.com/5mil/MagiMDM.git
cd MagiMDM
powershell -ExecutionPolicy Bypass -File tools\windows\BUILD.ps1
powershell -ExecutionPolicy Bypass -File tools\windows\RUN.ps1
```

That fetches SQLite amalgamation and builds `zig-out\bin\zig-mdm.exe`. Bind is localhost only. Do not run as Administrator. Detail: [WINDOWS.md](./WINDOWS.md).

---

## 2C. Ubuntu on a desktop (house server)

Install Ubuntu 24.04 or 26.04 **Server** (or Desktop). Ethernet. UEFI + AHCI.

```bash
sudo apt update
sudo apt install -y git build-essential curl ca-certificates sqlite3 libsqlite3-dev
# Zig as in 2A
git clone https://github.com/5mil/MagiMDM.git
cd MagiMDM && zig build
```

Keep `data/mdm.db` on the OS SSD. Optional systemd: `deploy/zig-mdm.service` with `WorkingDirectory=` the clone. Optional Caddy: `deploy/Caddyfile` or `deploy/Caddyfile.platform`. Prefer Tailscale over opening 443 to the world.

---

## 2D. Hot-plug USB (Linux/WSL)

```bash
cd MagiMDM
./tools/usb_hot.sh /mnt/e/MagiMDM-USB --with-zig
cd /mnt/e/MagiMDM-USB
./BUILD.sh && ./RUN.sh
```

Not the student imaging USB. See [USB_HOT.md](./USB_HOT.md).

---

## 3. First login and password

Open `/login` → `admin` / `changeme`.

```bash
sqlite3 data/mdm.db "UPDATE users SET password_hash='PLACEHOLDER$YOUR_NEW_PASSWORD' WHERE username='admin';"
```

(`PLACEHOLDER$` + literal password is what `auth.zig` accepts until argon is wired for changes.)

Pages after login: `/` `/school` `/lms` `/algebra-war` `/comms` `/enroll/pc`

---

## 4. Smoke test

Second terminal, same machine:

```bash
curl -sI http://127.0.0.1:8787/login
TOKEN=dev MDM_URL=http://127.0.0.1:8787 python3 tools/mock_pc_agent.py
```

Algebra War: login, open `/algebra-war`, or

```bash
# after login cookie — or use the page
curl -s -c /tmp/c -b /tmp/c -X POST http://127.0.0.1:8787/api/game/session -d '{"band":2}'
```

Pass = binary stays up, login works, mock agent returns ok.

---

## 5. School + LMS tables

Created automatically on first `zig-mdm` start (`src/db.zig`). Optional extra files:

```bash
sqlite3 data/mdm.db < sql/school.sql
sqlite3 data/mdm.db < sql/lms.sql
sqlite3 data/mdm.db < sql/algebra_war.sql
```

Seed:

```bash
sqlite3 data/mdm.db "INSERT INTO children(given_name,grade_band,grade) VALUES('Child','9-12',9);"
```

NY subject rules: [SCHOOL_NYS.md](./SCHOOL_NYS.md).

---

## 6. Moodle (optional classroom)

Needs Docker.

```bash
cd MagiMDM
cp deploy/moodle/.env.example deploy/moodle/.env
# change passwords
./tools/moodle_up.sh
```

http://127.0.0.1:8888 — first boot is slow. Do not port-forward 8888. Grades are not auto-synced yet. [MOODLE.md](./MOODLE.md).

---

## 7. Reach the console from a phone (still private)

1. Tailscale on the server and the phone, **or**
2. Set `host` in `src/config.zig` to `0.0.0.0`, rebuild, firewall 8787 to LAN only.

Never put `/api/agent/*` on the open internet.

---

## 8. Student Android (when you have a phone)

Wipe → install Device Owner agent from `agent/` → server URL + token → call-screening role. [COMMS.md](./COMMS.md). iPhone student MDM is not in this product; iOS app is parent-only.

---

## 9. Student PC (destroys the disk)

```bash
TOKEN=... MDM_URL=http://SERVER:8787 ./tools/usb_pack.sh /tmp/usb linux
```

Windows pack: edit Autounattend passwords first. [PC_ENROLL.md](./PC_ENROLL.md).

---

## 10. Parent apps

`parent-app/android` and `parent-app/ios` — same URL. Device list is empty until `/api/parent/devices` is more than a stub.

---

## 11. Backup

```bash
./deploy/backup.sh
```

Copy `data/mdm.db`. If Moodle is up, volumes live in Docker — `docker compose -f deploy/moodle/docker-compose.yml` does not replace a MagiMDM backup.

---

## 12. Done when

- [ ] `zig-mdm` prints `/login`
- [ ] Password is not `changeme`
- [ ] Mock agent enrolls **or** a real device polls
- [ ] You know where `data/mdm.db` is
- [ ] Moodle only if you actually opened :8888

If `zig build` fails, send the first error block (often `sqlite3.h`, Zig tarball name, or a 0.16 std rename).
