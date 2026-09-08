# MagiMDM

Self-hosted MDM for a small homeschool fleet (phones + student PCs).

**Repo:** https://github.com/5mil/MagiMDM

## Docs

| Doc | What |
|-----|------|
| [docs/RUNBOOK.md](./docs/RUNBOOK.md) | Parent day-to-day |
| [docs/PC_ENROLL.md](./docs/PC_ENROLL.md) | Blank-disk Linux/Windows enroll |
| [docs/SCHOOL_YEAR.md](./docs/SCHOOL_YEAR.md) | What landed vs hardware |
| [docs/DEPLOY.md](./docs/DEPLOY.md) | TLS / proxy |
| [docs/POLL.md](./docs/POLL.md) | Agent extras |

## Console (when main.zig is wired)

| Path | Purpose |
|------|---------|
| /login | Parent only |
| / or /home | School / Free / Exam / Lock |
| /enroll/pc | PC token + USB notes |
| /policies | SchoolDay and siblings |
| /audit | Trail |

Default `admin` / `changeme` — change immediately.

```bash
git clone https://github.com/5mil/MagiMDM
# vendor zqlite + http.zig as in prior README
zig build
./zig-out/bin/zig-mdm
TOKEN=dev MDM_URL=http://127.0.0.1:8788 python3 tools/mock_pc_agent.py
```

Student templates keep `mining.enabled: false`.
