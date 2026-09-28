#!/bin/sh
# One-time: splice lists.zig into src/main.zig if still stubbed.
set -e
cd "$(dirname "$0")/.."
grep -q 'lists.devicesJson' src/main.zig && { echo already wired; exit 0; }
python3 - <<'PY'
from pathlib import Path
p = Path("src/main.zig")
s = p.read_text()
if 'lists.zig' not in s:
    s = s.replace('const ui = @import("ui.zig");', 'const ui = @import("ui.zig");\nconst lists = @import("lists.zig");')
s = s.replace('or std.mem.eql(u8, path, "/settings") or std.mem.startsWith(u8, path, "/enroll")',
              'or std.mem.eql(u8, path, "/settings") or std.mem.eql(u8, path, "/ai") or std.mem.startsWith(u8, path, "/enroll")')
s = s.replace('return reply(w, "200 OK", "application/json", "", "{\\"devices\\":[]}");',
              'const out = try lists.devicesJson(a, conn);\n        defer a.free(out);\n        return reply(w, "200 OK", "application/json", "", out);')
s = s.replace('return reply(w, "200 OK", "application/json", "", "{\\"events\\":[]}");',
              'const out = try lists.commsJson(a, conn);\n        defer a.free(out);\n        return reply(w, "200 OK", "application/json", "", out);')
if 'web/ai.html' not in s:
    s = s.replace('try page(a, w, "web/settings.html");\n        return;\n    }',
                  'try page(a, w, "web/settings.html");\n        return;\n    }\n    if (std.mem.eql(u8, method, "GET") and std.mem.eql(u8, path, "/ai")) {\n        try page(a, w, "web/ai.html");\n        return;\n    }')
s = s.replace('return reply(w, "302 Found", "text/plain", "Location: /\\r\\n", "queued\\n");',
              'const pol = formGet(body, "policy") orelse "SchoolDay";\n        conn.exec("DELETE FROM device_policies") catch {};\n        const q = try std.fmt.allocPrintSentinel(a, "INSERT OR IGNORE INTO device_policies(device_id,policy_id) SELECT d.id,p.id FROM devices d, policies p WHERE p.name='{s}'", .{pol}, 0);\n        defer a.free(q);\n        conn.exec(q) catch {};\n        return reply(w, "302 Found", "text/plain", "Location: /\\r\\n", "applied\\n");')
p.write_text(s)
print("wired", "lists.devicesJson" in s)
PY
