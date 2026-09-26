//! Zig 0.16+ auth. No std.crypto.random (removed).
const std = @import("std");

var seed: u64 = 0x123456789abcdef;

fn nextU64() u64 {
    seed +%= 0x9e3779b97f4a7c15;
    var z = seed;
    z = (z ^ (z >> 30)) *% 0xbf58476d1ce4e5b9;
    z = (z ^ (z >> 27)) *% 0x94d049bb133111eb;
    return z ^ (z >> 31);
}

pub const AuthError = error{
    HashFailed,
    VerifyFailed,
    TokenGenFailed,
    OutOfMemory,
};

pub fn generateSessionToken(allocator: std.mem.Allocator) AuthError![]u8 {
    var hex: [64]u8 = undefined;
    const charset = "0123456789abcdef";
    var i: usize = 0;
    while (i < 64) : (i += 16) {
        const n = nextU64();
        var shift: u6 = 0;
        var k: usize = 0;
        while (k < 16) : (k += 1) {
            const nib: u8 = @truncate((n >> shift) & 0xf);
            hex[i + k] = charset[nib];
            shift +%= 4;
        }
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
