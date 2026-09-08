//! HTTP routing table (live dispatch still belongs in main.zig).
const std = @import("std");
const config = @import("config.zig");

pub const Route = struct { method: []const u8, path: []const u8 };

pub const routes = [_]Route{
    .{ .method = "GET", .path = "/login" },
    .{ .method = "POST", .path = "/login" },
    .{ .method = "GET", .path = "/logout" },
    .{ .method = "GET", .path = "/" },
    .{ .method = "GET", .path = "/home" },
    .{ .method = "GET", .path = "/devices/partial" },
    .{ .method = "POST", .path = "/devices/:id/command" },
    .{ .method = "POST", .path = "/devices/bulk" },
    .{ .method = "GET", .path = "/enroll" },
    .{ .method = "GET", .path = "/enroll/pc" },
    .{ .method = "POST", .path = "/enroll/pc" },
    .{ .method = "GET", .path = "/policies" },
    .{ .method = "GET", .path = "/audit" },
    .{ .method = "GET", .path = "/audit.csv" },
    .{ .method = "POST", .path = "/api/agent/enroll" },
    .{ .method = "POST", .path = "/api/agent/poll" },
    .{ .method = "POST", .path = "/api/agent/ack" },
};
