const std = @import("std");

pub fn load(a: std.mem.Allocator, path: []const u8) ?[]u8 {
    const src: []const u8 = if (std.mem.eql(u8, path, "web/home.html"))
        @embedFile("home.html")
    else if (std.mem.eql(u8, path, "web/lms.html"))
        @embedFile("lms.html")
    else if (std.mem.eql(u8, path, "web/school.html"))
        @embedFile("school.html")
    else if (std.mem.eql(u8, path, "web/comms.html"))
        @embedFile("comms.html")
    else if (std.mem.eql(u8, path, "web/enroll.html"))
        @embedFile("enroll.html")
    else if (std.mem.eql(u8, path, "web/enroll_pc.html"))
        @embedFile("enroll.html")
    else if (std.mem.eql(u8, path, "web/algebra_war.html"))
        @embedFile("algebra_war.html")
    else if (std.mem.eql(u8, path, "web/devices.html"))
        @embedFile("devices.html")
    else if (std.mem.eql(u8, path, "web/policies.html"))
        @embedFile("policies.html")
    else if (std.mem.eql(u8, path, "web/settings.html"))
        @embedFile("settings.html")
    else if (std.mem.eql(u8, path, "web/ai.html"))
        @embedFile("ai.html")
    else
        return null;
    return a.dupe(u8, src) catch null;
}
