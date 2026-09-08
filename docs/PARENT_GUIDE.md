# MagiMDM parent guide

Household manual. You run the machines at home. Kids do not get a MagiMDM login.

https://github.com/5mil/MagiMDM

Print a copy. Keep tokens in a notebook that never sits on a student device.

## What sits on the house server

MagiMDM watches phones and laptops and has four buttons: School, Free, Exam, Lock.

Moodle is where lessons and quizzes live.

RosarioSIS is optional. Use it if you want attendance letters, report cards, or a transcript. A first year can be MagiMDM plus Moodle and nothing else.

Parent apps on your phone only watch and tap those four buttons. They do not replace Device Owner on the kid's Android.

The console is https://mdm.home. The parent app is the same account. The student agent is a different APK (`agent/`). Do not install the parent app on the kid's phone.

`src/main.zig` and `src/db.zig` are still missing from public git. You need a built `zig-mdm` on the Mini-ITX before the console exists. Student policies keep mining turned off. Leave it off.

When the server is up:

    TOKEN=dev MDM_URL=http://127.0.0.1:8787 python3 tools/mock_pc_agent.py

You should see an enroll line and poll lines. That is enough.

## First weekend

Install Debian or Ubuntu on the Mini-ITX SSD. Mount the SAS disk at /srv/mdm for backups, APKs, and USB packs.

Build MagiMDM (`zig build`) or drop the binary at /usr/local/bin/zig-mdm. Enable `deploy/zig-mdm.service`. Database path is /var/lib/zigmdm/mdm.sqlite.

Put Caddy in front (`deploy/Caddyfile`) so the LAN uses https://mdm.home. Log in as admin / changeme and change the password the same hour. Only make parent users.

Run `deploy/backup.sh` once and check that a file showed up under /srv/mdm/backups.

Tailscale on the Mini-ITX if you want the parent app away from home. Do not open 443 to the internet.

If MagiMDM is off, devices keep the last policy and stop taking new commands.

Moodle can live on the same box or a VM next to it. RosarioSIS the same. Names that work on Tailscale:

    https://mdm.home
    https://moodle.home
    https://sis.home

## The four buttons

School (SchoolDay): weekdays 08:00–15:00. Firefox should reach Moodle.

Free (AfterHours): evening until curfew.

Exam (ExamLock): tests. Point it at the quiz, not the whole web.

Lock: dinner, bedtime, lost phone.

Sick day is Free plus a line in the audit or on paper. A tutor laptop can stay on Monitor (watch only).

The agents also switch School vs AfterHours from the clock on the device, so you do not have to tap School at 08:00 every morning.

## Kid's Android

Wipe the phone. In the console, make a token labeled with their name and assign SchoolDay.

Install the student agent as Device Owner. Normal Play install is not enough. See agent/README.md.

Enter https://mdm.home (or the Tailscale URL) and the token. The device should show up and last-seen should move within a minute. Reboot. Policy should still be there.

If they can uninstall the agent, it is not Device Owner. Start over.

Write their name and the device uuid in the notebook. Keep the parent PIN off that phone.

## Kid's laptop

Image a blank disk. Do not layer the agent on top of their old Windows install if you want a school machine.

Console: Enroll PC, pick Linux or Windows, make a token. On the server:

    TOKEN=thetoken MDM_URL=https://mdm.home ./tools/usb_pack.sh /tmp/usb windows

Or the same command with linux. Copy that folder onto the installer USB.

Windows: edit Autounattend.xml first. Change ChangeMeParent! and ChangeMeStudent!. Use a licensed Win11 Pro USB. Booting that stick wipes disk 0.

After first boot the device should show platform=windows or linux. Daily login is the student account (no admin). Parent account is for fixes only. Bookmark https://moodle.home in Firefox on the student account.

On Linux the student must not be able to disable zigmdm-agent. On Windows they must not be able to stop ZigMdmAgent.

## School year policies

Templates are in policies/ and sql/policies_school.sql: Baseline, SchoolDay, AfterHours, ExamLock, Weekend, Monitor.

Change hours in the JSON if your day is different. Leave mining.enabled false on every one of them.

