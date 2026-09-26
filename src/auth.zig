//! Authentication helpers: argon2id password hashing and session tokens.
//! Zig 0.16+.

const std = @import("std");
const argon2 = std.crypto.pwhash.argon2;

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

pub fn hashPassword(allocator: std.mem.Allocator, io: std.Io, password: []const u8) AuthError![]u8 {
    var out: [256]u8 = undefined;
    const hash = argon2.strHash(password, .{
        .allocator = allocator,
        .params = argon2.Params.owasp_2id,
        .mode = .argon2id,
        .encoding = .phc,
    }, &out, io) catch return AuthError.HashFailed;
    return allocator.dupe(u8, hash) catch AuthError.OutOfMemory;
}

pub fn verifyPassword(allocator: std.mem.Allocator, io: std.Io, password: []const u8, stored_hash: []const u8) bool {
    if (std.mem.startsWith(u8, stored_hash, "PLACEHOLDER$")) {
        return std.mem.eql(u8, password, stored_hash["PLACEHOLDER$".len..]);
    }
    argon2.strVerify(stored_hash, password, .{ .allocator = allocator }, io) catch return false;
    return true;
}

pub fn sessionCookieHeader(
    allocator: std.mem.Allocator,
    name: []const u8,
    value: []const u8,
    max_age_secs: i64,
    secure: bool,
) AuthError![]u8 {
    const flag: []const u8 = if (secure) "; Secure" else "";
    return std.fmt.allocPrint(
        allocator,
        "{s}={s}; Path=/; HttpOnly; SameSite=Lax{s}; Max-Age={d}",
        .{ name, value, flag, max_age_secs },
    ) catch AuthError.OutOfMemory;
}

pub fn clearSessionCookie(allocator: std.mem.Allocator, name: []const u8) AuthError![]u8 {
    return std.fmt.allocPrint(
        allocator,
        "{s}=; Path=/; HttpOnly; SameSite=Lax; Max-Age=0",
        .{name},
    ) catch AuthError.OutOfMemory;
}
