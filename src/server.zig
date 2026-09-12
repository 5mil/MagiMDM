const std = @import("std");

pub const Route = struct { method: []const u8, path: []const u8 };

pub const routes = [_]Route{
    .{ .method = "GET", .path = "/login" },
    .{ .method = "POST", .path = "/login" },
    .{ .method = "GET", .path = "/logout" },
    .{ .method = "GET", .path = "/" },
    .{ .method = "GET", .path = "/home" },
    .{ .method = "GET", .path = "/comms" },
    .{ .method = "GET", .path = "/school" },
    .{ .method = "GET", .path = "/lms" },
    .{ .method = "GET", .path = "/enroll" },
    .{ .method = "GET", .path = "/enroll/pc" },
    .{ .method = "POST", .path = "/enroll/pc" },
    .{ .method = "POST", .path = "/devices/bulk" },
    .{ .method = "GET", .path = "/api/parent/devices" },
    .{ .method = "GET", .path = "/api/parent/comms" },
    .{ .method = "GET", .path = "/api/school/year" },
    .{ .method = "GET", .path = "/api/lms/courses" },
    .{ .method = "POST", .path = "/api/learn/sync" },
    .{ .method = "POST", .path = "/api/agent/enroll" },
    .{ .method = "POST", .path = "/api/agent/poll" },
    .{ .method = "POST", .path = "/api/agent/ack" },
    .{ .method = "POST", .path = "/api/agent/comms-log" },
};
