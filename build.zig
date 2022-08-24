const std = @import("std");
const Builder = @import("std").build.Builder;
const Pkg = std.build.Pkg;
const header_list: []const []const u8 = &.{"gst/gst.h"};

pub fn build(b: *Builder) !void {
    const target = b.standardTargetOptions(.{});

    const mode = b.standardReleaseOptions();

    const gst_rpath = "/usr/include/gstreamer-1.0";
    // TODO: use struct
    for (header_list) |header| {
        const gst_file_path: []const u8 = try std.fs.path.join(b.allocator, &.{gst_rpath, header});
        var fs: std.build.FileSource = std.build.FileSource{ .path = gst_file_path };
        const c = b.addTranslateC(fs);
        const include_dirs: []const []const u8 = &.{ "/usr/include/gstreamer-1.0", "/usr/include/aarch64-linux-gnu", "/usr/include/glib-2.0", "/usr/lib/aarch64-linux-gnu/glib-2.0/include" };
        for (include_dirs) |dir| {
            c.addIncludeDir(dir);
        }
        // https://github.com/ziglang/zig/issues/11040
        c.defineCMacroRaw("__sched_priority");
        c.output_dir = "src/bindings";
        const header_rpath = "src/bindings/gst.zig";
        const cwd: std.fs.Dir = try std.fs.openDirAbsolute(b.build_root, std.fs.Dir.OpenDirOptions{
            .access_sub_paths = true,
            .no_follow = true
        });
        // if file not existed yet, build it.
        _ = cwd.access(header_rpath, std.fs.File.OpenFlags{
            .mode = .read_only
        }) catch |e| {
            switch (e){
                 error.FileNotFound =>{
                    std.log.info("header bindings are not exist yet, try to generate!", .{});
                    try c.step.make();
                 },
                 else => return e
            }
        };
        const p = try std.fs.path.join(b.allocator, &.{b.build_root, header_rpath});
        std.log.info("header bindings is in `{s}`.", .{p});
    }

    const known_folders = Pkg {
        .name = "known",
        .source = .{ .path = "libs/known-folders/known-folders.zig"},
        .dependencies = null
    };

    const exe = b.addExecutable("zig-agora", "src/main.zig");
    const lib_rpath = "agora_sdk/lib/aarch64";
    const lib_path = try std.fs.path.join(b.allocator, &.{ b.build_root, lib_rpath });
    exe.addIncludePath("agora_sdk/include");
    // change this to x86_64 if you're using x86 machine
    exe.addLibraryPath(lib_path);
    exe.addPackage(known_folders);
    exe.linkLibC();
    // IT IS DASH NOT UNDERSCORE! FUCK IT!
    exe.linkSystemLibraryName("agora-rtc-sdk");
    // install gstreamer-1.0 from your package manager before build this
    // or use pkg-config exe.linkSystemLibraryPkgConfigOnly()
    exe.linkSystemLibrary("gstreamer-1.0");
    exe.linkSystemLibrary("gstreamer-app-1.0");
    exe.setBuildMode(mode);
    exe.setTarget(target);
    exe.install();

    std.log.info("Build finished! \n", .{});

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
