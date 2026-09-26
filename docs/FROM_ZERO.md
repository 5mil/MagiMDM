# MagiMDM — full install from zero

Repo: https://github.com/5mil/MagiMDM  
Console: **http://127.0.0.1:8787/login** · `admin` / `changeme`  
Classroom: **Moodle 5.2** · **http://127.0.0.1:8888**

Detail: [INSTALL.md](./INSTALL.md) · [MOODLE.md](./MOODLE.md) · [MOODLE_FIX.md](./MOODLE_FIX.md) · [MOODLE_VERSIONS.md](./MOODLE_VERSIONS.md) · [WINDOWS.md](./WINDOWS.md) · [USB_HOT.md](./USB_HOT.md) · [PLATFORM.md](./PLATFORM.md) · [SCHOOL_NYS.md](./SCHOOL_NYS.md) · [PARENT_GUIDE.md](./PARENT_GUIDE.md)

## 0. Pieces

| Piece | Port | Today |
|-------|------|-------|
| MagiMDM `zig-mdm` | 8787 | Yes |
| SQLite `data/mdm.db` | — | Yes |
| **Moodle 5.2** (Bitnami) | 8888 | Classroom |
| Open edX / Caddy | 80 / 443 | No |

## 1. Ubuntu 26.04 house PC (Moodle 5.2 first if that is the goal)

```bash
sudo apt update
sudo apt install -y git curl ca-certificates docker.io docker-compose-v2
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
# log out and back in

cd ~ && git clone https://github.com/5mil/MagiMDM.git
cd ~/MagiMDM && git pull
cp deploy/moodle/.env.example deploy/moodle/.env
# MOODLE_IMAGE must stay docker.io/bitnami/moodle:5.2
./tools/moodle_up.sh
docker compose -f deploy/moodle/docker-compose.yml logs -f moodle
```

http://127.0.0.1:8888 — `admin` / `ChangeMeMoodle1` unless you changed `.env`.

Failed earlier 4.5 install:

```bash
cd ~/MagiMDM/deploy/moodle && docker compose down -v
cd ~/MagiMDM && git pull && ./tools/moodle_up.sh
```

Alpine fallback: `docker compose -f deploy/moodle/docker-compose.alpine.yml up -d`

## 2. Then zig-mdm on the same machine

```bash
sudo apt install -y build-essential sqlite3 libsqlite3-dev python3 xz-utils
curl -L -o /tmp/zig.tar.xz https://ziglang.org/download/0.16.0/zig-x86_64-linux-0.16.0.tar.xz
sudo mkdir -p /opt/zig && sudo tar -xJf /tmp/zig.tar.xz -C /opt/zig --strip-components=1
export PATH=/opt/zig:$PATH
cd ~/MagiMDM && zig build && ./zig-out/bin/zig-mdm
```

http://127.0.0.1:8787/login

WSL / Windows native / USB: same Moodle folder if Docker exists; console steps in older sections of git history and [WINDOWS.md](./WINDOWS.md) / [USB_HOT.md](./USB_HOT.md).

## 3. Password + smoke

Change `changeme`. `curl -sI http://127.0.0.1:8787/login` and `TOKEN=dev MDM_URL=http://127.0.0.1:8787 python3 tools/mock_pc_agent.py`.

## 4. Backup

`cp data/mdm.db ~/mdm.db.bak`. Moodle 5.2 data is Docker volumes — do not `down -v` after you have courses.
