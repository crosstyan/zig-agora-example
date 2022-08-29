const std = @import("std");
const Builder = @import("std").build.Builder;
const Pkg = std.build.Pkg;

pub fn build(b: *Builder) !void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    // TODO: use struct to describe header
    // WARN: this gstreamer bindings generation is not include gstreamer app plugins
    // I should have written a wrapper (C header) and translate the whole unit
    // Now I'm doing this by call `zig translate-c` manually and merge them by hands with diff.
    // That's dumb!
    // ************* DON'T TRUST THIS BLOCK *************
    const header_list: []const []const u8 = &.{"gst/gst.h"};
    // change this to your gstreamer path
    const gst_path = "/usr/include/gstreamer-1.0";
    for (header_list) |header| {
        const gst_file_path: []const u8 = try std.fs.path.join(b.allocator, &.{gst_path, header});
        var fs: std.build.FileSource = std.build.FileSource{ .path = gst_file_path };
        const c = b.addTranslateC(fs);
        // https://ziglang.org/documentation/master/std/#root;build.TranslateCStep
        // `translate-c` (TranslateCStep) can't call `pkg-config`
        // to find the library I want to include so I have to do it manually
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
    // ************* BLOCK ENDS *************

    const known_folders = Pkg {
        .name = "known",
        .source = .{ .path = "libs/known-folders/known-folders.zig"},
        .dependencies = null
    };

    const exe = b.addExecutable("zig-agora", "src/main.zig");
    // change this to x86_64 if you're using x86 machine
    const lib_rpath = "agora_sdk/lib/aarch64";
    const lib_path = try std.fs.path.join(b.allocator, &.{ b.build_root, lib_rpath });
    exe.addIncludePath("agora_sdk/include");
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
