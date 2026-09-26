//! MagiMDM console — std.net HTTP + libsqlite3.
const std = @import("std");
const dbmod = @import("db.zig");
const auth = @import("auth.zig");
const enroll_pc = @import("enroll_pc.zig");
const config = @import("config.zig");
const algebra = @import("algebra.zig");

const login_html =
    \\<!DOCTYPE html><html><body style="font-family:sans-serif;background:#020617;color:#e2e8f0;padding:2rem">
    \\<h1>MagiMDM</h1>
    \\<form method="post" action="/login">
    \\Username <input name="username" value="admin"/><br/><br/>
    \\Password <input name="password" type="password"/><br/><br/>
    \\<button>Sign in</button></form>
    \\<p>Default admin / changeme — change immediately.</p></body></html>
;

fn jsonGet(obj: []const u8, key: []const u8) ?[]const u8 {
    var needle_buf: [64]u8 = undefined;
    const needle = std.fmt.bufPrint(&needle_buf, "\"{s}\":" , .{key}) catch return null;
    const i = std.mem.indexOf(u8, obj, needle) orelse return null;
    var p = i + needle.len;
    while (p < obj.len and (obj[p] == ' ')) p += 1;
    if (p >= obj.len) return null;
    if (obj[p] == '"') {
        p += 1;
        const start = p;
        while (p < obj.len and obj[p] != '"') p += 1;
        return obj[start..p];
    }
    const start = p;
    while (p < obj.len and obj[p] != ',' and obj[p] != '}' and obj[p] != ' ') p += 1;
    return obj[start..p];
}
