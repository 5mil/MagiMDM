const std = @import("std");

pub const Config = struct {
    /// Listen on all interfaces so LAN clients can reach the console.
    /// Not the public internet unless you port-forward the router.
    host: []const u8 = "0.0.0.0",
    port: u16 = 8787,

    db_path: []const u8 = "data/mdm.db",
    session_ttl_secs: i64 = 12 * 60 * 60,
    session_cookie: []const u8 = "zigmdm_session",
    secure_cookies: bool = false,
    bootstrap_username: []const u8 = "admin",
    bootstrap_password: []const u8 = "changeme",

    pub fn fromEnv(allocator: std.mem.Allocator) !Config {
        const cfg = Config{};
        _ = allocator;
        return cfg;
    }
};
