//! JSON lists from SQLite for the desk.
const std = @import("std");
const dbmod = @import("db.zig");
const c = @import("sqlite_c.zig");

fn col(stmt: ?*c.sqlite3_stmt, i: c_int) []const u8 {
    const raw = c.sqlite3_column_text(stmt, i) orelse return "";
    return std.mem.sliceTo(raw, 0);
}

fn esc(a: std.mem.Allocator, s: []const u8) ![]u8 {
    var out = std.ArrayList(u8).init(a);
    for (s) |ch| {
        switch (ch) {
            '"' => try out.appendSlice("\\\""),
            '\\' => try out.appendSlice("\\\\"),
            '\n' => try out.appendSlice("\\n"),
            else => try out.append(ch),
        }
    }
    return out.toOwnedSlice();
}

pub fn devicesJson(a: std.mem.Allocator, conn: *dbmod.Conn) ![]u8 {
    var stmt: ?*c.sqlite3_stmt = null;
    const sql = "SELECT uuid,ifnull(name,''),platform,status,ifnull(last_seen_at,'') FROM devices ORDER BY id DESC LIMIT 50";
    if (c.sqlite3_prepare_v2(conn.db, sql, -1, &stmt, null) != c.SQLITE_OK) {
        return try a.dupe(u8, "{\"devices\":[]}");
    }
    defer _ = c.sqlite3_finalize(stmt);
    var buf = std.ArrayList(u8).init(a);
    try buf.appendSlice("{\"devices\":[");
    var first = true;
    while (c.sqlite3_step(stmt) == c.SQLITE_ROW) {
        if (!first) try buf.appendSlice(",");
        first = false;
        const uuid = try esc(a, col(stmt, 0));
        defer a.free(uuid);
        const name = try esc(a, col(stmt, 1));
        defer a.free(name);
        const plat = try esc(a, col(stmt, 2));
        defer a.free(plat);
        const st = try esc(a, col(stmt, 3));
        defer a.free(st);
        const seen = try esc(a, col(stmt, 4));
        defer a.free(seen);
        try buf.writer().print("{{\"uuid\":\"{s}\",\"name\":\"{s}\",\"platform\":\"{s}\",\"status\":\"{s}\",\"last_seen_at\":\"{s}\"}}", .{ uuid, name, plat, st, seen });
    }
    try buf.appendSlice("]}");
    return buf.toOwnedSlice();
}

pub fn commsJson(a: std.mem.Allocator, conn: *dbmod.Conn) ![]u8 {
    var stmt: ?*c.sqlite3_stmt = null;
    const sql = "SELECT ifnull(peer,''),direction,kind,allowed FROM comms_log ORDER BY id DESC LIMIT 50";
    if (c.sqlite3_prepare_v2(conn.db, sql, -1, &stmt, null) != c.SQLITE_OK) {
        return try a.dupe(u8, "{\"events\":[]}");
    }
    defer _ = c.sqlite3_finalize(stmt);
    var buf = std.ArrayList(u8).init(a);
    try buf.appendSlice("{\"events\":[");
    var first = true;
    while (c.sqlite3_step(stmt) == c.SQLITE_ROW) {
        if (!first) try buf.appendSlice(",");
        first = false;
        const peer = try esc(a, col(stmt, 0));
        defer a.free(peer);
        const dir = try esc(a, col(stmt, 1));
        defer a.free(dir);
        const kind = try esc(a, col(stmt, 2));
        defer a.free(kind);
        const al = col(stmt, 3);
        try buf.writer().print("{{\"peer\":\"{s}\",\"direction\":\"{s}\",\"kind\":\"{s}\",\"allowed\":{s}}}", .{ peer, dir, kind, if (al.len > 0) al else "1" });
    }
    try buf.appendSlice("]}");
    return buf.toOwnedSlice();
}
