# MagiMDM parent guide — start to finish

This is the household manual. You run the servers at home. Students never log into the MagiMDM console or the parent apps.

Repo: https://github.com/5mil/MagiMDM

Print this + keep a tokens notebook **off** student devices.

---

## 0. What you are combining

Three separate programs. Do not merge them into one app.

| System | Job | Who uses it |
|--------|-----|-------------|
| **MagiMDM** | Enroll phones/laptops, School / Free / Exam / Lock | Parent only |
| **Moodle** | Lessons, quizzes, files, classwork | Parent assigns; student does work |
| **RosarioSIS** (optional) | Roster, attendance, report cards, transcripts | Parent / teacher |

| MagiMDM piece | Who uses it |
|---------------|-------------|
| House Mini-ITX + MagiMDM | Always-on server |
| Web console `https://mdm.home` | You, on a browser |
| Parent app (Android or iPhone) | You, away from the desk |
| Student phone agent | Child's Android, Device Owner |
| Student laptop agent | Child's Windows or Linux PC |

Parent apps **manage and watch**. They do not replace Device Owner on the child's phone.

Moodle is classwork. MagiMDM is the device. RosarioSIS is paper-trail records. A single-family homeschool can run **MagiMDM + Moodle only** and add RosarioSIS later.

### Honest status (read this)

Public git still needs `src/main.zig` and `src/db.zig` before `zig build` produces a live console. Follow this guide on the Mini-ITX once that binary exists. Student policy templates keep `mining.enabled: false`. Leave it that way.

Self-test when the server is up:

```bash
TOKEN=dev MDM_URL=http://127.0.0.1:8787 python3 tools/mock_pc_agent.py
```

You want an enroll printout and repeating `poll` lines. That is “it works.” Mining to a pool is not a household goal.

---

## 1. First weekend — house server

1. Install Debian or Ubuntu on the Mini-ITX **SSD**.
2. Attach the SAS disk (HBA). Mount it at `/srv/mdm` for backups, APKs, USB packs, Moodle backups.
3. Build MagiMDM (`zig build`) or copy a binary to `/usr/local/bin/zig-mdm`.
4. Install `deploy/zig-mdm.service`. Database: `/var/lib/zigmdm/mdm.sqlite`.
5. Put Caddy in front (`deploy/Caddyfile`) so you use `https://mdm.home` on the LAN.
6. Open the site, sign in as `admin` / `changeme`, **change the password immediately**.
7. Only create parent users. Do not give the child a MagiMDM account.
8. Run `deploy/backup.sh` once; confirm a file appears under `/srv/mdm/backups`.
9. Optional: Tailscale on the Mini-ITX so parent apps work when you are not home. Do **not** publish port 443 to the whole internet.

If MagiMDM is off, devices keep the last policy but will not get new commands.

Same box (or a second VM on the same LAN) later hosts Moodle and, if you want records, RosarioSIS. Point all three at Tailscale names, for example:

- `https://mdm.home`
- `https://moodle.home`
- `https://sis.home` (optional)

---

## 2. Daily screen (web or parent app)

After MagiMDM login you should see:

- Each device: name, Android / Windows / Linux, last check-in, current policy
- Four actions: **School**, **Free**, **Exam**, **Lock**

| Button | Policy | Typical use | Classwork |
|--------|--------|-------------|-----------|
| School | SchoolDay | Weekdays 08:00–15:00 | Firefox / Moodle allowed |
| Free | AfterHours | Evening until curfew | Moodle optional |
| Exam | ExamLock | Tests | Kiosk / quiz only |
| Lock | lock command | Dinner, bedtime, lost device | Nothing |

Sick day: **Free** + a sentence in the audit (or a note on paper). Guest/tutor devices stay on **Monitor** (watch only).

The phone and laptop agents also apply School vs AfterHours from the **clock on the device** so you do not have to tap School at 08:00 every day.

---

## 3. Enroll a student Android phone

