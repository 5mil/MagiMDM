# Hot-plug USB console

Alternative to installing MagiMDM on the XPS or only in WSL: the **stick is the app**. Plug in, run, unplug. Database stays on the stick.

This is **not** the student imaging pack (`tools/usb_pack.sh`). That writes Autounattend/autoinstall for a blank PC. This pack is the **parent console**.

## What lives on the stick

```
MagiMDM-USB/
  src/ web/ sql/ tools/ build.zig
  zig/                 optional portable Zig (Linux x86_64)
  zig-out/bin/zig-mdm  after first compile
  data/mdm.db          created on first run — keep this folder
  RUN.sh               Linux / WSL
  BUILD.sh             compile on the stick
```

Needs from the **host** (not copied): `libsqlite3.so` (package `libsqlite3-dev` / `libsqlite3-0`) and a glibc Linux userland. WSL Ubuntu is fine. A random Windows `E:\` double-click will not run the Linux binary; use WSL:

```bash
cd /mnt/e/MagiMDM-USB   # letter will vary
./BUILD.sh
./RUN.sh
```

Then Windows browser: http://127.0.0.1:8787/login

## Build the stick (once, from a clone)

Plug a USB formatted ext4 or exFAT (exFAT is OK for the tree; ext4 is kinder to SQLite).

```bash
cd MagiMDM
./tools/usb_hot.sh /mnt/e/MagiMDM-USB
```

Add Zig onto the stick (optional, so the next cafe PC does not need `/opt/zig`):

```bash
./tools/usb_hot.sh /mnt/e/MagiMDM-USB --with-zig
```

## Each plug-in

```bash
./BUILD.sh    # only if sources changed
./RUN.sh      # cwd must be the USB tree so data/ stays on the stick
```

Do not run two copies against the same `data/mdm.db`. Eject only after the process exits.

## Limits

- Linux/WSL binary. Not a Windows `.exe` yet.
- Open edX will not fit a casual USB stick.
- `libsqlite3` must exist on the host.
- Treat the stick like a key: anyone with it has the parent console and the DB.
