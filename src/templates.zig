const std = @import("std");

pub const names = [_][]const u8{ "Baseline", "SchoolDay", "AfterHours", "ExamLock", "Weekend", "Monitor" };

pub fn isStudentLocked(name: []const u8) bool {
    return std.mem.eql(u8, name, "SchoolDay") or std.mem.eql(u8, name, "ExamLock");
}
