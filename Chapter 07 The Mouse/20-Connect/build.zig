const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // ----------------------------------------------------

    const exe = b.addExecutable(.{
        .name = "20-Connect",
        .root_source_file = .{ .path = "Connect.zig" },
        .target = target,
        .optimize = optimize,
        .single_threaded = true,
    });

    const win32 = b.createModule(.{ .source_file = .{ .path = "../../zigwin32/win32.zig" } });
    const windowsx = b.createModule(.{
        .source_file = .{ .path = "../../windowsx/windowsx.zig" },
        .dependencies = &.{.{ .name = "win32", .module = win32 }},
    });
    exe.addModule("win32", win32);
    exe.addModule("windowsx", windowsx);

    b.installArtifact(exe);

    // ----------------------------------------------------

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
