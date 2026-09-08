//! SQLite access for MagiMDM. Schema from sql/*.sql, applied on open.

const std = @import("std");
const zqlite = @import("zqlite");
const enroll_pc = @import("enroll_pc.zig");

pub const Conn = struct {
    raw: zqlite.Conn,
    mu: std.Thread.Mutex = .{},

    pub fn open(path: []const u8) !Conn {
        if (std.fs.path.dirname(path)) |dir| {
            std.fs.cwd().makePath(dir) catch {};
        }
        const flags = zqlite.OpenFlags.Create | zqlite.OpenFlags.EXResCode;
        const raw = try zqlite.open(path, flags);
        var c = Conn{ .raw = raw };
        try c.execNoArgs(
            \\
PRAGMA journal_mode = WAL;
            \\
PRAGMA foreign_keys = ON;
        );
        try c.applySchema();
        return c;
    }

    pub fn close(self: *Conn) void {
        self.raw.close();
    }

    pub fn exec(self: *Conn, sql: []const u8, args: anytype) !void {
        self.mu.lock();
        defer self.mu.unlock();
        try self.raw.exec(sql, args);
    }

    pub fn execNoArgs(self: *Conn, sql: [:0]const u8) !void {
        self.mu.lock();
        defer self.mu.unlock();
        try self.raw.execNoArgs(sql);
    }

    pub fn lastId(self: *Conn) i64 {
        self.mu.lock();
        defer self.mu.unlock();
        return self.raw.lastInsertedRowId();
    }

    pub fn applySchema(self: *Conn) !void {
        try self.execNoArgs(
            \\
CREATE TABLE IF NOT EXISTS users (
            \\
    id INTEGER PRIMARY KEY AUTOINCREMENT,
            \\
    username TEXT NOT NULL UNIQUE COLLATE NOCASE,
            \\
    password_hash TEXT NOT NULL,
            \\
    display_name TEXT,
            \\
    is_active INTEGER NOT NULL DEFAULT 1,
            \\
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
            \\
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
            \\
);
            \\
CREATE TABLE IF NOT EXISTS sessions (
            \\
    id TEXT PRIMARY KEY,
            \\
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            \\
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
            \\
    expires_at TEXT NOT NULL,
            \\
    ip TEXT,
            \\
    user_agent TEXT
            \\
);
            \\
CREATE TABLE IF NOT EXISTS devices (
            \\
    id INTEGER PRIMARY KEY AUTOINCREMENT,
            \\
    uuid TEXT NOT NULL UNIQUE,
            \\
    name TEXT,
            \\
    platform TEXT NOT NULL DEFAULT 'android',
            \\
    model TEXT,
            \\
    os_version TEXT,
            \\
    agent_version TEXT,
            \\
    enrollment_token TEXT,
            \\
    status TEXT NOT NULL DEFAULT 'pending',
            \\
    last_seen_at TEXT,
            \\
    battery_pct INTEGER,
            \\
    extras_json TEXT,
            \\
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
            \\
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
            \\
);
            \\
CREATE TABLE IF NOT EXISTS enrollment_tokens (
            \\
    id INTEGER PRIMARY KEY AUTOINCREMENT,
            \\
    token TEXT NOT NULL UNIQUE,
            \\
    label TEXT,
            \\
    created_by INTEGER REFERENCES users(id),
            \\
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
            \\
    expires_at TEXT,
            \\
    used_at TEXT,
            \\
    used_by_device INTEGER REFERENCES devices(id),
            \\
    max_uses INTEGER NOT NULL DEFAULT 1,
            \\
    use_count INTEGER NOT NULL DEFAULT 0
            \\
);
            \\
CREATE TABLE IF NOT EXISTS commands (
            \\
    id INTEGER PRIMARY KEY AUTOINCREMENT,
            \\
    device_id INTEGER NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
            \\
    type TEXT NOT NULL,
            \\
    payload_json TEXT,
            \\
    status TEXT NOT NULL DEFAULT 'pending',
            \\
    created_by INTEGER REFERENCES users(id),
            \\
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
            \\
    sent_at TEXT,
            \\
    acked_at TEXT,
            \\
    result_json TEXT
            \\
);
            \\
CREATE TABLE IF NOT EXISTS audit_log (
            \\
    id INTEGER PRIMARY KEY AUTOINCREMENT,
            \\
    actor_user_id INTEGER REFERENCES users(id),
            \\
    actor_device_id INTEGER REFERENCES devices(id),
            \\
    action TEXT NOT NULL,
            \\
    target_type TEXT,
            \\
    target_id TEXT,
            \\
    detail_json TEXT,
            \\
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
            \\
);
            \\
CREATE TABLE IF NOT EXISTS policies (
            \\
    id INTEGER PRIMARY KEY AUTOINCREMENT,
            \\
    name TEXT NOT NULL UNIQUE,
            \\
    description TEXT,
            \\
    config_json TEXT NOT NULL DEFAULT '{}',
            \\
    is_default INTEGER NOT NULL DEFAULT 0,
            \\
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
            \\
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
            \\
);
            \\
CREATE TABLE IF NOT EXISTS device_policies (
            \\
    device_id INTEGER NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
            \\
    policy_id INTEGER NOT NULL REFERENCES policies(id) ON DELETE CASCADE,
            \\
    assigned_at TEXT NOT NULL DEFAULT (datetime('now')),
            \\
    PRIMARY KEY (device_id, policy_id)
            \\
);
            \\
CREATE TABLE IF NOT EXISTS packages (
            \\
    id INTEGER PRIMARY KEY AUTOINCREMENT,
            \\
    filename TEXT NOT NULL,
            \\
    label TEXT,
            \\
    sha256 TEXT,
            \\
    size_bytes INTEGER,
            \\
    created_by INTEGER REFERENCES users(id),
            \\
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
            \\
);
            \\
CREATE TABLE IF NOT EXISTS images (
            \\
    id INTEGER PRIMARY KEY AUTOINCREMENT,
            \\
    slug TEXT NOT NULL UNIQUE,
            \\
    label TEXT NOT NULL,
            \\
    os TEXT NOT NULL,
            \\
    arch TEXT NOT NULL DEFAULT 'x86_64',
            \\
    source_path TEXT,
            \\
    sha256 TEXT,
            \\
    seed_json TEXT NOT NULL DEFAULT '{}',
            \\
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
            \\
);
            \\
CREATE TABLE IF NOT EXISTS device_images (
            \\
    device_id INTEGER NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
            \\
    image_id INTEGER NOT NULL REFERENCES images(id),
            \\
    applied_at TEXT NOT NULL DEFAULT (datetime('now')),
            \\
    PRIMARY KEY (device_id)
            \\
);
            \\
CREATE TABLE IF NOT EXISTS comms_log (
            \\
    id INTEGER PRIMARY KEY AUTOINCREMENT,
            \\
    device_id INTEGER NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
            \\
    ts TEXT NOT NULL DEFAULT (datetime('now')),
            \\
    direction TEXT NOT NULL,
            \\
    kind TEXT NOT NULL,
            \\
    peer TEXT,
            \\
    allowed INTEGER NOT NULL DEFAULT 1,
            \\
    meta_json TEXT,
            \\
    body TEXT
            \\
);
            \\
CREATE INDEX IF NOT EXISTS comms_log_dev_ts ON comms_log(device_id, ts);
            \\
CREATE TABLE IF NOT EXISTS term_calendar (
            \\
    id INTEGER PRIMARY KEY AUTOINCREMENT,
            \\
    name TEXT NOT NULL,
            \\
    starts_on TEXT NOT NULL,
            \\
    ends_on TEXT NOT NULL,
            \\
    kind TEXT NOT NULL DEFAULT 'term'
            \\
);
        );
        try self.execNoArgs(
            \\
INSERT OR IGNORE INTO policies (name, description, config_json, is_default) VALUES
            \\
('Baseline', 'Floor for every student device',
            \\
 '{"mining":{"enabled":false},"install_lock":true,"unknown_sources":false,"encryption":true}', 1),
            \\
('SchoolDay', 'Weekday class hours',
            \\
 '{"mining":{"enabled":false},"mode":"school","hours":{"start":"08:00","end":"15:00","days":[1,2,3,4,5]},"apps_allow":["org.mozilla.firefox","org.documentfoundation.libreoffice"],"install_lock":true,"camera":false,"usb_file_transfer":false}', 0),
            \\
('AfterHours', 'Evening cap',
            \\
 '{"mining":{"enabled":false},"mode":"after","hours":{"start":"15:00","end":"20:00"},"curfew":"20:00","install_lock":true}', 0),
            \\
('ExamLock', 'Single-task exam',
            \\
 '{"mining":{"enabled":false},"mode":"exam","kiosk":true,"install_lock":true,"camera":false}', 0),
            \\
('Weekend', 'Weekend lighter rules',
            \\
 '{"mining":{"enabled":false},"mode":"weekend","curfew":"21:00"}', 0),
            \\
('Monitor', 'Inventory only (tutor/guest)',
            \\
 '{"mining":{"enabled":false},"mode":"monitor","enforce":false}', 0);
            \\
INSERT OR IGNORE INTO term_calendar (id, name, starts_on, ends_on, kind) VALUES
            \\
(1, 'Fall', '2026-08-17', '2026-12-18', 'term'),
            \\
(2, 'Winter break', '2026-12-19', '2027-01-04', 'break'),
            \\
(3, 'Spring', '2027-01-05', '2027-05-29', 'term'),
            \\
(4, 'Exam week fall', '2026-12-14', '2026-12-18', 'exam');
            \\
INSERT OR IGNORE INTO images (slug, label, os, seed_json) VALUES
            \\
('linux-debian12-student', 'Debian 12 student', 'linux',
            \\
 '{"hostname_prefix":"student","student_user":"student","admin_user":"parent"}'),
            \\
('windows11-student', 'Windows 11 student', 'windows',
            \\
 '{"hostname_prefix":"STUDENT","student_user":"student","admin_user":"parent"}');
        );
    }

    pub fn bootstrapAdmin(self: *Conn, username: []const u8, password: []const u8) !void {
        var buf: [96]u8 = undefined;
        const hash = try std.fmt.bufPrint(&buf, "PLACEHOLDER${s}", .{password});
        try self.exec(
            "INSERT OR IGNORE INTO users (username, password_hash, display_name) VALUES (?1, ?2, ?3)",
            .{ username, hash, username },
        );
        try self.exec(
            "INSERT OR IGNORE INTO enrollment_tokens (token, label, max_uses) VALUES ('dev', 'lab-mock', 100)",
            .{},
        );
    }

    pub fn userByName(self: *Conn, allocator: std.mem.Allocator, name: []const u8) !?struct { id: i64, hash: []u8 } {
        self.mu.lock();
        defer self.mu.unlock();
        if (try self.raw.row("SELECT id, password_hash FROM users WHERE username = ?1 AND is_active = 1", .{name})) |row| {
            defer row.deinit();
            return .{ .id = row.int(0), .hash = try allocator.dupe(u8, row.text(1)) };
        }
        return null;
    }

    pub fn createSession(self: *Conn, sid: []const u8, user_id: i64, ttl_secs: i64) !void {
        var mod_buf: [32]u8 = undefined;
        const mod = try std.fmt.bufPrint(&mod_buf, "+{d} seconds", .{ttl_secs});
        try self.exec(
            "INSERT INTO sessions (id, user_id, expires_at) VALUES (?1, ?2, datetime('now', ?3))",
            .{ sid, user_id, mod },
        );
    }

    pub fn sessionUser(self: *Conn, sid: []const u8) !?i64 {
        self.mu.lock();
        defer self.mu.unlock();
        if (try self.raw.row(
            "SELECT user_id FROM sessions WHERE id = ?1 AND expires_at > datetime('now')",
            .{sid},
        )) |row| {
            defer row.deinit();
            return row.int(0);
        }
        return null;
    }

    pub fn deleteSession(self: *Conn, sid: []const u8) !void {
        try self.exec("DELETE FROM sessions WHERE id = ?1", .{sid});
    }

    pub fn consumeToken(self: *Conn, token: []const u8) !bool {
        self.mu.lock();
        defer self.mu.unlock();
        const row = try self.raw.row(
            \\
SELECT id, use_count, max_uses FROM enrollment_tokens
            \\
 WHERE token = ?1 AND (expires_at IS NULL OR expires_at > datetime('now'))
        , .{token}) orelse return false;
        defer row.deinit();
        const id = row.int(0);
        const used = row.int(1);
        const max = row.int(2);
        if (used >= max) return false;
        try self.raw.exec(
            "UPDATE enrollment_tokens SET use_count = use_count + 1, used_at = datetime('now') WHERE id = ?1",
            .{id},
        );
        return true;
    }

    pub fn insertToken(self: *Conn, token: []const u8, label: []const u8, user_id: i64) !void {
        try self.exec(
            "INSERT INTO enrollment_tokens (token, label, created_by, max_uses) VALUES (?1, ?2, ?3, 1)",
            .{ token, label, user_id },
        );
    }

    pub fn insertDevice(
        self: *Conn,
        uuid: []const u8,
        name: []const u8,
        platform: []const u8,
        os_version: []const u8,
        agent_version: []const u8,
        token: []const u8,
    ) !i64 {
        try self.exec(enroll_pc.insert_device_sql, .{ uuid, name, platform, os_version, agent_version, token });
        const id = self.lastId();
        try self.exec(
            "UPDATE enrollment_tokens SET used_by_device = ?1 WHERE token = ?2",
            .{ id, token },
        );
        return id;
    }

    pub fn bindImage(self: *Conn, device_id: i64, slug: []const u8) !void {
        if (slug.len == 0) return;
        try self.exec(enroll_pc.bind_image_sql, .{ device_id, slug });
    }

    pub fn deviceByUuid(self: *Conn, uuid: []const u8) !?i64 {
        self.mu.lock();
        defer self.mu.unlock();
        if (try self.raw.row("SELECT id FROM devices WHERE uuid = ?1", .{uuid})) |row| {
            defer row.deinit();
            return row.int(0);
        }
        return null;
    }

    pub fn touchDevice(self: *Conn, id: i64, battery: ?i64, extras: ?[]const u8, agent_version: ?[]const u8) !void {
        try self.exec(
            \\
UPDATE devices SET last_seen_at = datetime('now'), status = 'enrolled',
            \\
 battery_pct = COALESCE(?2, battery_pct),
            \\
 extras_json = COALESCE(?3, extras_json),
            \\
 agent_version = COALESCE(?4, agent_version),
            \\
 updated_at = datetime('now')
            \\
 WHERE id = ?1
        , .{ id, battery, extras, agent_version });
    }

    pub fn assignPolicyByName(self: *Conn, device_id: i64, name: []const u8) !void {
        try self.exec("DELETE FROM device_policies WHERE device_id = ?1", .{device_id});
        try self.exec(
            \\
INSERT INTO device_policies (device_id, policy_id)
            \\
SELECT ?1, id FROM policies WHERE name = ?2
        , .{ device_id, name });
    }

    pub fn assignPolicyAll(self: *Conn, name: []const u8, user_id: i64) !void {
        try self.exec("DELETE FROM device_policies", .{});
        try self.exec(
            \\
INSERT INTO device_policies (device_id, policy_id)
            \\
SELECT d.id, p.id FROM devices d, policies p WHERE p.name = ?1
        , .{name});
        try self.audit(user_id, null, "bulk_policy", "policy", name, null);
    }

    pub fn enqueueCommandAll(self: *Conn, typ: []const u8, user_id: i64) !void {
        try self.exec(
            \\
INSERT INTO commands (device_id, type, created_by)
            \\
SELECT id, ?1, ?2 FROM devices
        , .{ typ, user_id });
        try self.audit(user_id, null, "bulk_command", "command", typ, null);
    }

    pub fn pendingCommandsJson(self: *Conn, allocator: std.mem.Allocator, device_id: i64) ![]u8 {
        self.mu.lock();
        defer self.mu.unlock();
        var rows = try self.raw.rows(
            "SELECT id, type, COALESCE(payload_json, 'null') FROM commands WHERE device_id = ?1 AND status = 'pending' ORDER BY id",
            .{device_id},
        );
        defer rows.deinit();
        var out = std.ArrayList(u8).init(allocator);
        try out.appendSlice("[");
        var first = true;
        while (rows.next()) |row| {
            if (!first) try out.appendSlice(",");
            first = false;
            const id = row.int(0);
            const typ = row.text(1);
            const payload = row.text(2);
            try out.writer().print("{{\"id\":{d},\"type\":{s},\"payload\":{s}}}", .{
                id,
                try quote(allocator, typ),
                payload,
            });
            try self.raw.exec(
                "UPDATE commands SET status = 'sent', sent_at = datetime('now') WHERE id = ?1",
                .{id},
            );
        }
        if (rows.err) |e| return e;
        try out.appendSlice("]");
        return out.toOwnedSlice();
    }

    pub fn ackCommand(self: *Conn, device_id: i64, command_id: i64, result: []const u8) !void {
        try self.exec(
            \\
UPDATE commands SET status = 'acked', acked_at = datetime('now'), result_json = ?3
            \\
 WHERE id = ?1 AND device_id = ?2
        , .{ command_id, device_id, result });
    }

    pub fn policyJson(self: *Conn, allocator: std.mem.Allocator, device_id: i64) ![]u8 {
        self.mu.lock();
        defer self.mu.unlock();
        if (try self.raw.row(
            \\
SELECT p.id, p.name, p.config_json FROM device_policies dp
            \\
 JOIN policies p ON p.id = dp.policy_id
            \\
 WHERE dp.device_id = ?1
            \\
 ORDER BY dp.assigned_at DESC LIMIT 1
        , .{device_id})) |row| {
            defer row.deinit();
            return std.fmt.allocPrint(allocator, "{{\"id\":{d},\"name\":{s},\"config\":{s}}}", .{
                row.int(0),
                try quote(allocator, row.text(1)),
                row.text(2),
            });
        }
        if (try self.raw.row(
            "SELECT id, name, config_json FROM policies WHERE is_default = 1 LIMIT 1",
            .{},
        )) |row| {
            defer row.deinit();
            return std.fmt.allocPrint(allocator, "{{\"id\":{d},\"name\":{s},\"config\":{s}}}", .{
                row.int(0),
                try quote(allocator, row.text(1)),
                row.text(2),
            });
        }
        return allocator.dupe(u8, "{\"id\":0,\"name\":\"\",\"config\":{}}");
    }

    pub fn devicesJson(self: *Conn, allocator: std.mem.Allocator) ![]u8 {
        self.mu.lock();
        defer self.mu.unlock();
        var rows = try self.raw.rows(
            \\
SELECT d.id, d.name, d.uuid, d.platform, d.status, d.last_seen_at,
            \\
       COALESCE((SELECT p.name FROM device_policies dp JOIN policies p ON p.id = dp.policy_id
            \\
                 WHERE dp.device_id = d.id LIMIT 1), '')
            \\
  FROM devices d ORDER BY d.id
        , .{});
        defer rows.deinit();
        var out = std.ArrayList(u8).init(allocator);
        try out.appendSlice("{\"devices\":[");
        var first = true;
        while (rows.next()) |row| {
            if (!first) try out.appendSlice(",");
            first = false;
            try out.writer().print(
                "{{\"id\":{d},\"name\":{s},\"uuid\":{s},\"platform\":{s},\"status\":{s},\"last_seen_at\":{s},\"policy\":{s}}}",
                .{
                    row.int(0),
                    try quote(allocator, row.text(1)),
                    try quote(allocator, row.text(2)),
                    try quote(allocator, row.text(3)),
                    try quote(allocator, row.text(4)),
                    try quote(allocator, row.text(5)),
                    try quote(allocator, row.text(6)),
                },
            );
        }
        if (rows.err) |e| return e;
        try out.appendSlice("]}");
        return out.toOwnedSlice();
    }

    pub fn tokensHtml(self: *Conn, allocator: std.mem.Allocator) ![]u8 {
        self.mu.lock();
        defer self.mu.unlock();
        var rows = try self.raw.rows(
            "SELECT token, COALESCE(label,''), use_count, max_uses FROM enrollment_tokens ORDER BY id DESC LIMIT 50",
            .{},
        );
        defer rows.deinit();
        var out = std.ArrayList(u8).init(allocator);
        try out.appendSlice("<ul>");
        while (rows.next()) |row| {
            try out.writer().print("<li><code>{s}</code> {s} ({d}/{d})</li>", .{
                row.text(0),
                row.text(1),
                row.int(2),
                row.int(3),
            });
        }
        if (rows.err) |e| return e;
        try out.appendSlice("</ul>");
        return out.toOwnedSlice();
    }

    pub fn audit(
        self: *Conn,
        user_id: ?i64,
        device_id: ?i64,
        action: []const u8,
        target_type: []const u8,
        target_id: []const u8,
        detail: ?[]const u8,
    ) !void {
        try self.exec(
            "INSERT INTO audit_log (actor_user_id, actor_device_id, action, target_type, target_id, detail_json) VALUES (?1, ?2, ?3, ?4, ?5, ?6)",
            .{ user_id, device_id, action, target_type, target_id, detail },
        );
    }

    pub fn insertComms(
        self: *Conn,
        uuid: []const u8,
        ts: []const u8,
        direction: []const u8,
        kind: []const u8,
        peer: []const u8,
        allowed: i64,
        meta: []const u8,
        body: []const u8,
    ) !void {
        try self.exec(
            \\
INSERT INTO comms_log (device_id, ts, direction, kind, peer, allowed, meta_json, body)
            \\
SELECT d.id, COALESCE(NULLIF(?1, ''), datetime('now')), ?2, ?3, ?4, ?5, ?6, ?7
            \\
  FROM devices d WHERE d.uuid = ?8
        , .{ ts, direction, kind, peer, allowed, meta, body, uuid });
    }
};

fn quote(allocator: std.mem.Allocator, s: []const u8) ![]const u8 {
    var out = std.ArrayList(u8).init(allocator);
    try out.append('"');
    for (s) |c| {
        switch (c) {
            '"' => try out.appendSlice("\\\""),
            '\\' => try out.appendSlice("\\\\"),
            '\n' => try out.appendSlice("\\n"),
            else => try out.append(c),
        }
    }
    try out.append('"');
    return out.toOwnedSlice();
}
