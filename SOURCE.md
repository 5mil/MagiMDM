# Source layout

**Repository:** https://github.com/5mil/MagiMDM

Full working tree was developed locally. Core server implementation files:

| Path | Notes |
|------|--------|
| `src/main.zig` | HTTP routes, agent API, console handlers |
| `src/db.zig` | SQLite schema + queries |
| `src/handlers/*.zig` | Login / dashboard HTML |
| `tools/mock_agent.py` | Python enroll/poll/ack loop |
| `agent/app/...` | Kotlin agent |

If any of these are missing on `main`, copy from your local MagiMDM/ZigMDM workspace and push:

```bash
git clone https://github.com/5mil/MagiMDM.git
# copy remaining files from local artifacts, then:
git add -A && git commit -m "Complete server and agent sources" && git push
```

Vendored deps (not committed):

```bash
git clone --depth 1 https://github.com/karlseguin/zqlite.zig.git vendor/zqlite
git clone --depth 1 https://github.com/karlseguin/http.zig.git vendor/httpz
```

Requires **Zig 0.16.0**.
