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
