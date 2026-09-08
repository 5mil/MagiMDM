//! MagiMDM console — std.net HTTP + libsqlite3.
const std = @import("std");
const dbmod = @import("db.zig");
const auth = @import("auth.zig");
const enroll_pc = @import("enroll_pc.zig");
const config = @import("config.zig");

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

fn formGet(body: []const u8, key: []const u8) ?[]const u8 {
    var it = std.mem.splitScalar(u8, body, '&');
    while (it.next()) |pair| {
        var kv = std.mem.splitScalar(u8, pair, '=');
        const k = kv.next() orelse continue;
        const v = kv.next() orelse "";
        if (std.mem.eql(u8, k, key)) return v;
    }
    return null;
}

fn cookieSid(headers: []const u8) ?[]const u8 {
    const i = std.mem.indexOf(u8, headers, "zigmdm_session=") orelse return null;
    const start = i + "zigmdm_session=".len;
    var end = start;
    while (end < headers.len and headers[end] != ';' and headers[end] != '\r' and headers[end] != '\n') end += 1;
    return headers[start..end];
}

fn reply(w: anytype, code: []const u8, ctype: []const u8, extra_headers: []const u8, body: []const u8) !void {
    try w.print("HTTP/1.1 {s}\r\nContent-Type: {s}\r\nContent-Length: {d}\r\nConnection: close\r\n{s}\r\n", .{ code, ctype, body.len, extra_headers });
    try w.writeAll(body);
}

fn loadFile(a: std.mem.Allocator, path: []const u8) ?[]u8 {
    return std.fs.cwd().readFileAlloc(a, path, 1_000_000) catch null;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const a = gpa.allocator();
    const cfg = config.Config{};
    std.fs.cwd().makePath("data") catch {};
    var conn = dbmod.Conn.open("data/mdm.db") catch |e| {
        std.debug.print("db open failed: {s} (install libsqlite3-dev)\n", .{@errorName(e)});
        return e;
    };
    defer conn.close();

    const addr = try std.net.Address.parseIp(cfg.host, cfg.port);
    var server = try addr.listen(.{ .reuse_address = true });
    std.debug.print("MagiMDM http://{s}:{d}/login  db=data/mdm.db\n", .{ cfg.host, cfg.port });

    while (true) {
        var conn_c = server.accept() catch continue;
        defer conn_c.stream.close();
        handle(a, &conn, &conn_c.stream) catch |e| {
            std.debug.print("req err {s}\n", .{@errorName(e)});
        };
    }
}

