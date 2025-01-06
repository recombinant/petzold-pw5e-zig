const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zigwin32 = b.dependency("zigwin32", .{}).module("zigwin32");
    const windowsx = b.dependency("windowsx", .{}).module("windowsx");
    const sysmets = b.createModule(.{ .root_source_file = b.path("../04-SysMets1/SysMets.zig") });
    sysmets.addImport("zigwin32", zigwin32);
    sysmets.addImport("windowsx", windowsx);

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("SysMets2.zig"),
        .target = target,
        .optimize = optimize,
    });
    const exe = b.addExecutable(.{
        .name = "SysMets2",
        .root_module = exe_mod,
    });
    exe.root_module.addImport("zigwin32", zigwin32);
    exe.root_module.addImport("windowsx", windowsx);
    exe.root_module.addImport("sysmets", sysmets);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // ----------------------------------------------------------
    const exe_unit_tests = b.addTest(.{
        .root_module = exe_mod,
    });
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
