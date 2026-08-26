const std = @import("std");

pub const Config = struct {
    /// Listen address
    host: []const u8 = "127.0.0.1",
    port: u16 = 8787,

    /// SQLite database path (relative to working directory)
    db_path: []const u8 = "data/mdm.db",

    /// Session lifetime in seconds (default 12 hours)
    session_ttl_secs: i64 = 12 * 60 * 60,

    /// Cookie name for session id
    session_cookie: []const u8 = "zigmdm_session",

    /// Whether to set Secure flag on cookies (enable when behind HTTPS)
    secure_cookies: bool = false,

    /// Default admin created on first run (change immediately)
    bootstrap_username: []const u8 = "admin",
    bootstrap_password: []const u8 = "changeme",

    pub fn fromEnv(allocator: std.mem.Allocator) !Config {
        const cfg = Config{};
        // Future: read ZIGMDM_HOST, ZIGMDM_PORT, ZIGMDM_DB, etc.
        _ = allocator;
        return cfg;
    }
};
