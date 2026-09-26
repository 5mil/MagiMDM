//! SQLite via libsqlite3. Zig 0.16+ (no @cImport).
const std = @import("std");
const c = @import("sqlite_c.zig");

pub const Conn = struct {
    db: *c.sqlite3,

    pub fn open(path: [:0]const u8) !Conn {
        var ptr: ?*c.sqlite3 = null;
        if (c.sqlite3_open(path.ptr, &ptr) != c.SQLITE_OK) return error.OpenFailed;
        const db = ptr.?;
        var self = Conn{ .db = db };
        try self.exec(
            \\
            \\PRAGMA journal_mode=WAL;
            \\PRAGMA foreign_keys=ON;
            \\CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT NOT NULL UNIQUE COLLATE NOCASE, password_hash TEXT NOT NULL, display_name TEXT, is_active INTEGER NOT NULL DEFAULT 1, created_at TEXT NOT NULL DEFAULT (datetime('now')), updated_at TEXT NOT NULL DEFAULT (datetime('now')));
            \\CREATE TABLE IF NOT EXISTS sessions (id TEXT PRIMARY KEY, user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE, created_at TEXT NOT NULL DEFAULT (datetime('now')), expires_at TEXT NOT NULL);
            \\CREATE TABLE IF NOT EXISTS devices (id INTEGER PRIMARY KEY AUTOINCREMENT, uuid TEXT NOT NULL UNIQUE, name TEXT, platform TEXT NOT NULL DEFAULT 'android', model TEXT, os_version TEXT, agent_version TEXT, enrollment_token TEXT, status TEXT NOT NULL DEFAULT 'pending', last_seen_at TEXT, extras_json TEXT, created_at TEXT NOT NULL DEFAULT (datetime('now')));
            \\CREATE TABLE IF NOT EXISTS enrollment_tokens (id INTEGER PRIMARY KEY AUTOINCREMENT, token TEXT NOT NULL UNIQUE, label TEXT, expires_at TEXT, used_at TEXT, max_uses INTEGER NOT NULL DEFAULT 1, use_count INTEGER NOT NULL DEFAULT 0);
            \\CREATE TABLE IF NOT EXISTS commands (id INTEGER PRIMARY KEY AUTOINCREMENT, device_id INTEGER NOT NULL REFERENCES devices(id) ON DELETE CASCADE, type TEXT NOT NULL, payload_json TEXT, status TEXT NOT NULL DEFAULT 'pending', created_at TEXT NOT NULL DEFAULT (datetime('now')), acked_at TEXT, result_json TEXT);
            \\CREATE TABLE IF NOT EXISTS audit_log (id INTEGER PRIMARY KEY AUTOINCREMENT, action TEXT NOT NULL, detail_json TEXT, created_at TEXT NOT NULL DEFAULT (datetime('now')));
            \\CREATE TABLE IF NOT EXISTS policies (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, description TEXT, config_json TEXT NOT NULL DEFAULT '{}', is_default INTEGER NOT NULL DEFAULT 0);
            \\CREATE TABLE IF NOT EXISTS device_policies (device_id INTEGER NOT NULL REFERENCES devices(id) ON DELETE CASCADE, policy_id INTEGER NOT NULL REFERENCES policies(id) ON DELETE CASCADE, PRIMARY KEY (device_id, policy_id));
            \\CREATE TABLE IF NOT EXISTS images (id INTEGER PRIMARY KEY AUTOINCREMENT, slug TEXT NOT NULL UNIQUE, label TEXT NOT NULL, os TEXT NOT NULL, seed_json TEXT NOT NULL DEFAULT '{}');
            \\CREATE TABLE IF NOT EXISTS device_images (device_id INTEGER NOT NULL REFERENCES devices(id) ON DELETE CASCADE, image_id INTEGER NOT NULL REFERENCES images(id), PRIMARY KEY (device_id));
            \\CREATE TABLE IF NOT EXISTS comms_log (id INTEGER PRIMARY KEY AUTOINCREMENT, device_id INTEGER NOT NULL REFERENCES devices(id) ON DELETE CASCADE, ts TEXT NOT NULL DEFAULT (datetime('now')), direction TEXT NOT NULL, kind TEXT NOT NULL, peer TEXT, allowed INTEGER NOT NULL DEFAULT 1, meta_json TEXT, body TEXT);
            \\CREATE TABLE IF NOT EXISTS school_years (id INTEGER PRIMARY KEY AUTOINCREMENT, label TEXT NOT NULL UNIQUE, starts_on TEXT NOT NULL DEFAULT '2026-09-01', ends_on TEXT NOT NULL DEFAULT '2027-06-30', is_current INTEGER NOT NULL DEFAULT 0);
            \\CREATE TABLE IF NOT EXISTS children (id INTEGER PRIMARY KEY AUTOINCREMENT, given_name TEXT NOT NULL, grade_band TEXT NOT NULL DEFAULT '9-12', grade INTEGER, created_at TEXT NOT NULL DEFAULT (datetime('now')));
            \\CREATE TABLE IF NOT EXISTS courses (id INTEGER PRIMARY KEY AUTOINCREMENT, code TEXT NOT NULL, title TEXT NOT NULL, credit_hours REAL NOT NULL DEFAULT 3, kind TEXT NOT NULL DEFAULT 'home', track TEXT NOT NULL DEFAULT 'legal', nys_bucket TEXT);
            \\CREATE TABLE IF NOT EXISTS enrollments (id INTEGER PRIMARY KEY AUTOINCREMENT, course_id INTEGER NOT NULL, child_id INTEGER NOT NULL);
            \\CREATE TABLE IF NOT EXISTS outcomes (id INTEGER PRIMARY KEY AUTOINCREMENT, enrollment_id INTEGER NOT NULL, as_of TEXT NOT NULL DEFAULT (datetime('now')), grade TEXT, narrative TEXT, source TEXT NOT NULL DEFAULT 'manual');
            \\CREATE TABLE IF NOT EXISTS hour_logs (id INTEGER PRIMARY KEY AUTOINCREMENT, child_id INTEGER, on_date TEXT, minutes INTEGER NOT NULL DEFAULT 0, note TEXT);
            \\CREATE TABLE IF NOT EXISTS game_sessions (id INTEGER PRIMARY KEY AUTOINCREMENT, child_id INTEGER, course_id INTEGER, mode TEXT NOT NULL DEFAULT 'lane', band INTEGER NOT NULL DEFAULT 1, started_at TEXT NOT NULL DEFAULT (datetime('now')), gold INTEGER NOT NULL DEFAULT 0, last_hits INTEGER NOT NULL DEFAULT 0, misses INTEGER NOT NULL DEFAULT 0, tower_down INTEGER NOT NULL DEFAULT 0, current_x INTEGER, current_prompt TEXT);
            \\CREATE TABLE IF NOT EXISTS game_events (id INTEGER PRIMARY KEY AUTOINCREMENT, session_id INTEGER NOT NULL, ts TEXT NOT NULL DEFAULT (datetime('now')), kind TEXT NOT NULL, prompt TEXT, answer TEXT, correct INTEGER NOT NULL DEFAULT 0);
        );
        try self.exec(
            \\
            \\INSERT OR IGNORE INTO users (username, password_hash) VALUES ('admin', 'PLACEHOLDER$changeme');
            \\INSERT OR IGNORE INTO images (slug, label, os) VALUES ('linux-debian12-student', 'Debian 12 student', 'linux'), ('windows11-student', 'Windows 11 student', 'windows');
            \\INSERT OR IGNORE INTO policies (name, description, config_json, is_default) VALUES ('Baseline', 'Floor', '{"mining":{"enabled":false}}', 1), ('SchoolDay', 'Class hours', '{"mining":{"enabled":false},"mode":"school"}', 0), ('AfterHours', 'Evening', '{"mining":{"enabled":false},"mode":"after"}', 0), ('ExamLock', 'Exam', '{"mining":{"enabled":false},"mode":"exam"}', 0), ('Weekend', 'Weekend', '{"mining":{"enabled":false},"mode":"weekend"}', 0), ('Monitor', 'Watch only', '{"mining":{"enabled":false},"mode":"monitor"}', 0);
            \\INSERT OR IGNORE INTO school_years(label,is_current) VALUES('2026-27',1);
            \\INSERT OR IGNORE INTO courses(code,title,credit_hours,kind,track,nys_bucket) VALUES('ALG1-WAR','Algebra 1 fluency (Algebra War)',1,'home','legal','mathematics');
        );
        return self;
    }

    pub fn close(self: *Conn) void {
        _ = c.sqlite3_close(self.db);
    }

    pub fn exec(self: *Conn, sql: [:0]const u8) !void {
        var err: [*c]u8 = null;
        if (c.sqlite3_exec(self.db, sql.ptr, null, null, &err) != c.SQLITE_OK) {
            if (err != null) c.sqlite3_free(err);
            return error.ExecFailed;
        }
    }

    pub fn lastId(self: *Conn) i64 {
        return @intCast(c.sqlite3_last_insert_rowid(self.db));
    }

    pub fn queryText(self: *Conn, allocator: std.mem.Allocator, sql: [:0]const u8) !?[]u8 {
        var stmt: ?*c.sqlite3_stmt = null;
        if (c.sqlite3_prepare_v2(self.db, sql.ptr, -1, &stmt, null) != c.SQLITE_OK) return error.Prepare;
        defer _ = c.sqlite3_finalize(stmt);
        if (c.sqlite3_step(stmt) != c.SQLITE_ROW) return null;
        const p = c.sqlite3_column_text(stmt, 0);
        if (p == null) return null;
        return try allocator.dupe(u8, std.mem.span(p));
    }
};
