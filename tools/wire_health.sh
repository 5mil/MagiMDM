#!/bin/sh
set -e
cd "$(dirname "$0")/.."
grep -q 'path, "/health"' src/main.zig && { echo health already wired; exit 0; }
python3 - <<'PY'
from pathlib import Path
p = Path("src/main.zig")
s = p.read_text()
block = '''    if (std.mem.eql(u8, method, "GET") and std.mem.eql(u8, path, "/health")) {
        return reply(w, "200 OK", "application/json", "", "{\\"ok\\":true,\\"app\\":\\"magimdm\\"}");
    }
'''
needle = 'if (std.mem.eql(u8, method, "GET") and std.mem.eql(u8, path, "/login"))'
if needle in s:
    s = s.replace(needle, block + '    ' + needle, 1)
    p.write_text(s)
    print("health wired")
else:
    print("no login splice point")
PY