1. Wipe the phone (or start unused).
2. On the console: **Tokens** → new token, label with the child's name, assign **SchoolDay**.
3. Install the **student** agent (`agent/` APK) as **Device Owner** (not a normal Play install). Follow `agent/README.md`.
4. Enter `https://mdm.home` (or Tailscale URL) and the token.
5. Confirm the device appears and last-seen updates within a minute.
6. Reboot the phone. Policy must still be there.
7. Write the child's name + `device.uuid` in the notebook (and in the map table in §7).

The child should not be able to uninstall the agent. If they can, it is not Device Owner — start over.

Store one parent PIN / escape path in your notebook, not on the phone.

---

## 4. Enroll a student laptop (blank disk)

The laptop is built during enroll. Do not install the agent on top of the child's existing Windows install if you want a clean school machine.

1. Console → **Enroll PC** → Linux or Windows → create token.
2. On the server:

   ```bash
   TOKEN=thetoken MDM_URL=https://mdm.home ./tools/usb_pack.sh /tmp/usb windows
   # or: ./tools/usb_pack.sh /tmp/usb linux
   ```

3. Copy that folder onto the installer USB.
4. **Windows:** edit `Autounattend.xml` and change `ChangeMeParent!` / `ChangeMeStudent!` first. Use a licensed Win11 Pro USB.
5. Boot the laptop from USB. The disk will be wiped.
6. After first boot the agent enrolls. The console shows `platform=windows` or `linux`.
7. Log in as **parent** for admin work. Daily use is the **student** account (no admin).
8. Bookmark `https://moodle.home` in Firefox on the student account.

Linux: student must not be able to `systemctl disable zigmdm-agent`. Windows: student must not stop `ZigMdmAgent`.

---

## 5. School year settings (MagiMDM)

Templates already in the repo (`policies/` and `sql/policies_school.sql`):

- Baseline — floor on every device
- SchoolDay — class hours
- AfterHours — evening cap
- ExamLock — tight
- Weekend
- Monitor — watch only

Edit JSON if you need different hours. **Keep `mining.enabled` false** on every template.

Put Moodle in the school-hours allowlist so class time can reach classwork:

```json
"apps_allow": [
  "org.mozilla.firefox",
  "org.documentfoundation.libreoffice"
]
```

Add the official Moodle app package later if you install it. ExamLock stays kiosk / single-task — point it at the quiz URL, not the whole web.

Term dates live in `term_calendar` (seeded for Fall 2026). Change them to your calendar.

End of term: `tools/audit_export.sh` → CSV on the SAS disk.

---

## 6. Moodle — classwork (do this before RosarioSIS)

Moodle is enough for lessons. MagiMDM does not store grades.

1. Install Moodle on the LAN (same Mini-ITX VM or a neighbor VM). Reach it at `https://moodle.home` through Caddy / Tailscale. Do not expose it to the public internet.
2. Create one category per child or per subject.
3. Create the parent as a teacher (or manager). Create the student as a student. Write those usernames in the notebook next to the MagiMDM token.
4. On the student laptop/phone, confirm Firefox can open Moodle **while SchoolDay is on**.
5. Exam week: build the quiz in Moodle first, tap **Exam** on MagiMDM the day before as a rehearsal.

Daily: child does work in Moodle. You flip MagiMDM buttons. You do not need RosarioSIS for that loop.

---

## 7. RosarioSIS — optional records

Add RosarioSIS when you want attendance letters, report cards, or a formal transcript. Skip this section for a first year if Moodle + MagiMDM is enough.

1. Install RosarioSIS (`https://sis.home`). Default login is `admin` / `admin` — change it.
2. School → Configuration → Plugins → Moodle:
   - Moodle URL = `https://moodle.home`
   - API = REST
   - Token from Moodle (Site administration → Server → Web services)
   - Parent role ID from Moodle
   - Student email field set
