# MagiMDM — onboard and manage devices

This is the working handbook for adding phones and laptops to a home MagiMDM box.
Server on this house: tank at **192.168.50.143**

- Desk: http://192.168.50.143:8787/login
- Add device: http://192.168.50.143:8787/enroll/pc
- Moodle (separate login): http://learn.home:8888 or http://192.168.50.143:8888

Print the QR sheet from the desk. Keep tokens off student devices.

Repo: https://github.com/5mil/MagiMDM

---

## What “enrolled” means

An enrolled device:

1. Has a one-use (or limited-use) token that only you created.
2. Talks to `/api/agent/enroll` then `/api/agent/poll`.
3. Shows up on the desk after the first successful poll.
4. Cannot drop the agent without a wipe (Android Device Owner, or PC image + parent-only admin).

If the kid can tap Uninstall and the agent vanishes, it is **not** enrolled. Start over from a blank device.

---

## Before any device

On tank:

```bash
ss -tlnp | grep 8787
curl -sS -D- --max-time 5 http://127.0.0.1:8787/login | head
```

You want `0.0.0.0:8787` and HTTP 200.

On the laptop browser: http://192.168.50.143:8787/login  (`admin` / `changeme` until you change it).

Wi-Fi for student devices must reach **192.168.50.143**. Guest Wi-Fi that isolates clients will fail enrollment.

Optional local names in `/etc/hosts` on tank **and** the parent laptop:

```text
192.168.50.143    learn.home mdm.home
```

Windows hosts file: `C:\Windows\System32\drivers\etc\hosts`

---

## Path A — blank Android (factory reset + QR)

Use this for a new or wiped phone. Do not enroll a phone the kid already uses as their daily driver unless you accept a wipe.

### 1. Make a token

Desk → **Add device** → platform **Android (blank / QR)** → child name → Create.

Write in the notebook:

- child name
- token
- date

Do not reuse `dev` on a real phone.

### 2. Host the student APK on the LAN

The factory QR must download the agent. Until the console serves `/agent.apk`, put a copy on tank:

```bash
# after you build agent/ in Android Studio, copy the APK
mkdir -p ~/magimdm/data/apk
cp /path/to/app-debug.apk ~/magimdm/data/apk/agent.apk
# temporary: python static file on :8788 if zig-mdm does not serve APKs yet
cd ~/magimdm/data/apk && python3 -m http.server 8788 --bind 0.0.0.0
```

UFW: allow 8788 from `192.168.0.0/16` only if you use that helper.

QR download URL becomes `http://192.168.50.143:8788/agent.apk` (or `:8787/agent.apk` once the console serves it).

### 3. Six-tap setup

1. Wipe the phone (Settings → factory reset) or unbox it.
2. On the **Hello / Hi** language screen tap the same spot **six times**. A QR scanner opens.
3. Scan the **Blank Android** QR from the desk (or the printout).
4. Join house Wi-Fi when asked.
5. Wait. The phone pulls the APK, sets Device Owner, and should POST enroll by itself if extras include `server` + `token`.
6. If the agent opens and asks for URL + token, type:
   - URL: `http://192.168.50.143:8787`
   - token: the one you just created

### 4. Prove it

- Desk device list / last-seen moves within a minute.
- Reboot the phone. Agent still there.
- Settings → security / device admin shows ZigMDM Agent and **cannot** be turned off without wipe.

If Uninstall works, you sideloaded a normal app. Wipe and use the six-tap QR again.

### AFW QR payload (what the desk encodes)

```json
{
  "android.app.extra.PROVISIONING_DEVICE_ADMIN_COMPONENT_NAME": "com.zigmdm.agent/.MdmDeviceAdminReceiver",
  "android.app.extra.PROVISIONING_DEVICE_ADMIN_PACKAGE_DOWNLOAD_LOCATION": "http://192.168.50.143:8788/agent.apk",
  "android.app.extra.PROVISIONING_DEVICE_ADMIN_PACKAGE_CHECKSUM": "",
  "android.app.extra.PROVISIONING_SKIP_ENCRYPTION": true,
  "android.app.extra.PROVISIONING_LEAVE_ALL_SYSTEM_APPS_ENABLED": true,
  "android.app.extra.PROVISIONING_ADMIN_EXTRAS_BUNDLE": {
    "server": "http://192.168.50.143:8787",
    "token": "YOUR_TOKEN"
  }
}
```

Checksum: after you have a release APK, `sha256sum agent.apk` and put the hex in the QR. Debug builds can omit it on some OEMs; Pixel / stock Android is pickier.

---

## Path B — Android that already has an account (not blank)

Worse than Path A. The kid can often remove a normal app.

Only use this for a lab phone.

