# MagiMDM server setup, start to finish

One always-on Linux box on the house LAN. Not a student laptop. Any leftover desktop, NUC, mini PC, NAS VM, or similar is fine.

Paths below use /opt/MagiMDM for the source tree and /srv/mdm for backups. Change them if you want. Keep one working directory and one database file.

MagiMDM listens on 127.0.0.1:8787. The unit file in deploy/ talks about /var/lib/zigmdm and the Caddyfile in deploy/ points at 8788. Those files are stale. Follow this page, not those two numbers.

Student policies keep mining off. Leave it off.

## 1. OS

Install Debian or Ubuntu Server. A desktop install works too.

Create a system user that is not a kid:

    sudo useradd -r -m -d /var/lib/zigmdm -s /usr/sbin/nologin mdm
    sudo mkdir -p /opt /srv/mdm/backups /srv/mdm/apk /srv/mdm/usb /var/lib/zigmdm
    sudo chown -R mdm:mdm /var/lib/zigmdm /srv/mdm

Give your own admin account sudo. Update the box.

    sudo apt update
    sudo apt install -y git curl ca-certificates build-essential sqlite3 python3 caddy

Pick a fixed LAN IP if you can (router reservation). Example used below: 192.168.1.20. Use yours.

## 2. Zig 0.16

Distro zig is too old.

    uname -m
    # x86_64 -> zig-linux-x86_64-0.16.0.tar.xz
    # aarch64 -> zig-linux-aarch64-0.16.0.tar.xz

Get the 0.16 tarball from https://ziglang.org/download/ and unpack:

    cd /tmp
    tar -xf zig-linux-*.tar.xz
    sudo mv zig-linux-* /usr/local/zig-0.16
    sudo ln -sfn /usr/local/zig-0.16/zig /usr/local/bin/zig
    zig version

You want 0.16.x.

## 3. Clone MagiMDM

    sudo git clone https://github.com/5mil/MagiMDM.git /opt/MagiMDM
    sudo chown -R "$USER":"$USER" /opt/MagiMDM
    cd /opt/MagiMDM
    git log -1 --oneline
    ls src/main.zig src/db.zig

If those two files are missing, you cloned an old commit. git pull.

    git clone --depth 1 https://github.com/karlseguin/zqlite.zig.git vendor/zqlite
    git clone --depth 1 https://github.com/karlseguin/http.zig.git vendor/httpz

build.zig.zon already points at vendor/zqlite and vendor/httpz.

## 4. Build

    cd /opt/MagiMDM
    zig build
    ls -l zig-out/bin/zig-mdm
    sudo cp zig-out/bin/zig-mdm /usr/local/bin/zig-mdm

If the compiler dies on std.Io.Threaded or httpz.Server.init, the 0.16 snapshots moved. Fix those two call sites in src/main.zig. Do not enable mining.

## 5. First run (foreground)

    mkdir -p /opt/MagiMDM/data
    cd /opt/MagiMDM
    /usr/local/bin/zig-mdm

Leave that terminal open. On the same machine:

    curl -sI http://127.0.0.1:8787/login

You want HTTP 200. Browser: http://127.0.0.1:8787/login

Login admin / changeme. Change it the same hour.

In another terminal:

    cd /opt/MagiMDM
    TOKEN=dev MDM_URL=http://127.0.0.1:8787 python3 tools/mock_pc_agent.py

Enroll line plus poll lines. Refresh /. The mock device should show in the JSON.

Ctrl-C the server when that works.

First start created /opt/MagiMDM/data/mdm.db, policies, and the lab token "dev".

    sudo ln -sfn /opt/MagiMDM/data/mdm.db /var/lib/zigmdm/mdm.sqlite
    sudo chown -R mdm:mdm /opt/MagiMDM/data

## 6. systemd

