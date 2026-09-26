# Moodle 5.2 sibling — launch now, manage later

Default classroom is **Moodle 5.2** (`docker.io/bitnami/moodle:5.2`). It is not inside `zig-mdm`. MagiMDM later stores `courses.kind=moodle` and grades in `outcomes`. Until that hook ships, teach in Moodle and log hours on `/school`.

## Ubuntu 26.04 / WSL — 5.2

Docker Engine or Desktop. Then:

```bash
cd ~/MagiMDM
git pull
cp deploy/moodle/.env.example deploy/moodle/.env
# edit MOODLE_PASSWORD (must meet Moodle complexity)
./tools/moodle_up.sh
docker compose -f deploy/moodle/docker-compose.yml logs -f moodle
```

First boot 3–8 minutes. Do not Ctrl+C the compose process until `up -d` returns; logs `-f` is optional.

- Site: http://127.0.0.1:8888
- User: `admin`
- Password: from `.env` (example `ChangeMeMoodle1`)
- Image: `bitnami/moodle:5.2`
- zig-mdm stays on :8787

If a previous 4.5 attempt left volumes:

```bash
cd ~/MagiMDM/deploy/moodle
docker compose down -v
```

Then `moodle_up.sh` again. `-v` wipes the classroom.

Stop: `docker compose -f deploy/moodle/docker-compose.yml down` (no `-v`).

Bitnami still failing → `docker compose -f deploy/moodle/docker-compose.alpine.yml up -d` (also 5.x-class). See [MOODLE_FIX.md](./MOODLE_FIX.md).

Do **not** publish 8888 on the router.

## Later: MagiMDM

`data/moodle.env`:

```
MOODLE_URL=http://127.0.0.1:8888
MOODLE_WSTOKEN=
```

Versions / restore: [MOODLE_VERSIONS.md](./MOODLE_VERSIONS.md).
