# Moodle sibling — launch now, manage later

Moodle is **not** inside `zig-mdm`. It is a Docker stack you start beside the console. MagiMDM will later store course rows (`kind=moodle`) and pull grades into `outcomes`. Until that hook ships, you launch Moodle here and keep the transcript in MagiMDM by hand or via `tools/learn_sync.sh` style paste.

Open edX remains an optional second classroom (`docs/PLATFORM.md`). You can run Moodle only.

## Launch (Linux / WSL)

Need Docker Engine or Docker Desktop (WSL backend).

```bash
cd MagiMDM/deploy/moodle
cp .env.example .env
# edit MOODLE_PASSWORD
docker compose up -d
docker compose logs -f moodle
```

Wait until Moodle finishes first-run install (several minutes).

- Site: http://127.0.0.1:8888
- User: `admin` (see `.env`)
- zig-mdm stays on :8787

Stop: `docker compose down` (add `-v` only if you intend to wipe the classroom).

Windows native: use Docker Desktop, same `deploy\moodle` folder, `docker compose up -d`.

Do **not** publish 8888 on the router. Tailscale or LAN only.

## Caddy (optional)

See `deploy/Caddyfile.platform` — `learn.home` can point at `127.0.0.1:8888` if you are not using Open edX on :80.

## Later: MagiMDM management

Planned, not in the Zig binary yet:

1. `courses.kind = 'moodle'` + `moodle_id` (course idnumber).
2. Parent page `/lms` lists Moodle courses next to `home` / `openedx` / `college`.
3. `POST /api/learn/sync` reads Moodle web service (`core_enrol_get_users_courses` / grade export) into `outcomes`.
4. SchoolDay allowlist includes `http://learn.home`.

Token placeholder: `data/moodle.env`

```
MOODLE_URL=http://127.0.0.1:8888
MOODLE_WSTOKEN=
```

Create a Moodle web-service token as admin when you are ready to wire sync. Until then, launch + teach in Moodle; log hours on `/school`.
