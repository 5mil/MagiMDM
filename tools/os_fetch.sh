#!/bin/sh
# Download student-PC installer ISOs from project origin servers only.
# Verify SHA256 when the project publishes SHA256SUMS next to the file.
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
STORE=${MAGIMDM_ISO_DIR:-$ROOT/data/iso}
mkdir -p "$STORE"

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "need $1 (apt install wget ca-certificates coreutils)" >&2
    exit 1
  }
}
need wget
need sha256sum

fetch_verified() {
  # $1 dest-dir-url (must contain SHA256SUMS) $2 filename
  base=$1
  file=$2
  dest=$STORE/$file
  echo "GET $base/$file"
  wget -c -O "$dest.part" "$base/$file"
  wget -q -O "$STORE/SHA256SUMS.$file" "$base/SHA256SUMS" || wget -q -O "$STORE/SHA256SUMS.$file" "$base/SHA256SUMS.txt" || {
    echo "no SHA256SUMS at $base — leaving $dest.part unverified" >&2
    mv "$dest.part" "$dest"
    echo "$dest"
    return 0
  }
  (cd "$STORE" && grep -E " ([*]?)$file$" "SHA256SUMS.$file" | sha256sum -c -) || {
    echo "checksum failed for $file" >&2
    exit 1
  }
  mv "$dest.part" "$dest"
  echo "OK $dest"
}

# Pin names that change with point releases: discover from SHA256SUMS when possible.
pick_from_sums() {
  # $1 sums-url $2 grep pattern
  wget -q -O- "$1" | awk -v p="$2" '$0 ~ p {print $NF; exit}' | tr -d '*'
}

fetch_debian_netinst() {
  base=https://cdimage.debian.org/debian-cd/current/amd64/iso-cd
  file=$(pick_from_sums "$base/SHA256SUMS" 'debian-.*-amd64-netinst.iso')
  [ -n "$file" ] || file=debian-13.0.0-amd64-netinst.iso
  fetch_verified "$base" "$file"
}

fetch_debian_dvd() {
  base=https://cdimage.debian.org/debian-cd/current/amd64/iso-dvd
  file=$(pick_from_sums "$base/SHA256SUMS" 'debian-.*-amd64-DVD-1.iso')
  [ -n "$file" ] || { echo "could not name DVD-1 from SHA256SUMS" >&2; exit 1; }
  fetch_verified "$base" "$file"
}

fetch_ubuntu() {
  # $1 series dir e.g. 24.04 $2 pattern
  rel=$1
  pat=$2
  base=https://releases.ubuntu.com/$rel
  file=$(pick_from_sums "$base/SHA256SUMS" "$pat")
  [ -n "$file" ] || { echo "no Ubuntu file matching $pat in $rel" >&2; exit 1; }
  fetch_verified "$base" "$file"
}

fetch_fedora() {
  echo "Fedora uses a locator URL; following redirects from getfedora."
  dest=$STORE/Fedora-Workstation-Live-x86_64.iso
  wget -c -O "$dest.part" \
    "https://download.fedoraproject.org/pub/fedora/linux/releases/42/Workstation/x86_64/iso/Fedora-Workstation-Live-x86_64-42-1.1.iso" \
    || wget -c -O "$dest.part" "https://download.fedoraproject.org/pub/fedora/linux/releases/41/Workstation/x86_64/iso/Fedora-Workstation-Live-x86_64-41-1.4.iso"
  mv "$dest.part" "$dest"
  echo "OK $dest (verify at https://fedoraproject.org/verify)"
}

windows_help() {
  cat <<'EOF'
Windows 11 Pro must come from Microsoft. MagiMDM will not mirror an ISO.

On a Windows PC you already own:
  https://www.microsoft.com/software-download/windows11
  — Media Creation Tool, or “Download disk image (ISO)”

On tank (Linux) you can only store an ISO you already downloaded:
  mkdir -p data/iso
  cp /path/to/Win11_*.iso data/iso/

Then:
  TOKEN=… MDM_URL=… ./tools/usb_pack.sh /tmp/usb windows
  # copy Autounattend.xml + zigmdm/ onto the official installer USB

Do not use unofficial “Windows ISO” blogs. Those are not source.
EOF
}

usage() {
  cat <<EOF
Usage:
  $0                  # interactive menu
  $0 list
  $0 debian-netinst
  $0 debian-dvd
  $0 ubuntu-24.04-desktop
  $0 ubuntu-24.04-live-server
  $0 ubuntu-22.04-desktop
  $0 fedora-workstation
  $0 windows-official   # prints Microsoft source steps (no silent ISO)

ISOs land in: $STORE
Override: MAGIMDM_ISO_DIR=/bigdisk/iso $0 debian-netinst
EOF
}

list() {
  cat <<'EOF'
 id                      origin
 --                      ------
 debian-netinst          cdimage.debian.org current amd64 netinst + SHA256SUMS
 debian-dvd              cdimage.debian.org current amd64 DVD-1 + SHA256SUMS
 ubuntu-24.04-desktop    releases.ubuntu.com/24.04 desktop + SHA256SUMS
 ubuntu-24.04-live-server releases.ubuntu.com/24.04 live-server + SHA256SUMS
 ubuntu-22.04-desktop    releases.ubuntu.com/22.04 desktop + SHA256SUMS
 fedora-workstation      download.fedoraproject.org Workstation Live x86_64
 windows-official        microsoft.com/software-download/windows11 (manual)
EOF
}

run_id() {
  case $1 in
    debian-netinst) fetch_debian_netinst ;;
    debian-dvd) fetch_debian_dvd ;;
    ubuntu-24.04-desktop) fetch_ubuntu 24.04 'ubuntu-24.04.*desktop-amd64.iso' ;;
    ubuntu-24.04-live-server) fetch_ubuntu 24.04 'ubuntu-24.04.*live-server-amd64.iso' ;;
    ubuntu-22.04-desktop) fetch_ubuntu 22.04 'ubuntu-22.04.*desktop-amd64.iso' ;;
    fedora-workstation) fetch_fedora ;;
    windows-official) windows_help ;;
    list) list ;;
    -h|--help|help) usage ;;
    *) echo "unknown id: $1" >&2; usage; exit 1 ;;
  esac
}

if [ "${#}" -gt 0 ]; then
  run_id "$1"
  exit 0
fi

list
echo
printf 'Select id [debian-netinst]: '
read -r choice || true
choice=${choice:-debian-netinst}
run_id "$choice"
