const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const resolved = target.result;
    const default_bundle = resolved.os.tag == .windows;
    const bundle_sqlite = b.option(bool, "bundle-sqlite", "Compile third_party/sqlite/sqlite3.c instead of system lib") orelse default_bundle;

    const root = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const exe = b.addExecutable(.{
        .name = "zig-mdm",
        .root_module = root,
    });

    if (bundle_sqlite) {
        exe.addCSourceFile(.{
            .file = b.path("third_party/sqlite/sqlite3.c"),
            .flags = &.{ "-DSQLITE_THREADSAFE=1", "-DSQLITE_DQS=0", "-DSQLITE_OMIT_LOAD_EXTENSION" },
        });
        exe.addIncludePath(b.path("third_party/sqlite"));
    } else {
        root.linkSystemLibrary("sqlite3", .{});
    }

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);
    const run_step = b.step("run", "Run MagiMDM");
    run_step.dependOn(&run_cmd.step);
}
