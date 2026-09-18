# Shipped this drop

- `src/algebra.zig` — server-side problem gen + last-hit judge (no client-trusted x)
- `src/main.zig` — `/school` `/lms` `/algebra-war` and `/api/game/session` `/api/game/move`
- `src/db.zig` — school + lms + game tables on open
- Lane UI posts moves to the API when the server is up; still playable as a file

```bash
git pull && zig build && ./zig-out/bin/zig-mdm
# login, then http://127.0.0.1:8787/algebra-war
```
