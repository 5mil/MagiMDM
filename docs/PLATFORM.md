# MagiMDM homeschool platform — complete setup

One household product. Three layers. Two processes. One front door.

Repo: https://github.com/5mil/MagiMDM

| Layer | Process | Job |
|-------|---------|-----|
| **mdm** | `zig-mdm` | Devices, policy, comms allowlist, parent/student login |
| **school** | `zig-mdm` (same binary) | NY 100.10 year, children, IHIP, hours, quarterlies, transcript |
| **lms** | `zig-mdm` catalog + outcomes | Unbounded college-format course list, enrollments, grades |
| **learn** | Open edX (Tutor) | Daily classroom: sequences, problems, Studio |

MagiMDM is the **system of record** for compliance and the transcript.
Open edX is the **system of record** for work *inside* a course (attempts, problem scores).
A sync job copies completions into MagiMDM so you never type grades twice.

Do **not** merge Open edX into the Zig binary. Do **not** expose agent enroll ports to the public internet.

---

## 1. Pieces defined

### 1.1 zig-mdm (this repo)

- Listens on `127.0.0.1:8787` (see `src/config.zig`).
- SQLite `data/mdm.db` (keep on the OS SSD).
- Login: local users only (`admin` / then parent / student roles).
- Routes today: `/login`, `/`, `/home`, `/comms`, `/enroll/pc`, `/api/agent/*`, `/api/parent/*`.
- Routes this drop adds as contracts: `/school`, `/lms`, `/api/school/*`, `/api/lms/*`, `/api/learn/sync`.
- Schema: `sql/school.sql`, `sql/lms.sql` (apply with `sqlite3 data/mdm.db < sql/school.sql`).

### 1.2 Open edX (sibling)

