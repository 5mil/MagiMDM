//! PC enroll helpers — persist platform + image_slug (call from enroll handler).
const std = @import("std");

pub fn normalizePlatform(raw: []const u8) []const u8 {
    if (std.mem.eql(u8, raw, "windows") or std.mem.eql(u8, raw, "win") or std.mem.eql(u8, raw, "win32"))
        return "windows";
    if (std.mem.eql(u8, raw, "linux") or std.mem.eql(u8, raw, "debian") or std.mem.eql(u8, raw, "ubuntu"))
        return "linux";
    if (std.mem.eql(u8, raw, "android")) return "android";
    return raw;
}

/// SQL after INSERT INTO devices … platform=?
/// Then bind image if slug non-empty.
pub const bind_image_sql =
    \\INSERT OR REPLACE INTO device_images (device_id, image_id)
    \\SELECT ?, id FROM images WHERE slug = ?;
;

pub const insert_device_sql =
    \\INSERT INTO devices (uuid, name, platform, os_version, agent_version, enrollment_token, status)
    \\VALUES (?, ?, ?, ?, ?, ?, 'pending');
;

test "normalize" {
    try std.testing.expectEqualStrings("windows", normalizePlatform("win"));
    try std.testing.expectEqualStrings("linux", normalizePlatform("debian"));
}
