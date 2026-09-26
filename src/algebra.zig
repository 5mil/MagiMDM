const std = @import("std");

var seed: u64 = 0x9e3779b97f4a7c15;

fn nextU64() u64 {
    seed +%= 0x9e3779b97f4a7c15;
    var z = seed;
    z = (z ^ (z >> 30)) *% 0xbf58476d1ce4e5b9;
    z = (z ^ (z >> 27)) *% 0x94d049bb133111eb;
    return z ^ (z >> 31);
}

fn rnd(min: i32, max: i32) i32 {
    const span: u64 = @intCast(max - min + 1);
    return min + @as(i32, @intCast(nextU64() % span));
}

pub const Problem = struct {
    prompt: []u8,
    x: i32,
};

pub fn makeProblem(a: std.mem.Allocator, band: u8) !Problem {
    if (band <= 1) {
        const coef = rnd(2, 9);
        const x = rnd(-6, 9);
        const b = coef * x;
        const prompt = try std.fmt.allocPrint(a, "{d}x = {d}", .{ coef, b });
        return .{ .prompt = prompt, .x = x };
    }
    if (band == 2) {
        const coef = rnd(2, 6);
        const x = rnd(-5, 8);
        const c = rnd(-8, 8);
        const b = coef * x + c;
        const prompt = if (c >= 0)
            try std.fmt.allocPrint(a, "{d}x + {d} = {d}", .{ coef, c, b })
        else
            try std.fmt.allocPrint(a, "{d}x - {d} = {d}", .{ coef, -c, b });
        return .{ .prompt = prompt, .x = x };
    }
    const left = rnd(3, 7);
    const right = rnd(1, left - 1);
    const x = rnd(-5, 8);
    const c = (left - right) * x;
    const prompt = if (c >= 0)
        try std.fmt.allocPrint(a, "{d}x = {d}x + {d}", .{ left, right, c })
    else
        try std.fmt.allocPrint(a, "{d}x = {d}x - {d}", .{ left, right, -c });
    return .{ .prompt = prompt, .x = x };
}

pub fn parseIntAnswer(s: []const u8) ?i32 {
    const t = std.mem.trim(u8, s, " \t\r\n");
    return std.fmt.parseInt(i32, t, 10) catch null;
}

pub fn judgeSolve(expected: i32, answer: []const u8) bool {
    const v = parseIntAnswer(answer) orelse return false;
    return v == expected;
}
