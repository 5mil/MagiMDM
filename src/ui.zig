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
    else if (std.mem.eql(u8, path, "web/enroll_pc.html"))
        @embedFile("enroll_pc.html")
    else if (std.mem.eql(u8, path, "web/algebra_war.html"))
        @embedFile("algebra_war.html")
    else
        return null;
    return a.dupe(u8, src) catch null;
}
