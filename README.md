# Zig Agora RTSA example

An example stream to Agora by GStreamer with [`videotestsrc`](https://gstreamer.freedesktop.org/documentation/videotestsrc/index.html)
and H264. I tried H265 but no luck.

I will say it's kind of crazy experience with zig. It will tell you when the allocator will kick in, 
which is good? Its C interop should be good in theory...but [`[*c]`](https://github.com/ziglang/zig/issues/1059) is the big
problem for interop. You SHOULD rewrite every function with C pointer. 

Zig will translate C files (header or source) to `.zig`. I wish I can write type annotation in another folder and Zig can
apply to the translated Zig code. `cImport` is also confusing. If you want to edit your generated zig file, the best way
is to utilize `build.zig` with `addTranslateC`, then import it.

By the way the [Zig Language Server](https://github.com/zigtools/zls) often crashes when parsing large files, which means
I have to look for documentation by myself.

## Usage

This repo should have [Agora SDK](https://docs.agora.io/cn/RTSA/downloads?platform=Linux) `aarch64-linux-gnu`. `x86_64` is not included
and you should install by yourself and modify `addLibraryPath` in `build.zig`

`build.zig` is actually a build script (may not the conventional script) which will call `zig build-exe` or `zig translate-c`
or anything else. In theory you can complete that with python script. 

The config file will be stored in your local configuration folder, which should be `~/.config` in Linux. 
