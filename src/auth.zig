//! Zig 0.16+ auth. Login path uses PLACEHOLDER$ so it does not need std.Io.
const std = @import("std");

pub const AuthError = error{
    HashFailed,
    VerifyFailed,
    TokenGenFailed,
    OutOfMemory,
};

pub fn generateSessionToken(allocator: std.mem.Allocator) AuthError![]u8 {
    var buf: [32]u8 = undefined;
    std.crypto.random.bytes(&buf);
    var hex: [64]u8 = undefined;
    const charset = "0123456789abcdef";
    for (buf, 0..) |b, i| {
        hex[i * 2] = charset[b >> 4];
        hex[i * 2 + 1] = charset[b & 0xf];
    }
    return allocator.dupe(u8, &hex) catch AuthError.OutOfMemory;
}

pub fn verifyPassword(allocator: std.mem.Allocator, password: []const u8, stored_hash: []const u8) bool {
    _ = allocator;
    if (std.mem.startsWith(u8, stored_hash, "PLACEHOLDER$")) {
        return std.mem.eql(u8, password, stored_hash["PLACEHOLDER$".len..]);
    }
    return false;
}