3. Create courses in RosarioSIS **after** the plugin is live, or they will not appear in Moodle.
4. People live in RosarioSIS. Moodle accounts are created by the plugin. MagiMDM still only knows devices.

### Bind a child to a device

Keep one map on the Mini-ITX (SQLite is fine):

```sql
CREATE TABLE IF NOT EXISTS sis_device_map (
  student_name TEXT NOT NULL,
  student_id   TEXT,          -- RosarioSIS STUDENT_ID when you have SIS
  moodle_user  TEXT,
  device_uuid  TEXT NOT NULL, -- MagiMDM devices.uuid
  asset_tag    TEXT,
  platform     TEXT,          -- android | windows | linux
  status       TEXT           -- assigned | lost | returned
);
```

On enroll, insert one row. On lost phone, set `status=lost` and tap **Lock**. On withdraw / end of year, set `returned` and retire the token.

Do not copy SMS bodies or comms logs into RosarioSIS.

---

## 8. Parent apps (your phone)

Install **MagiMDM Parent**, not the student agent.

- Android: `parent-app/android`
- iPhone: `parent-app/ios`

First launch:

1. Server URL (`https://mdm.home` or Tailscale name)
2. Parent username + password (same as the web console)
3. Device list + the four buttons

Use the apps to check last-seen and flip School / Free / Exam / Lock. Enroll and reimage are easier on the web console at home.

If login fails: Tailscale on, URL includes `https://`, account is a parent user.

Moodle and RosarioSIS have their own logins. Do not reuse the MagiMDM admin password there.

---

## 9. When something is wrong

| Symptom | What to do |
|---------|------------|
| Device missing from list | Not enrolled, or token already used |
| Last-seen old | Device off, Wi-Fi down, or MagiMDM down |
| Child uninstalled agent | Not Device Owner / not locked service — reimage or re-enroll |
| Policy ignored on laptop | Agent task/service stopped; log in as parent and fix |
| Moodle opens on Free but not School | SchoolDay allowlist missing Firefox / Moodle |
| Moodle user missing after adding a child in RosarioSIS | Plugin off, or course existed before the plugin |
| Forgot MagiMDM parent password | Reset the hash in SQLite **on the Mini-ITX only** |

Lost student phone: **Lock** from the app, mark `lost` in the map table, change Wi-Fi passwords if needed. Location only works if the agent and OS allow it.

---

## 10. What this stack does not do

- Control a second secret phone or a friend's computer
- Replace house router DNS (use both)
- Match Apple's iCloud family controls on a *student iPhone* (student devices are Android + Windows/Linux; parent *management* apps can be iPhone)
- Survive a BIOS reset on a laptop with no firmware password
- Pull Moodle grades back into RosarioSIS automatically
- Mine crypto on student devices — leave `mining.enabled` false

Write household rules the student has actually seen.

---

## 11. Yearly loop

- **August:** update images, new tokens, enroll or reimage; set `term_calendar`; create Moodle courses (and RosarioSIS courses if you use SIS)
- **Week one:** confirm SchoolDay reaches Moodle; confirm parent app last-seen
- **Mid-year:** reimage one laptop from USB to prove the stick still works
- **Exam week:** Moodle quiz ready, Exam button, rehearsal the day before
- **June:** `tools/audit_export.sh`, Moodle backup to `/srv/mdm`, RosarioSIS rollover if used, rotate parent passwords, copy MagiMDM DB to SAS

---

## 12. Weekend checklist (short)

- [ ] Mini-ITX on, Caddy serving `https://mdm.home`
- [ ] MagiMDM password changed; child has no console account
- [ ] `deploy/backup.sh` produced a file on `/srv/mdm/backups`
- [ ] Student Android is Device Owner and cannot uninstall the agent
- [ ] Student laptop student account has no admin
- [ ] School / Free / Exam / Lock all do something visible
- [ ] Moodle opens during SchoolDay
- [ ] Notebook has token, uuid, Moodle user (and SIS id if used)
- [ ] `mining.enabled` is false on every policy
