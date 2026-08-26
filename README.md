# MagiMDM (ZigMDM)

**Repository:** https://github.com/5mil/MagiMDM

Self-hosted **Mobile Device Management** for a small fleet (about 1–10 devices).

Built in **Zig** for a small binary, low memory use, and fully local control — no cloud IdP, no mandatory external services.

---

## Documentation index

| Document | Description |
|----------|-------------|
| [README.md](./README.md) | This file — overview, quick start, API |
| [docs/DEPLOY.md](./docs/DEPLOY.md) | TLS, reverse proxy (Caddy/nginx), systemd, backups |
| [agent/README.md](./agent/README.md) | Android Kotlin agent (enroll, poll, WorkManager) |
| [tools/README.md](./tools/README.md) | Python mock agent usage |

### Console URLs (default local server)

| Link | Purpose |
|------|---------|
| http://127.0.0.1:8787/login | Sign in |
| http://127.0.0.1:8787/ | Devices |
| http://127.0.0.1:8787/enroll | Enrollment tokens |
| http://127.0.0.1:8787/policies | Policies |
| http://127.0.0.1:8787/packages | APK / package registry |
| http://127.0.0.1:8787/audit | Audit log |
| http://127.0.0.1:8787/devices/1 | Device detail (policy + deploy) |

### Upstream libraries

| Library | Repository |
|---------|------------|
| Zig | https://ziglang.org/download/ |
| Zig 0.16.0 (Linux x86_64) | https://ziglang.org/download/0.16.0/zig-x86_64-linux-0.16.0.tar.xz |
| http.zig | https://github.com/karlseguin/http.zig |
| zqlite | https://github.com/karlseguin/zqlite.zig |

---

## Features

| Area | Status |
|------|--------|
| Single binary + SQLite | Done |
| Local username/password (**argon2id**) | Done |
| Web console (HTMX + Tailwind) | Done |
| Enrollment tokens | Done |
| Remote commands (lock / reboot / wipe queue) | Done |
| Agent API (enroll / poll / ack) | Done |
| Policies pushed on poll | Done |
| Per-device policy assignment UI | Done |
| Audit log UI | Done |
| APK deploy command (`deploy_apk`) | Done |
| Python mock agent | Done |
| Android Kotlin agent + **WorkManager** | Done |
| TLS / reverse-proxy guide | Done — [docs/DEPLOY.md](./docs/DEPLOY.md) |

---

## Quick start

```bash
# Vendor deps (not committed — clone locally):
git clone --depth 1 https://github.com/karlseguin/zqlite.zig.git vendor/zqlite
git clone --depth 1 https://github.com/karlseguin/http.zig.git vendor/httpz

# Zig 0.16.0 required
zig build
./zig-out/bin/zig-mdm
```

Open **http://127.0.0.1:8787/login** — default `admin` / `changeme`.

See full README sections in the repository for Agent API, layout, and security notes.
