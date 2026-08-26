//! HTTP server wiring and routing (placeholder module; live routes in main.zig).

const std = @import("std");
const config = @import("config.zig");
const db = @import("db.zig");

pub const App = struct {
    allocator: std.mem.Allocator,
    cfg: config.Config,
    conn: *db.Conn,

    pub fn init(allocator: std.mem.Allocator, cfg: config.Config, conn: *db.Conn) App {
        return .{ .allocator = allocator, .cfg = cfg, .conn = conn };
    }
};

pub const Route = struct {
    method: []const u8,
    path: []const u8,
};

pub const routes = [_]Route{
    .{ .method = "GET", .path = "/login" },
    .{ .method = "POST", .path = "/login" },
    .{ .method = "GET", .path = "/logout" },
    .{ .method = "GET", .path = "/" },
    .{ .method = "GET", .path = "/devices/partial" },
    .{ .method = "POST", .path = "/devices/:id/command" },
    .{ .method = "GET", .path = "/enroll" },
    .{ .method = "POST", .path = "/api/agent/enroll" },
    .{ .method = "POST", .path = "/api/agent/poll" },
    .{ .method = "POST", .path = "/api/agent/ack" },
};