- Installed with [Tutor](https://docs.tutor.edly.io/) on the same machine.
- Learner LMS typically on `local.overhang.io` or a Caddy host you choose (`learn.home`).
- Studio for the parent to author/import courses (any number per year).
- Not public edx.org. Family catalog, few concurrent learners.

### 1.3 Caddy (front door)

- `https://mdm.home` → zig-mdm `:8787`
- `https://learn.home` → Open edX LMS
- `https://studio.home` → Open edX Studio (parent only)
- Bind to LAN and/or Tailscale. Prefer **not** a raw public 443 on the router.

### 1.4 Agents

- Student Android Device Owner (`agent/`).
- Student PC (`agent-pc/`).
- Parent apps (`parent-app/`) talk only to zig-mdm.

### 1.5 What is not in this product

- Gibbon PHP SIS (optional extra, not required).
- Moodle (Open edX is the daily classroom).
- NYSED e-file API (you export PDF and email the district).
- Mining on student images.

---

## 2. Data model (school + LMS)

See `sql/school.sql` and `sql/lms.sql`.

```
school_years → children → ihips → ihip_subjects
                → hour_logs
                → quarterlies
                → assessments

courses (unbounded) → enrollments → outcomes
     ↖ openedx_key / institution / credit_hours
```

A course may be:

- `home` — taught at home, logged in MagiMDM only
- `openedx` — daily work in Open edX; MagiMDM stores credits + synced grade
- `college` — dual enrollment; college is the classroom; MagiMDM stores the IHIP row

NY unit reminder: 1 unit ≈ 6,480 minutes (≈108 hours). A 3-credit college course is often treated as 1 unit locally — confirm with your district. Hours toward 900 (grades 1–6) or 990 (7–12) still accumulate from `hour_logs`.

College-track extras (`track=capability`) are *in addition* to `track=legal` 100.10 minima (HS math/science legal floor is 2+2; capability track targets 3–4).

---

## 3. Bring-up today (one machine)

Assumes Ubuntu 26.04.1 LTS Server (or 24.04) on the XPS desktop, Ethernet, user with sudo.

### 3.1 System packages

```bash
sudo apt update
sudo apt install -y git build-essential curl ca-certificates sqlite3 libsqlite3-dev \
  caddy docker.io docker-compose-v2 python3-pip
sudo usermod -aG docker $USER
# log out and back in so docker works
```

Install Zig 0.16 as in [INSTALL.md](./INSTALL.md).

### 3.2 MagiMDM

```bash
git clone https://github.com/5mil/MagiMDM.git
cd MagiMDM
zig build
mkdir -p data
sqlite3 data/mdm.db < sql/school.sql
sqlite3 data/mdm.db < sql/lms.sql
./zig-out/bin/zig-mdm
```

Confirm: `curl -sI http://127.0.0.1:8787/login`

Change admin password immediately (`PLACEHOLDER$` update in SQLite; see INSTALL).

Apply schema on an existing db the same way (`CREATE TABLE IF NOT EXISTS`).

### 3.3 systemd

Copy `deploy/zig-mdm.service`, set `WorkingDirectory` to the clone, `enable --now`.

### 3.4 Open edX via Tutor (daily classroom)

```bash
pip3 install --user "tutor<21"
export PATH="$HOME/.local/bin:$PATH"
tutor local launch
```

Tutor will ask for a platform name and LMS host. For a house box use a LAN name you will put in `/etc/hosts` on every device, e.g. `learn.home`. Do not publish the installer to the whole internet on day one.

Create the parent as Studio staff. Create each child as a learner. Add **any number** of courses for the year.

Document the LMS URL and Studio URL in `data/learn.env`:

```
LEARN_URL=https://learn.home
STUDIO_URL=https://studio.home
```

### 3.5 Caddy

Use `deploy/Caddyfile.platform`. Point `mdm.home` / `learn.home` at this machine in LAN DNS or `/etc/hosts`.

```bash
sudo cp deploy/Caddyfile.platform /etc/caddy/Caddyfile
sudo systemctl enable --now caddy
sudo systemctl reload caddy
```

### 3.6 “Online today” without opening the house

**Preferred:** install Tailscale on the XPS and on parent phones. Share `mdm.home` / `learn.home` on the tailnet. No router port-forward.

**If you must use a public name today:** put only Caddy :443 on the firewall; keep `:8787` and Docker ports on localhost; force strong passwords; do not expose `/api/agent/*` without a shared secret later. Public agent enroll is how random devices join.

### 3.7 First school year row

```bash
sqlite3 data/mdm.db "INSERT INTO school_years(label,starts_on,ends_on,is_current)
  VALUES('2026-27','2026-09-01','2027-06-30',1);"
sqlite3 data/mdm.db "INSERT INTO children(given_name,grade_band,grade) VALUES('Child','9-12',9);"
```

Add courses with no cap:

```bash
sqlite3 data/mdm.db "INSERT INTO courses(code,title,credit_hours,kind,track,nys_bucket)
  VALUES('ENG101','English 9',3,'openedx','legal','english');"
```

Wire `openedx_key` when the Tutor course exists (`course-v1:Org+Eng9+2026`).

### 3.8 Sync stub

`tools/learn_sync.sh` is a placeholder: list enrollments and remind you to paste or API-pull grades into `outcomes`. Replace with Open edX API credentials when Tutor is up.

---

## 4. Daily use

1. Devices: SchoolDay policy (MagiMDM).
2. Student opens `https://learn.home` (Open edX) — allowed app/site during school hours.
3. Parent opens `https://mdm.home` — devices, hours log, course list, quarterly draft.
4. Parent authors in Studio (`studio.home`) when adding a course. No limit per year.
5. After a unit or term, run sync so `outcomes` and `hour_logs` match reality.
6. Quarterly: export from school tables → PDF → email district (no NYSED API).

---

## 5. Roles

| Role | MagiMDM | Open edX |
|------|---------|----------|
| Parent / instructor | Full console | Studio + LMS staff |
| Student | `/lms` status only; no devices/comms | Learner |
| Agent | poll/ack only | none |

---

## 6. Backups

- `data/mdm.db` (zig-mdm) via `deploy/backup.sh`
- Tutor data: `tutor local stop` then copy the Tutor data directory Tutor prints (`$(tutor config printroot)`)
- Keep live DB on SSD; extra disk only for archive copies

---

## 7. Done when (today)

- [ ] zig-mdm serves `/login`
- [ ] school + lms tables exist
- [ ] Caddy routes mdm + learn (even if learn is “coming soon” page)
- [ ] Tailscale or LAN hosts file works from a second device
- [ ] Admin password is not `changeme`
- [ ] At least one child + one course row
- [ ] Open edX launch finished **or** scheduled the same day with Tutor docs

Hardware-agnostic install remains [INSTALL.md](./INSTALL.md).
NY subject lists: [SCHOOL_NYS.md](./SCHOOL_NYS.md).
