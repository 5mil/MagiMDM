//! SQLite access for MagiMDM. Schema from sql/*.sql, applied on open.

const std = @import("std");
const zqlite = @import("zqlite");
const enroll_pc = @import("enroll_pc.zig");