SchoolDay already allows Firefox and LibreOffice. Add the Moodle app package later if you install it.

Term dates are in term_calendar (seeded for Fall 2026). Put your dates there.

End of term: tools/audit_export.sh writes a CSV onto the SAS disk.

## Moodle

Install it on the LAN. Serve it at https://moodle.home. Do not put it on the public internet.

One category per child or per subject. You are the teacher. They are the student. Write those usernames next to the MagiMDM token.

From the student device, open Moodle while SchoolDay is on. If it fails, Firefox is missing from the allowlist.

Build exam quizzes in Moodle first. Tap Exam the day before as a dry run.

Day to day the kid works in Moodle and you only touch MagiMDM buttons. RosarioSIS is not required for that.

## RosarioSIS (skip if you do not need records)

Install at https://sis.home. Default is admin / admin. Change it.

School > Configuration > Plugins > Moodle:

- URL https://moodle.home
- REST
- token from Moodle (Site administration > Server > Web services)
- Parent role ID
- student email field set

Create courses in RosarioSIS after that plugin is on, or they never show up in Moodle.

People live in RosarioSIS. Moodle accounts come from the plugin. MagiMDM still only knows devices.

Keep a small map on the Mini-ITX:

    CREATE TABLE IF NOT EXISTS sis_device_map (
      student_name TEXT NOT NULL,
      student_id   TEXT,
      moodle_user  TEXT,
      device_uuid  TEXT NOT NULL,
      asset_tag    TEXT,
      platform     TEXT,
      status       TEXT
    );

Insert a row when you enroll. Lost phone: status=lost and tap Lock. End of year: status=returned and retire the token.

Do not dump call or SMS logs into RosarioSIS.

## Parent app

Install MagiMDM Parent from parent-app/android or parent-app/ios. Not the student agent.

Server URL, parent username, parent password. You should see devices and the four buttons.

Enroll and reimage from the web console at home. The app is for last-seen and School / Free / Exam / Lock when you are out.

If login fails, Tailscale is off, the URL is missing https, or you used a student account.

Moodle and RosarioSIS have their own passwords. Do not reuse the MagiMDM admin one.

## When it breaks

Device missing: never enrolled, or the token was already used.

Last-seen stale: device off, Wi-Fi down, or MagiMDM down.

Kid removed the agent: it was not Device Owner. Reimage.

Laptop ignores policy: the service or task stopped. Log in as parent and start it.

Moodle works on Free but not School: Firefox is not on the SchoolDay allowlist.

New child in RosarioSIS has no Moodle user: plugin was off, or the course existed before the plugin.

Forgot the MagiMDM password: reset the hash in SQLite on the Mini-ITX, not from a kid device.

Lost phone: Lock, mark lost in the map, change the house Wi-Fi password if you need to. Location only works if the phone and the agent allow it.

## What this will not do

It will not catch a second secret phone or a friend's computer.

It does not replace router DNS. Use both.

It is not Apple Family Sharing on a student iPhone. Student devices here are Android, Windows, or Linux. Your management phone can be an iPhone.

A BIOS reset with no firmware password walks around the laptop agent.

Moodle grades do not flow back into RosarioSIS by themselves.

Student devices do not mine. Keep mining.enabled false.

Write house rules the kid has actually read.

## The year

August: new images, new tokens, enroll or reimage, fix term_calendar, make Moodle courses (and RosarioSIS courses if you use it).

Week one: SchoolDay reaches Moodle. Parent app shows last-seen.

Mid-year: reimage one laptop from the USB stick so you know the stick still works.

Exam week: quiz in Moodle, Exam button, practice the day before.

June: audit_export.sh, Moodle backup to /srv/mdm, RosarioSIS rollover if you use it, new parent passwords, copy the MagiMDM database to the SAS disk.

## Weekend check

Mini-ITX on, https://mdm.home loads.

Password changed. Kid has no MagiMDM account.

backup.sh left a file on /srv/mdm/backups.

Android is Device Owner.

Laptop student account has no admin.

School, Free, Exam, and Lock each do something you can see.

Moodle opens during SchoolDay.

Notebook has token, uuid, Moodle user, and SIS id if you use SIS.

mining.enabled is false on every policy.
