const std = @import("std");

/// Pull the extras object from a poll body for devices.extras_json.
pub fn extractExtrasJson(body: []const u8) ?[]const u8 {
    const key = "\"extras\"";
    const i = std.mem.indexOf(u8, body, key) orelse return null;
    const colon = std.mem.indexOfScalarPos(u8, body, i + key.len, ':') orelse return null;
    var p = colon + 1;
    while (p < body.len and (body[p] == ' ' or body[p] == '\t' or body[p] == '\n')) p += 1;
    if (p >= body.len or body[p] != '{') return null;
    var depth: usize = 0;
    var q = p;
    while (q < body.len) : (q += 1) {
        if (body[q] == '{') depth += 1;
        if (body[q] == '}') {
            depth -= 1;
            if (depth == 0) return body[p .. q + 1];
        }
    }
    return null;
}

test "extract mining extras" {
    const body = "{\"uuid\":\"abc\",\"extras\":{\"mining_enabled\":true,\"mining_algo\":\"skein\"}}";
    const ex = extractExtrasJson(body).?;
    try std.testing.expect(std.mem.indexOf(u8, ex, "mining_enabled") != null);
}
