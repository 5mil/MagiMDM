# Moodle versions — we run 5.2

**Shipped default:** `docker.io/bitnami/moodle:5.2`

Restore rule: a `.mbz` loads onto the **same or newer** Moodle. Not onto an older one.

| Backup from | Restore onto **5.2** (what we run) |
|-------------|--------------------------------------|
| Moodle 3.x / 4.x `.mbz` | yes |
| MoodleCloud | yes (forward) |
| Gnomio 5.x `.mbz` | yes |
| Moodle 5.2 `.mbz` | yes |
| Newer than 5.2 | no — bump the image tag first |

Do not boot 4.5 to “be compatible.” 4.5 cannot take Gnomio 5 backups. 5.2 takes both.

Change major only on **new volumes** (`docker compose down -v`). Never point 5.2 at a half-installed 4.5 volume.

`deploy/moodle/.env`:

```
MOODLE_IMAGE=docker.io/bitnami/moodle:5.2
```
