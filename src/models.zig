const std = @import("std");

pub const User = struct {
    id: i64,
    username: []const u8,
    password_hash: []const u8,
    display_name: ?[]const u8 = null,
    is_active: bool = true,
};

pub const Session = struct {
    id: []const u8,
    user_id: i64,
    expires_at: []const u8,
};

pub const Device = struct {
    id: i64,
    uuid: []const u8,
    name: ?[]const u8 = null,
    platform: []const u8 = "android",
    model: ?[]const u8 = null,
    os_version: ?[]const u8 = null,
    agent_version: ?[]const u8 = null,
    status: []const u8 = "pending",
    last_seen_at: ?[]const u8 = null,
    battery_pct: ?i32 = null,
};

pub const Command = struct {
    id: i64,
    device_id: i64,
    type: []const u8,
    payload_json: ?[]const u8 = null,
    status: []const u8 = "pending",
    created_at: []const u8,
};
