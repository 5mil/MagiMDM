# MagiMDM parent guide

Household manual. You run the machines at home. Kids do not get a MagiMDM login.

https://github.com/5mil/MagiMDM

Print a copy. Keep tokens in a notebook that never sits on a student device.

Server install, start to finish: docs/SERVER_SETUP.md

## What you are running

MagiMDM is the device box. Four buttons on the desk: School, Free, Exam, Lock.

Moodle is classwork. Lessons and quizzes live there.

RosarioSIS is optional. Use it for attendance letters, report cards, or a transcript. Year one can be MagiMDM plus Moodle.

The web console is http://127.0.0.1:8787 or https://mdm.home behind Caddy. The parent app uses the same parent account. The student agent is a different APK under agent/. Do not put the parent app on the kid's phone.

Student policies keep mining off. Leave it off.

src/main.zig and src/db.zig are on GitHub main. Pull the tree. Do not copy those files by hand.

## Hardware

Any always-on Linux box on the house LAN works. Examples: leftover desktop, NUC, mini PC, used ThinkCentre, a VM on a NAS, a Raspberry Pi 5 if you can get Zig 0.16 on it. x86_64 is the path of least pain. ARM is fine if you build from source.

You need:

- disk that survives a reboot (SSD is enough)
- a folder for backups, APKs, and USB packs (USB disk, second partition, NAS share, or just /var/backups/mdm)
- the box stays on during school hours
- it is not a student laptop

One machine can host MagiMDM, Moodle, and RosarioSIS. Or split them across VMs. Names stay the same either way.

This guide uses /opt/MagiMDM and /srv/mdm as path examples. Change them if your box is laid out differently. What matters is one working directory and one database file.

## Clone and build

Need Zig 0.16. Distro packages will be too old. Use the official tarball for your CPU. The numbered cookbook is docs/SERVER_SETUP.md.

    TOKEN=dev MDM_URL=http://127.0.0.1:8787 python3 tools/mock_pc_agent.py

## Console pages you will actually use

/login — parent sign in

/ — four buttons and a device list

/enroll — make a one-use token for a phone

/enroll/pc — make a token and print the usb_pack.sh line for a laptop

/devices/bulk — the four buttons POST here (policy=SchoolDay|AfterHours|ExamLock or command=lock)

/api/parent/devices — JSON the parent app and the home page fetch

/api/agent/enroll, /poll, /ack — what the student agent talks to

Do not give those /api/agent URLs to a kid to type. The agent holds the token.

## The four buttons

School (SchoolDay): weekdays 08:00-15:00. Firefox should reach Moodle.

Free (AfterHours): evening until curfew.

Exam (ExamLock): tests. Point it at the quiz, not the whole web.

Lock: dinner, bedtime, lost phone. Queues a lock command on every enrolled device. The next poll picks it up.

Sick day is Free plus a line in the audit or on paper. A tutor laptop can stay on Monitor.

The agents also switch School vs AfterHours from the clock on the device.

## Kid's Android

Wipe the phone. On /enroll make a token labeled with their name. Do not reuse the lab token "dev" on a real phone.

Install the student agent as Device Owner. Play Store install is not enough. See agent/README.md.

Enter https://mdm.home (or your Tailscale/WireGuard name) and the token. The device should appear. Last-seen should move within a minute. Reboot. Policy should still be there.

If they can uninstall the agent, it is not Device Owner. Start over.

Write name and uuid in the notebook. Keep the parent PIN off that phone.

## Kid's laptop

Image a blank disk. Do not layer the agent on an old Windows install if you want a school machine.

On /enroll/pc pick Linux or Windows, submit, copy the token off the result page.

    TOKEN=thetoken MDM_URL=https://mdm.home /opt/MagiMDM/tools/usb_pack.sh /tmp/usb windows

Same command with linux for Debian. Copy that folder onto the installer USB. Park a copy under /srv/mdm/usb.

Windows: edit Autounattend.xml first. Change ChangeMeParent! and ChangeMeStudent!. Licensed Win11 Pro USB. That stick wipes disk 0.

After first boot the console should show platform=windows or linux. Daily login is student (no admin). Parent account is for fixes. Bookmark https://moodle.home in Firefox on the student account.

Linux student must not disable zigmdm-agent. Windows student must not stop ZigMdmAgent.

## Policies

Seeded on first launch: Baseline, SchoolDay, AfterHours, ExamLock, Weekend, Monitor.

Change hours in the JSON if your day is different. mining.enabled stays false.

