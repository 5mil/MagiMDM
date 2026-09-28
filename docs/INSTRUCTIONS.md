# House instructions (current)

Tank: Ubuntu desktop. User often `fivemil`. Zig **0.16** at `/opt/zig/zig`.
LAN example: `192.168.50.143`.

Repos:
- Desk: https://github.com/5mil/MagiMDM
- Library: https://github.com/5mil/arcis

Do not port-forward 8787 / 8888 / 9090 on the router.

---

## 0. Once on tank

```bash
sudo apt update
sudo apt install -y build-essential pkg-config libsqlite3-dev curl git wget sqlite3 ufw docker.io docker-compose-v2
# Zig 0.16 if missing:
#   official tarball → /opt/zig/zig
/opt/zig/zig version
```

Firewall (LAN only):

```bash
sudo ufw allow OpenSSH
sudo ufw allow from 192.168.0.0/16 to any port 8787 proto tcp
sudo ufw allow from 192.168.0.0/16 to any port 8888 proto tcp
sudo ufw allow from 192.168.0.0/16 to any port 9090 proto tcp
sudo ufw enable
```

---

## 1. MagiMDM desk (:8787)

```bash
cd ~
git clone https://github.com/5mil/MagiMDM.git magimdm || (cd ~/magimdm && git pull)
cd ~/magimdm
chmod +x tools/*.sh
./tools/wire_main.sh
./tools/wire_audit.sh
./tools/wire_health.sh
mkdir -p data
/opt/zig/zig build
```

First run (creates `data/mdm.db`):

```bash
./tools/up.sh
```

Other terminal:

```bash
./tools/seed_lab.sh
./tools/doctor.sh
```

Laptop browser: `http://192.168.50.143:8787/login`  
`admin` / `changeme` — change immediately.

Health (no login): `http://192.168.50.143:8787/health`

If `AddressInUse`: `fuser -k 8787/tcp` then `./tools/up.sh`.

Production (after the binary works):

```bash
./tools/harden.sh
# edit User=/WorkingDirectory= in deploy/systemd/magimdm.service if not fivemil
sudo cp deploy/systemd/magimdm.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now magimdm
journalctl -u magimdm -f
```

---

## 2. Moodle classroom (:8888)

```bash
cd ~/magimdm/deploy/moodle
sudo docker compose -f docker-compose.alpine.yml up -d
# wwwroot must match how you type the URL:
#   sudo docker exec moodle-moodle-1 grep wwwroot /var/www/html/config.php
```

Browser: `http://192.168.50.143:8888/`  
Desk → Classwork embeds this. Redirect loops = wwwroot mismatch.

---

## 3. Arcis library (:9090)

```bash
cd ~
git clone https://github.com/5mil/arcis.git || (cd ~/arcis && git pull)
cd ~/arcis
chmod +x tools/*.sh
./tools/link_library.sh    # copies OpenStax txt from ~/magimdm/data/library if present
./tools/up.sh              # pulls R1 1.5B GGUF if missing, listens :9090
./tools/doctor.sh
```

Browser: `http://192.168.50.143:9090/`  
Health: `curl -s http://127.0.0.1:9090/health`  
Expect `model_loaded` after the ~1.1 GB GGUF is on disk (~6 GB RAM when loaded as f32).

Production:

```bash
./tools/harden.sh
sudo cp deploy/systemd/arcis.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now arcis
```

---

## 4. What should work

| URL | Role |
|-----|------|
| `:8787/login` | Parent desk |
| `:8787/` | Modes + who is online |
| `:8787/enroll/pc` | QR / USB add device |
| `:8888/` | Moodle |
| `:9090/` | Ask the library |
| Ollama `:11434` | Optional spare; not required |

---

## 5. Daily

```bash
sudo systemctl status magimdm arcis
cd ~/magimdm && ./tools/doctor.sh
cd ~/arcis && ./tools/doctor.sh
```

Update:

```bash
cd ~/magimdm && git pull && ./tools/wire_main.sh && /opt/zig/zig build && sudo systemctl restart magimdm
cd ~/arcis && git pull && zig build && sudo systemctl restart arcis
```

---

## 6. Still thin (do not pretend)

- Android APK is not produced by `zig build`
- iPhone is not MDM
- Moodle is not SSO with MagiMDM
- Desk fleet is empty until `wire_main.sh` + enroll or `seed_lab.sh`
- Arcis Q4 dequant → f32 uses a lot of RAM; answers may be weak until generate() is proven
- Default password is a hole until you change it
