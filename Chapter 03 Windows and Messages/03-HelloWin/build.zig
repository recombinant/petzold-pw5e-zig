const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("HelloWin.zig"),
        .target = target,
        .optimize = optimize,
    });
    const exe = b.addExecutable(.{
        .name = "HelloWin",
        .root_module = exe_mod,
    });

    exe.root_module.addImport(
        "win32",
        b.dependency("win32", .{}).module("win32"),
    );
    exe.root_module.addImport(
        "windowsx",
        b.dependency("windowsx", .{}).module("windowsx"),
    );
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
