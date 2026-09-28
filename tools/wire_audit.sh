#!/bin/sh
set -e
cd "$(dirname "$0")/.."
grep -q 'lists.auditJson' src/main.zig && { echo audit already wired; exit 0; }
grep -q 'lists.devicesJson' src/main.zig || { echo run tools/wire_main.sh first; exit 1; }
python3 - <<'PY'
from pathlib import Path
p = Path("src/main.zig")
s = p.read_text()
needle = 'if (std.mem.eql(u8, method, "GET") and std.mem.eql(u8, path, "/api/parent/comms"))'
insert = '''if (std.mem.eql(u8, method, "GET") and std.mem.eql(u8, path, "/api/parent/audit")) {
        const out = try lists.auditJson(a, conn);
        defer a.free(out);
        return reply(w, "200 OK", "application/json", "", out);
    }
    '''
if needle in s and 'lists.auditJson' not in s:
    s = s.replace(needle, insert + needle)
    p.write_text(s)
    print("audit wired")
else:
    print("no splice point or already present")
PY
