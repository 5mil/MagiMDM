# Day 1 Moodle — and why not GitHub Pages

**GitHub Pages cannot host Moodle.** Pages serves static files only (HTML/CSS/JS). Moodle is PHP + MariaDB/MySQL + a `moodledata` disk. There is no “attached database” on Pages. Putting `data/mdm.db` in a Pages repo also would publish the school database to the world.

Same block: Vercel / Netlify static sites. They will not run this stack.

Day 1 you pick **one** of the two paths below. MagiMDM stays on :8787 either way.

---

## Path 1 — Easiest website that is still yours (local Docker)

Already in the repo. Works on WSL or the XPS with Docker Desktop / Engine.

```bash
cd MagiMDM
git pull
cp deploy/moodle/.env.example deploy/moodle/.env
# set MOODLE_PASSWORD and DB passwords
./tools/moodle_up.sh
```

Open http://127.0.0.1:8888 when logs stop looking like first-install.

Login: `admin` + password from `.env`.

**Day 1 in Moodle (30 minutes after it is up):**

1. Site administration → change admin password if you left the example.
2. Site administration → Users → Add a user for the student (email can be fake `@localhost`).
3. Site administration → Courses → Add new course (e.g. Algebra 1). Short name `ALG1`.
4. Enrol the student as Student; you as Teacher.
5. Add one activity: File or Page with today’s work. Optional: a 3-question Quiz.
6. Leave the site on localhost or Tailscale. Do not port-forward 8888.

That is a working website on your LAN. MagiMDM does not sync grades yet — log hours on `/school`.

---

## Path 2 — Easiest *public* website (MoodleCloud trial)

Official hosted Moodle: https://moodlecloud.com/ — **28-day trial**, no card, ~50 users. After trial, Starter is paid (~USD 160/yr class of plan; check current pricing).

1. Sign up, pick region (US Oregon is fine for NYS).
2. Wait for `yoursite.moodlecloud.com`.
3. Same Day 1 clicks as Path 1 (course, student, one activity).
4. In MagiMDM later: `courses.kind=moodle` and `MOODLE_URL=https://yoursite.moodlecloud.com`.

Limits: **no extra plugins**, data lives on Moodle’s AWS, not on the XPS. Fine for a trial week. For a house that wants offline + no vendor, stay on Path 1.

---

## What is *not* Day 1

| Idea | Why not |
|------|--------|
| GitHub Pages + SQLite | Static host; no PHP; DB would be public |
| Shared $3 cPanel “install Moodle” | Works sometimes; you fight PHP versions all year |
| Open edX + Moodle same day | Two classrooms; pick Moodle first |
| MagiMDM grade sync | Not wired; token comes after you can log into Moodle |

---

## When MagiMDM learns the URL

Create `data/moodle.env`:

```
MOODLE_URL=http://127.0.0.1:8888
# or https://yoursite.moodlecloud.com
MOODLE_WSTOKEN=
```

Web-service token: Moodle admin → Site administration → Server → Web services — after Day 1 teaching works.