Write /etc/systemd/system/zig-mdm.service yourself so the paths match this tree:

    [Unit]
    Description=MagiMDM
    After=network-online.target
    Wants=network-online.target

    [Service]
    Type=simple
    User=mdm
    Group=mdm
    WorkingDirectory=/opt/MagiMDM
    ExecStart=/usr/local/bin/zig-mdm
    Restart=always
    RestartSec=5

    [Install]
    WantedBy=multi-user.target

    sudo chown -R mdm:mdm /opt/MagiMDM/data
    sudo systemctl daemon-reload
    sudo systemctl enable --now zig-mdm
    sudo systemctl status zig-mdm
    curl -sI http://127.0.0.1:8787/login

If it fails, journalctl -u zig-mdm -e. Usually WorkingDirectory is wrong or mdm cannot write data/mdm.db.

## 7. Names on the LAN

On the server and on parent machines that stay home, /etc/hosts:

    192.168.1.20  mdm.home moodle.home sis.home

Or the same names on your router DNS.

Do not publish port 443 on the internet.

## 8. Caddy

The repo Caddyfile proxies 8788. MagiMDM is on 8787. Use this instead in /etc/caddy/Caddyfile:

    mdm.home {
        bind 127.0.0.1 192.168.0.0/16 10.0.0.0/8 172.16.0.0/12
        reverse_proxy 127.0.0.1:8787
    }

    sudo systemctl enable --now caddy
    sudo systemctl reload caddy

Open https://mdm.home/login from a parent computer. First load may warn about a local cert. That is expected on a LAN name.

## 9. Backup

    sudo chmod +x /opt/MagiMDM/deploy/backup.sh
    sudo ZIGMDM_DB=/opt/MagiMDM/data/mdm.db ZIGMDM_BACKUP=/srv/mdm/backups /opt/MagiMDM/deploy/backup.sh
    ls /srv/mdm/backups

Put that in root's crontab once a night:

    15 3 * * * ZIGMDM_DB=/opt/MagiMDM/data/mdm.db ZIGMDM_BACKUP=/srv/mdm/backups /opt/MagiMDM/deploy/backup.sh

Copy a backup off the box now and then (USB disk or NAS).

## 10. Away-from-home access

Install Tailscale or WireGuard on the server only. Parent phones join that net.

Parent app server URL is https://mdm.home if split-DNS works, or http://100.x.y.z:8787 if you skip Caddy on the tailnet. Prefer https on the LAN name.

Do not port-forward 8787 or 443.

## 11. Moodle (optional, same box or another VM)

Install Moodle the usual way. Put it behind Caddy as moodle.home. LAN only.

Create a teacher account for you and a student account for the child. Write those names next to the MagiMDM token.

From a student device on SchoolDay, Firefox should open https://moodle.home.

## 12. RosarioSIS (optional)

Install RosarioSIS at sis.home. Change admin / admin.

Enable the Moodle plugin: REST, https://moodle.home, token from Moodle web services.

Create courses in RosarioSIS after the plugin is on.

Map child to device on the MagiMDM host:

    sqlite3 /opt/MagiMDM/data/mdm.db

    CREATE TABLE IF NOT EXISTS sis_device_map (
      student_name TEXT NOT NULL,
      student_id   TEXT,
      moodle_user  TEXT,
      device_uuid  TEXT NOT NULL,
      asset_tag    TEXT,
      platform     TEXT,
      status       TEXT
    );

## 13. Updates later

    cd /opt/MagiMDM
    sudo -u "$USER" git pull
    zig build
    sudo cp zig-out/bin/zig-mdm /usr/local/bin/zig-mdm
    sudo systemctl restart zig-mdm
    curl -sI http://127.0.0.1:8787/login

## 14. Done when

systemctl is-active zig-mdm is active.

http://127.0.0.1:8787/login and https://mdm.home/login load.

admin password is not changeme.

TOKEN=dev mock agent enrolls and polls.

/srv/mdm/backups has a sqlite copy.

Kids have no MagiMDM account.

mining.enabled is false on every policy.

Household use after that is docs/PARENT_GUIDE.md: tokens, Android Device Owner, laptop USB, four buttons, Moodle during SchoolDay.
