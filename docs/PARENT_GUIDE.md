# MagiMDM parent guide — start to finish

This is the household manual. You run the server at home. Students never log into the console or the parent apps.

Repo: https://github.com/5mil/MagiMDM

---

## 1. What you are setting up

| Piece | Who uses it |
|-------|-------------|
| House Mini-ITX + MagiMDM | Always-on server |
| Web console `https://mdm.home` | You, on a browser |
| Parent app (Android or iPhone) | You, away from the desk |
| Student phone agent | Child's Android, Device Owner |
| Student laptop agent | Child's Windows or Linux PC |

The parent apps **manage and watch**. They do not replace Device Owner on the child's phone.

---

## 2. First weekend (server)

1. Install Debian or Ubuntu on the Mini-ITX **SSD**.
2. Attach the SAS disk (HBA). Mount it at `/srv/mdm` for backups, APKs, USB packs.
3. Build MagiMDM (`zig build`) or copy a binary to `/usr/local/bin/zig-mdm`.
4. Install `deploy/zig-mdm.service`. Database: `/var/lib/zigmdm/mdm.sqlite`.
5. Put Caddy in front (`deploy/Caddyfile`) so you use `https://mdm.home` on the LAN.
6. Open the site, sign in as `admin` / `changeme`, **change the password immediately**.
7. Only create parent users. Do not give the child a console account.
8. Run `deploy/backup.sh` once; confirm a file appears under `/srv/mdm/backups`.
9. Optional: Tailscale on the Mini-ITX so the parent apps work when you are not home. Do not publish port 443 to the whole internet.

If the server is off, devices keep the last policy but will not get new commands.

---

## 3. Daily screen (web or parent app)

After login you should see:

- Each device: name, Android / Windows / Linux, last check-in, current policy
- Four actions: **School**, **Free**, **Exam**, **Lock**

| Button | Policy | Typical use |
|--------|--------|-------------|
| School | SchoolDay | Weekdays 08:00–15:00 |
| Free | AfterHours | Evening until curfew |
| Exam | ExamLock | Tests |
| Lock | lock command | Dinner, bedtime, lost device |

Sick day: Free + a sentence in the audit (or a note on paper). Guest/tutor devices stay on **Monitor** (watch only).

The phone and laptop agents also apply School vs AfterHours from the **clock on the device** so you do not have to tap School at 08:00 every day.

---

## 4. Enroll a student Android phone

1. Wipe the phone (or start unused).
2. On the console: **Tokens** → new token, label with the child's name, assign **SchoolDay**.
3. Install the **student** agent (`agent/` APK) as **Device Owner** (not a normal Play install). Follow `agent/README.md`.
4. Enter `https://mdm.home` (or Tailscale URL) and the token.
5. Confirm the device appears and last-seen updates within a minute.
6. Reboot the phone. Policy must still be there.

The child should not be able to uninstall the agent. If they can, it is not Device Owner — start over.

Store one parent PIN / escape path in your notebook, not on the phone.

---

## 5. Enroll a student laptop (blank disk)

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

Linux: student must not be able to `systemctl disable zigmdm-agent`. Windows: student must not stop `ZigMdmAgent`.

---

## 6. School year settings

Templates already in the repo (`policies/` and `sql/policies_school.sql`):

- Baseline — floor on every device  
- SchoolDay — class hours  
- AfterHours — evening cap  
- ExamLock — tight  
- Weekend  
- Monitor — watch only  

Edit JSON if you need different hours. Keep `mining.enabled` false.

Term dates live in `term_calendar` (seeded for Fall 2026). Change them to your calendar.

End of term: `tools/audit_export.sh` → CSV on the SAS disk.

---

## 7. Parent apps (your phone)

Install **MagiMDM Parent**, not the student agent.

- Android: `parent-app/android`  
- iPhone: `parent-app/ios`  

First launch:

1. Server URL (example `https://mdm.home` or Tailscale name)
2. Parent username + password (same as the web console)
3. You should see the device list and the four buttons

Use the apps to check last-seen and flip School/Free/Exam/Lock. Enroll and reimage are easier on the web console at home.

If login fails: VPN/Tailscale on, URL includes `https://`, account is a parent user.

---

## 8. When something is wrong

| Symptom | What to do |
|---------|------------|
| Device missing from list | Not enrolled, or token already used |
| Last-seen old | Device off, Wi-Fi down, or server down |
| Child uninstalled agent | Not Device Owner / not locked service — reimage or re-enroll |
| Policy ignored on laptop | Agent task/service stopped; log in as parent and fix |
| Forgot parent password | You are admin on the Mini-ITX; reset the hash in SQLite only from there |

Lost student phone: Lock from the app, then change Wi-Fi passwords if needed. Location only works if the agent and OS allow it.

---

## 9. What this does not do

- Control a second secret phone or a friend's computer  
- Replace house router DNS (use both)  
- Match Apple's built-in iCloud family controls on a *student iPhone* (this project images Android + Windows/Linux students; parent *management* apps can be iPhone)  
- Survive a BIOS reset on a laptop with no firmware password  

Write household rules the student has actually seen.

---

## 10. Yearly loop

- August: update images, new tokens, enroll or reimage  
- Mid-year: reimage one laptop from USB to prove the stick still works  
- Exam week: Exam button, rehearsal the day before  
- June: export audit, rotate parent password, copy DB to SAS  

Printed copy of this guide + current tokens notebook stay off the student devices.
