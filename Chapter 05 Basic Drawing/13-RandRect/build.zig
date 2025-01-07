const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zigwin32 = b.dependency("zigwin32", .{}).module("zigwin32");
    const windowsx = b.dependency("windowsx", .{}).module("windowsx");

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("RandRect.zig"),
        .target = target,
        .optimize = optimize,
    });
    const exe = b.addExecutable(.{
        .name = "RandRect",
        .root_module = exe_mod,
    });
    exe.root_module.addImport("zigwin32", zigwin32);
    exe.root_module.addImport("windowsx", windowsx);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
