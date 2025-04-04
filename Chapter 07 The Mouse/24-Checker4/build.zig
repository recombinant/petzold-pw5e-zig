const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("24-Checker4", "Checker4.zig");
    exe.single_threaded = true;
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    const pkg1 = std.build.Pkg{
        .name = "win32",
        .source = .{ .path = "../../zigwin32/win32.zig" },
    };
    const pkg2 = std.build.Pkg{
        .name = "windowsx",
        .source = .{ .path = "../../windowsx/windowsx.zig" },
        .dependencies = &[_]std.build.Pkg{pkg1},
    };

    exe.addPackage(pkg1);
    exe.addPackage(pkg2);

    // ----------------------------------------------------

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
