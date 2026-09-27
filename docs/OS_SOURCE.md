# Official OS sources for student PCs

Student laptops start from a **project-origin installer**, not a random ISO on a forum.

On tank:

```bash
cd ~/magimdm
chmod +x tools/os_fetch.sh tools/usb_pack.sh
./tools/os_fetch.sh
```

Menu ids:

| id | What you get | Origin |
|----|----------------|--------|
| debian-netinst | current Debian amd64 netinst | https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/ |
| debian-dvd | current Debian amd64 DVD-1 | https://cdimage.debian.org/debian-cd/current/amd64/iso-dvd/ |
| ubuntu-24.04-desktop | Ubuntu 24.04 LTS desktop | https://releases.ubuntu.com/24.04/ |
| ubuntu-24.04-live-server | Ubuntu 24.04 live-server | https://releases.ubuntu.com/24.04/ |
| ubuntu-22.04-desktop | Ubuntu 22.04 LTS desktop | https://releases.ubuntu.com/22.04/ |
| fedora-workstation | Fedora Workstation Live | https://fedoraproject.org/ |
| windows-official | instructions only | https://www.microsoft.com/software-download/windows11 |

Non-interactive:

```bash
./tools/os_fetch.sh debian-netinst
./tools/os_fetch.sh ubuntu-24.04-live-server
MAGIMDM_ISO_DIR=/srv/iso ./tools/os_fetch.sh debian-dvd
```

Files land in `data/iso/` (gitignored). SHA256 is checked against the project `SHA256SUMS` next to the ISO when that file exists.

## Pack a student stick after the ISO is local

```bash
TOKEN=thetoken MDM_URL=http://192.168.50.143:8787 \
  ./tools/usb_pack.sh /tmp/usb linux debian-netinst
```

Third argument is an `os_fetch.sh` id. Skip it if the ISO is already in `data/iso/`.

Then write the **official ISO** to the USB (`dd`, Balena Etcher, Startup Disk Creator, or Rufus). Copy the MagiMDM folder from `/tmp/usb` onto that stick (`zigmdm/`, `user-data` / `Autounattend.xml`).

Do not `dd` a home-built hybrid unless you know that path. The OS bits come from Debian/Ubuntu/Fedora/Microsoft. MagiMDM only drops the agent and autoinstall snippet.

## Windows

There is no honest silent URL that stays stable. Use Microsoft’s page or Media Creation Tool. Put the ISO in `data/iso/` if you want it next to Linux images. `usb_pack.sh windows` writes `iso-hint/WINDOWS_SOURCE.txt` so the stick still explains the source.

## Why this is separate from usb_hot.sh

`tools/usb_hot.sh` is the **parent console** on a stick. `os_fetch.sh` + `usb_pack.sh` are the **student installer**. Do not mix the two sticks.