SchoolDay allows Firefox and LibreOffice. Add the Moodle app later if you install it.

Term dates are in term_calendar (Fall 2026 seed). Put your dates there.

End of term: tools/audit_export.sh writes a CSV into your backup folder.

## Moodle

Install on the LAN. https://moodle.home. Not on the public internet.

You are the teacher. They are the student. Write those usernames next to the MagiMDM token.

Open Moodle from the student device while SchoolDay is on. If that fails, Firefox is missing from the allowlist.

Build exam quizzes in Moodle first. Tap Exam the day before.

Day to day the kid works in Moodle. You only touch MagiMDM buttons. RosarioSIS is not required for that.

## RosarioSIS (skip if you do not need records)

https://sis.home. Default admin / admin. Change it.

School > Configuration > Plugins > Moodle. URL https://moodle.home, REST, token from Moodle web services, parent role ID, student email field set.

Create courses in RosarioSIS after the plugin is on, or they never show up in Moodle.

People live in RosarioSIS. Moodle accounts come from the plugin. MagiMDM only knows devices.

Keep a map on the MagiMDM host:

    sqlite3 /opt/MagiMDM/data/mdm.db

    CREATE TABLE IF NOT EXISTS sis_device_map (
      student_name TEXT NOT NULL,
      student_id   TEXT,
      moodle_user  TEXT,
      device_uuid  TEXT NOT NULL,
      asset_tag    TEXT,
      platform     TEXT,
      status       TEXT
    );

Enroll: insert a row. Lost phone: status=lost and tap Lock. End of year: status=returned and retire the token.

Do not dump call or SMS logs into RosarioSIS.

## Parent app

Install MagiMDM Parent from parent-app/android or parent-app/ios. Not the student agent.

Server URL https://mdm.home or the VPN name. Parent username and password. You should see devices and the four buttons. Those buttons hit /devices/bulk the same way the web desk does.

Enroll and reimage from the web console at home.

If login fails: VPN off, URL missing https, or you used the wrong account.

Moodle and RosarioSIS have their own passwords. Do not reuse the MagiMDM admin one.

## When it breaks

zig-mdm will not start: missing vendor/zqlite or vendor/httpz, Zig is not 0.16, or WorkingDirectory is wrong.

Two database files: you started the binary once from the clone and once from elsewhere. Use one working directory and the symlink above.

Device missing: never enrolled, or the token was already used. The lab token "dev" allows 100 uses. Real tokens are one use.

Last-seen stale: device off, Wi-Fi down, or MagiMDM down.

Kid removed the agent: not Device Owner. Reimage.

Laptop ignores policy: service or task stopped. Log in as parent and start it.

Moodle works on Free but not School: Firefox not on the SchoolDay allowlist.

New child in RosarioSIS has no Moodle user: plugin was off, or the course existed before the plugin.

Forgot the MagiMDM password:

    sqlite3 /opt/MagiMDM/data/mdm.db
    UPDATE users SET password_hash = 'PLACEHOLDER$newpass' WHERE username = 'admin';

Then sign in with that and change it again if you want.

Lost phone: Lock, mark lost in the map, change house Wi-Fi if you need to.

## What this will not do

It will not catch a second secret phone or a friend's computer.

It does not replace router DNS. Use both.

It is not Apple Family Sharing on a student iPhone. Student devices here are Android, Windows, or Linux. Your management phone can be an iPhone.

A BIOS reset with no firmware password walks around the laptop agent.

Moodle grades do not flow back into RosarioSIS by themselves.

Student devices do not mine.

Write house rules the kid has actually read.

## The year

August: git pull, zig build, new tokens, enroll or reimage, fix term_calendar, make Moodle courses.

Week one: SchoolDay reaches Moodle. mock_pc_agent or a real device shows last-seen.

Mid-year: reimage one laptop from the USB stick.

Exam week: quiz in Moodle, Exam button, practice the day before.

June: audit_export.sh, Moodle backup into /srv/mdm, RosarioSIS rollover if you use it, new parent passwords, copy data/mdm.db onto the backup disk.

## Weekend check

https://mdm.home/login or http://127.0.0.1:8787/login loads.

Password is no longer changeme. Kid has no MagiMDM account.

backup.sh left a file in the backup folder.

Android is Device Owner.

Laptop student account has no admin.

School, Free, Exam, and Lock each do something you can see.

Moodle opens during SchoolDay.

Notebook has token, uuid, Moodle user.

mining.enabled is false on every policy.

git -C /opt/MagiMDM log -1 shows main.zig and db.zig on the tree.
