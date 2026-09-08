const std = @import("std");

/// weekday: 0=Sun .. 6=Sat (use local tz on the agent).
pub fn inWindow(weekday: u8, minutes: u16, start_h: u8, start_m: u8, end_h: u8, end_m: u8, days: []const u8) bool {
    var ok_day = false;
    for (days) |d| {
        if (d == weekday) ok_day = true;
    }
    if (!ok_day) return false;
    const start: u16 = @as(u16, start_h) * 60 + start_m;
    const end: u16 = @as(u16, end_h) * 60 + end_m;
    return minutes >= start and minutes < end;
}

pub fn pickMode(weekday: u8, minutes: u16) []const u8 {
    const school_days = [_]u8{ 1, 2, 3, 4, 5 };
    if (inWindow(weekday, minutes, 8, 0, 15, 0, &school_days)) return "SchoolDay";
    if (inWindow(weekday, minutes, 15, 0, 20, 0, &school_days)) return "AfterHours";
    if (weekday == 0 or weekday == 6) return "Weekend";
    return "AfterHours";
}

test "tue 10am is school" {
    try std.testing.expectEqualStrings("SchoolDay", pickMode(2, 10 * 60));
}
