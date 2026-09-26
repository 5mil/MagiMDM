# Day 1 Moodle 5.2 — not GitHub Pages

GitHub Pages cannot host Moodle. Use Docker 5.2 on the house PC.

```bash
cd ~/MagiMDM && git pull
cp deploy/moodle/.env.example deploy/moodle/.env
./tools/moodle_up.sh
docker compose -f deploy/moodle/docker-compose.yml logs -f moodle
```

http://127.0.0.1:8888 — `admin` + `.env` password. Image is **5.2**.

Then: add student → course `ALG1` → enrol → one Page or Quiz. No port-forward.

Broken first try: [MOODLE_FIX.md](./MOODLE_FIX.md) (`down -v`, then up again).

MoodleCloud trial is optional public URL only; pull `.mbz` into this 5.2 later.
