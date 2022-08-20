const Builder = @import("std").build.Builder;
const std = @import("std");
// var gpa = std.heap.GeneralPurposeAllocator(.{}){};
// const allocator = gpa.allocator();

pub fn build(b: *Builder) !void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("zig-agora", "src/main.zig");
    // std.log.info("Build root is: {s}", .{b.build_root});
    const lib_rpath = "agora_sdk/lib/aarch64";
    const lib_path = try std.fmt.allocPrint(b.allocator, "{s}/{s}", .{b.build_root, lib_rpath});
    // std.log.info("Library Path is: {s}", .{lib_path});
    exe.addIncludePath("agora_sdk/include");
    // change this to x86_64 if you're using x86 machine
    exe.addLibraryPath(lib_path);
    exe.linkLibC();
    // IT IS DASH NOT UNDERSCORE! FUCK IT!
    exe.linkSystemLibraryName("agora-rtc-sdk");
    exe.setBuildMode(mode);
    exe.setTarget(target);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}