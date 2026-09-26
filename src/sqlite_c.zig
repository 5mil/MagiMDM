//! Zig 0.16+ — no @cImport. Linked with -lsqlite3.
pub const sqlite3 = opaque {};
pub const sqlite3_stmt = opaque {};

pub const SQLITE_OK: c_int = 0;
pub const SQLITE_ROW: c_int = 100;

pub extern fn sqlite3_open(filename: [*:0]const u8, ppDb: *?*sqlite3) c_int;
pub extern fn sqlite3_close(db: ?*sqlite3) c_int;
pub extern fn sqlite3_exec(
    db: *sqlite3,
    sql: [*:0]const u8,
    callback: ?*const fn (?*anyopaque, c_int, [*c][*c]u8, [*c][*c]u8) callconv(.c) c_int,
    arg: ?*anyopaque,
    errmsg: *?[*c]u8,
) c_int;
pub extern fn sqlite3_free(ptr: ?*anyopaque) void;
pub extern fn sqlite3_last_insert_rowid(db: *sqlite3) i64;
pub extern fn sqlite3_prepare_v2(
    db: *sqlite3,
    zSql: [*:0]const u8,
    nByte: c_int,
    ppStmt: *?*sqlite3_stmt,
    pzTail: ?*[*c]const u8,
) c_int;
pub extern fn sqlite3_finalize(pStmt: ?*sqlite3_stmt) c_int;
pub extern fn sqlite3_step(pStmt: ?*sqlite3_stmt) c_int;
pub extern fn sqlite3_column_text(pStmt: ?*sqlite3_stmt, iCol: c_int) ?[*:0]const u8;
