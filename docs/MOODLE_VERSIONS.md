# Moodle versions — what “compatible with all” can mean

One running Moodle **cannot** speak every historic release at once. Core rule from Moodle restore:

**A `.mbz` restores onto the same version or a newer one. It does not restore onto an older one.**

So “backwards compatible” for *us* means:

1. MagiMDM treats backups as opaque files (any year).
2. The classroom you run is **new enough** to accept Cloud / Gnomio / old `.mbz` files.
3. You never try to load a Moodle 5 backup into a Moodle 4 container.

| Backup from | Restore onto 4.5 | Restore onto 5.x |
|-------------|------------------|------------------|
| Moodle 3.x / 4.1–4.5 `.mbz` | usually yes | yes |
| MoodleCloud current (4.5-class) | yes | yes |
| Gnomio 5.x `.mbz` | **no** | yes |
| Site SQL dump from Cloud (MySQL) | same major, careful | same or newer |

MagiMDM (`zig-mdm`) does not parse Moodle internals. Compatibility lives in **which image you boot**.

## What we ship

`deploy/moodle/.env`:

```
MOODLE_IMAGE=docker.io/bitnami/moodle:4.5
# Gnomio / Moodle 5 backups:
# MOODLE_IMAGE=docker.io/bitnami/moodle:5.0
```

Default stays 4.5 for Cloud trial restores. Flip the tag, `docker compose up -d`, **on a new volume** if you change major. Do not point 5.x at a 4.5 data volume.

## Do not do

- One container that “emulates all Moodles.”
- Downgrade a live volume.
- Assume plugins from 3.9 still exist on 5.x.

## MagiMDM side

Store `moodle_id`, URL, and `.mbz` paths. Hours and transcript stay in SQLite regardless of Moodle major.