fn handle(a: std.mem.Allocator, conn: *dbmod.Conn, stream: *std.net.Stream) !void {
    var buf: [65536]u8 = undefined;
    const n = try stream.read(&buf);
    if (n == 0) return;
    const req = buf[0..n];
    const head_end = std.mem.indexOf(u8, req, "\r\n\r\n") orelse return;
    const head = req[0..head_end];
    const body = req[head_end + 4 ..];
    const line_end = std.mem.indexOf(u8, head, "\r\n") orelse return;
    const line = head[0..line_end];
    var it = std.mem.splitScalar(u8, line, ' ');
    const method = it.next() orelse return;
    const path = it.next() orelse return;
    const w = stream.writer();

    if (std.mem.eql(u8, method, "GET") and std.mem.eql(u8, path, "/login")) {
        return reply(w, "200 OK", "text/html", "", login_html);
    }
    if (std.mem.eql(u8, method, "POST") and std.mem.eql(u8, path, "/login")) {
        const user = formGet(body, "username") orelse "";
        const pass = formGet(body, "password") orelse "";
        const q = try std.fmt.allocPrintSentinel(a, "SELECT password_hash FROM users WHERE username='{s}' LIMIT 1", .{user}, 0);
        defer a.free(q);
        const hash = try conn.queryText(a, q);
        var ok = false;
        if (hash) |h| {
            defer a.free(h);
            ok = auth.verifyPassword(a, undefined, pass, h);
        }
        if (!ok) return reply(w, "401 Unauthorized", "text/plain", "", "bad login\n");
        const tok = try auth.generateSessionToken(a);
        defer a.free(tok);
        const ins = try std.fmt.allocPrintSentinel(a, "INSERT INTO sessions(id,user_id,expires_at) VALUES('{s}',1,datetime('now','+12 hours'))", .{tok}, 0);
        defer a.free(ins);
        conn.exec(ins) catch {};
        const setc = try std.fmt.allocPrint(a, "Set-Cookie: zigmdm_session={s}; Path=/; HttpOnly; SameSite=Lax; Max-Age=43200\r\nLocation: /\r\n", .{tok});
        defer a.free(setc);
        return reply(w, "302 Found", "text/plain", setc, "ok");
    }
    if (std.mem.eql(u8, method, "GET") and std.mem.eql(u8, path, "/logout")) {
        return reply(w, "302 Found", "text/plain", "Set-Cookie: zigmdm_session=; Max-Age=0; Path=/\r\nLocation: /login\r\n", "");
    }

    if (std.mem.eql(u8, method, "POST") and std.mem.eql(u8, path, "/api/agent/enroll")) {
        const token = jsonGet(body, "token") orelse "";
        const name = jsonGet(body, "name") orelse "device";
        var plat = jsonGet(body, "platform") orelse "android";
        plat = enroll_pc.normalizePlatform(plat);
        const slug = jsonGet(body, "image_slug") orelse "";
        const uuid = jsonGet(body, "uuid") orelse blk: {
            break :blk try auth.generateSessionToken(a);
        };
        const ins = try std.fmt.allocPrintSentinel(a, "INSERT INTO devices(uuid,name,platform,enrollment_token,status) VALUES('{s}','{s}','{s}','{s}','enrolled')", .{ uuid, name, plat, token }, 0);
        defer a.free(ins);
        conn.exec(ins) catch {};
        if (slug.len > 0) {
            const bind = try std.fmt.allocPrintSentinel(a, "INSERT OR REPLACE INTO device_images(device_id,image_id) SELECT d.id,i.id FROM devices d, images i WHERE d.uuid='{s}' AND i.slug='{s}'", .{ uuid, slug }, 0);
            defer a.free(bind);
            conn.exec(bind) catch {};
        }
        const out = try std.fmt.allocPrint(a, "{{"ok":true,"uuid":"{s}","device_id":{d}}}", .{ uuid, conn.lastId() });
        defer a.free(out);
        return reply(w, "200 OK", "application/json", "", out);
    }
    if (std.mem.eql(u8, method, "POST") and std.mem.eql(u8, path, "/api/agent/poll")) {
        const uuid = jsonGet(body, "uuid") orelse "";
        const touch = try std.fmt.allocPrintSentinel(a, "UPDATE devices SET last_seen_at=datetime('now'), status='enrolled' WHERE uuid='{s}'", .{uuid}, 0);
        defer a.free(touch);
        conn.exec(touch) catch {};
        const pol = try conn.queryText(a, "SELECT config_json FROM policies WHERE name='SchoolDay' LIMIT 1");
        const cfg = if (pol) |p| p else "{}";
        const out = try std.fmt.allocPrint(a, "{{"ok":true,"device_id":1,"commands":[],"policy":{{"id":1,"name":"SchoolDay","config":{s}}}}}", .{cfg});
        defer a.free(out);
        return reply(w, "200 OK", "application/json", "", out);
    }
    if (std.mem.eql(u8, method, "POST") and std.mem.eql(u8, path, "/api/agent/ack")) {
        return reply(w, "200 OK", "application/json", "", "{"ok":true}");
    }
    if (std.mem.eql(u8, method, "POST") and std.mem.eql(u8, path, "/api/agent/comms-log")) {
        const uuid = jsonGet(body, "uuid") orelse "";
        const peer = jsonGet(body, "peer") orelse "";
        const dir = jsonGet(body, "direction") orelse "in";
        const kind = jsonGet(body, "kind") orelse "call";
        const sql = try std.fmt.allocPrintSentinel(a, "INSERT INTO comms_log(device_id,direction,kind,peer,allowed) SELECT id,'{s}','{s}','{s}',1 FROM devices WHERE uuid='{s}'", .{ dir, kind, peer, uuid }, 0);
        defer a.free(sql);
        conn.exec(sql) catch {};
        return reply(w, "200 OK", "application/json", "", "{"ok":true}");
    }

    const sid = cookieSid(head);
    const authed = if (sid) |s| blk: {
        const q = try std.fmt.allocPrintSentinel(a, "SELECT user_id FROM sessions WHERE id='{s}' AND expires_at>datetime('now')", .{s}, 0);
        defer a.free(q);
        break :blk (try conn.queryText(a, q)) != null;
    } else false;

    if (std.mem.eql(u8, path, "/api/parent/devices") or std.mem.eql(u8, path, "/api/parent/comms") or std.mem.eql(u8, path, "/") or std.mem.eql(u8, path, "/home") or std.mem.eql(u8, path, "/comms") or std.mem.startsWith(u8, path, "/enroll")) {
        if (!authed) return reply(w, "302 Found", "text/plain", "Location: /login\r\n", "");
    }

    if (std.mem.eql(u8, method, "GET") and std.mem.eql(u8, path, "/api/parent/devices")) {
        return reply(w, "200 OK", "application/json", "", "{"devices":[]}");
    }
    if (std.mem.eql(u8, method, "GET") and std.mem.eql(u8, path, "/api/parent/comms")) {
        return reply(w, "200 OK", "application/json", "", "{"events":[]}");
    }
    if (std.mem.eql(u8, method, "GET") and (std.mem.eql(u8, path, "/") or std.mem.eql(u8, path, "/home"))) {
        if (loadFile(a, "web/home.html")) |html| return reply(w, "200 OK", "text/html", "", html);
        return reply(w, "200 OK", "text/html", "", "<a href=/enroll/pc>Enroll PC</a> <a href=/comms>Comms</a>");
    }
    if (std.mem.eql(u8, method, "GET") and std.mem.eql(u8, path, "/enroll/pc")) {
        if (loadFile(a, "web/enroll_pc.html")) |html| return reply(w, "200 OK", "text/html", "", html);
    }
    if (std.mem.eql(u8, method, "GET") and std.mem.eql(u8, path, "/comms")) {
        if (loadFile(a, "web/comms.html")) |html| return reply(w, "200 OK", "text/html", "", html);
    }
    if (std.mem.eql(u8, method, "POST") and std.mem.eql(u8, path, "/enroll/pc")) {
        const tok = try auth.generateSessionToken(a);
        defer a.free(tok);
        const ins = try std.fmt.allocPrintSentinel(a, "INSERT INTO enrollment_tokens(token,label) VALUES('{s}','pc')", .{tok}, 0);
        defer a.free(ins);
        conn.exec(ins) catch {};
        const page = try std.fmt.allocPrint(a, "<pre>TOKEN={s}\n./tools/usb_pack.sh /tmp/usb linux</pre>", .{tok});
        defer a.free(page);
        return reply(w, "200 OK", "text/html", "", page);
    }
    if (std.mem.eql(u8, method, "POST") and std.mem.eql(u8, path, "/devices/bulk")) {
        return reply(w, "200 OK", "text/plain", "", "queued\n");
    }

    return reply(w, "404 Not Found", "text/plain", "", "not found\n");
}
