# Windows install path

Module: `tools/windows/` + `-Dbundle-sqlite=true`.
Same MagiMDM binary family as Linux. **Not** WSL (that is still Linux). This is a native `zig-mdm.exe`.

Repo: https://github.com/5mil/MagiMDM

---

## 1. One-time toolchain

1. Install [Zig](https://ziglang.org/download/) (0.16.x zip). Add the folder to PATH.
2. You do **not** need MSVC for this path if Zig’s MinGW/CRT can compile `sqlite3.c`. If the C compile fails, install [Build Tools for Visual Studio](https://visualstudio.microsoft.com/visual-cpp-build-tools/) with the C++ workload and use `x64 Native Tools` prompt.
3. Git for Windows.

```powershell
git clone https://github.com/5mil/MagiMDM.git
cd MagiMDM
powershell -ExecutionPolicy Bypass -File tools\windows\BUILD.ps1
powershell -ExecutionPolicy Bypass -File tools\windows\RUN.ps1
```

Browser: http://127.0.0.1:8787/login  (`admin` / `changeme` — change immediately).

`BUILD.ps1` fetches the SQLite amalgamation into `third_party/sqlite/` (not stored in git).

---

## 2. Security and Windows-specific constraints

Treat this like a household CA, not a game.

| Topic | What we do |
|-------|------------|
| Bind | Default `127.0.0.1:8787` in `src/config.zig`. Do **not** set `0.0.0.0` unless you intend LAN and you understand the agent API. |
| Firewall | Optional elevated `tools/windows/firewall_localhost.ps1` blocks inbound 8787 from the network. Loopback still works. |
| Cookies | `Secure` stays off until you put Caddy+HTTPS in front. Do not expose HTTP on a public NIC. |
| Privileges | Run as a normal user. Do not run `zig-mdm.exe` as Administrator or SYSTEM. |
| Data | `data\mdm.db` next to the working directory. ACL that folder to your account only. |
| USB | Prefer NTFS. Do not put the live DB on a snatched FAT32 stick without encryption (BitLocker To Go). |
| AV | First run of an unsigned `zig-mdm.exe` may be quarantined. Unblock the file you built; do not disable Defender. |
| Updates | `git pull` then `BUILD.ps1`. Do not download random exes. |
| Agent ports | `/api/agent/*` on a Windows desktop that is also a family PC is a larger attack surface if you bind LAN. Keep localhost until Caddy + tailnet. |
| Services | Do not install as a Windows Service on day one. A console window you can kill is safer while testing. |

Windows is fine for **parent console + Algebra War + mock agent**. Device Owner and Linux student imaging still happen on the devices, not inside this exe.

---

## 3. Cross-compile from WSL (optional)

```bash
# after fetch_sqlite.ps1 has run, or curl the amalgamation yourself
zig build -Dtarget=x86_64-windows-gnu -Dbundle-sqlite=true -Doptimize=ReleaseSafe
```

Copy `zig-out/bin/zig-mdm.exe` to the Windows tree. Still need `web\` and a `data\` folder beside where you start the exe (cwd).

---

## 4. Relation to other install paths

| Path | When |
|------|------|
| Ubuntu on XPS | Always-on house server |
| WSL | Fast test on a Windows laptop |
| `tools/windows` | Native exe, no WSL |
| `tools/usb_hot.sh` | Linux stick |
| `tools/usb_pack.sh` | Student PC imaging |
