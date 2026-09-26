# Moodle did not come up — reset and retry

The first compose used a MariaDB healthcheck that Bitnami often never passes, so Moodle stayed down. That is fixed on main.

## 1. See what died

```bash
cd ~/MagiMDM
git pull
docker compose -f deploy/moodle/docker-compose.yml ps -a
docker compose -f deploy/moodle/docker-compose.yml logs --tail=80
```

Permission denied on `docker` → `sudo usermod -aG docker $USER` then log out.

`compose: command not found` → `sudo apt install docker-compose-v2` or use `docker-compose`.

Image pull fail → skip to alpine fallback.

## 2. Wipe the broken volumes (no courses yet)

```bash
cd ~/MagiMDM/deploy/moodle
docker compose down
# names look like moodle_mariadb_data — list first
docker volume ls | grep -i moodle
docker compose down -v
```

`-v` deletes the classroom DB. Only if first boot never worked.

## 3. Official-shaped Bitnami (default now)

```bash
cd ~/MagiMDM
git pull
# image default is now moodle:5.2 (4.5 tag is often missing)
./tools/moodle_up.sh
docker compose -f deploy/moodle/docker-compose.yml logs -f moodle
```

Wait 3–8 minutes. Then http://127.0.0.1:8888  admin / `ChangeMeMoodle1` unless you set `.env`.

## 4. If Bitnami still fails — alpine stack

```bash
cd ~/MagiMDM/deploy/moodle
docker compose down -v
docker compose -f docker-compose.alpine.yml up -d
docker compose -f docker-compose.alpine.yml logs -f moodle
```

Same URL :8888.