1. Create a token on the desk.
2. Enable unknown sources.
3. Open `http://192.168.50.143:8788/agent.apk` on the phone and install.
4. Open ZigMDM Agent. Enter server + token. Scan the **Already set up** QR if the agent has a scan button; otherwise type the values.
5. Enable device admin when asked.
6. Accept that this is **not** Device Owner unless you factory-reset.

---

## Path C — blank Windows laptop

1. Desk → Add device → **Windows 11** → Create token.
2. On tank:

```bash
cd ~/magimdm
TOKEN=thetoken MDM_URL=http://192.168.50.143:8787 ./tools/usb_pack.sh /tmp/usb windows
```

3. Edit `agent-pc/windows/Autounattend.xml` passwords (`ChangeMeParent!` / `ChangeMeStudent!`) **before** you copy the stick.
4. Licensed Windows 11 Pro USB + the pack files. That stick **wipes disk 0**.
5. Boot the laptop from USB. First logon runs `enroll.ps1`.
6. Daily account is `student` (no admin). Parent account is for repair only.

---

## Path D — blank Linux laptop

1. Desk → Add device → **Linux** → Create token.
2. On tank:

```bash
TOKEN=thetoken MDM_URL=http://192.168.50.143:8787 ./tools/usb_pack.sh /tmp/usb linux
```

3. Debian 12 installer + `autoinstall.yaml` from `agent-pc/linux/`.
4. After first boot, `zigmdm-agent.service` must be enabled. Student user must not be in sudo if you can avoid it.

---

## Path E — iPhone / iPad

Student MDM on iOS needs Apple Business/School Manager + a signed MDM payload. MagiMDM does **not** do that yet.

- Parent **management** phone can be an iPhone (`parent-app/ios`) talking to the desk.
- A **student** iPhone is not a MagiMDM-controlled device today. Use Android for the kid, or keep the iPhone on Apple Family Sharing only.

Do not tell a parent to “just scan the Android QR” on an iPhone. It will not become Device Owner.

---

## After it appears on the desk

| Check | Pass |
|--------|------|
| Name / platform correct | android, linux, or windows |
| last-seen moves | within ~1 min, and after reboot |
| School day button | browser to Moodle works, play stores / extra browsers blocked if policy says so |
| Lock button | next poll locks |
| Kid cannot uninstall agent | wipe required to remove |

Notebook line:

```text
child | platform | token-used | uuid | date | asset-tag
```

---

## Day-to-day management (1–10 devices)

Four desk buttons POST `/devices/bulk`:

- **School day** — SchoolDay policy
- **After hours** — AfterHours
- **Exam lock** — ExamLock
- **Lock** — lock command on every enrolled device

Per-device policy assignment UI is still thin. Until it lands, bulk buttons plus the seeded policies (`Baseline`, `SchoolDay`, `AfterHours`, `ExamLock`, `Weekend`, `Monitor`) are the house controls.

Calls/SMS: `/comms`. Only native call/SMS the Android agent can see.

Lost device: Lock, mark lost in the notebook, change Wi-Fi if needed.

---

## Why adding a device felt hard

The live console had login and poll, but:

- `/enroll` was not a guided sheet (token + QR + USB on one page).
- Factory Android needs an APK URL in the QR. The agent APK is built from `agent/`, not from `zig build`.
- PC enrollment needs a USB pack (`tools/usb_pack.sh`), not a typed token on the laptop desktop.
- Tokens are one-use. A second try with the same token looks like “it does nothing.”

Use this page + Path A or C. Do not invent a fourth method.

---

## Failures

| Symptom | Likely cause |
|---------|----------------|
| Token page never appears | not signed in; POST body not read (old binary) |
| Phone cannot open 192.168.50.143 | guest Wi-Fi, VPN, wrong VLAN |
| QR camera never opens | you are past the Hello screen; wipe again |
| APK download fails | :8788 not running, UFW, HTTP vs HTTPS |
| Agent installs but uninstalls | not Device Owner |
| Device never listed | enroll POST never hit; watch tank log `req err` |
| last-seen frozen | agent killed, Wi-Fi down, zig-mdm not running |
| Windows ignored policy | scheduled task stopped; log in as parent |

Lab probe from tank (no phone needed):

```bash
TOKEN=thetoken MDM_URL=http://127.0.0.1:8787 python3 ~/magimdm/tools/mock_pc_agent.py
```

---

## Build the Android agent (once per release)

On a machine with Android Studio:

```text
Open agent/
Build → Build Bundle(s) / APK(s) → Build APK(s)
Copy app-debug.apk to tank:~/magimdm/data/apk/agent.apk
```

Until that APK exists, Path A QR can still carry server+token for a manual install, but six-tap Device Owner will fail the download step.
