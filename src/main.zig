// https://github.com/zigtools/zls/issues/313
const agora = @import("bindings/agora.zig");
const gst = @import("bindings/gst.zig");
const std = @import("std");
const log = std.log;


pub fn main() void {
  var args = std.os.argv;
  var argc = @intCast(c_int,args.len);
  var major: u32 = undefined;
  var minor: u32 = undefined; 
  var micro: u32 = undefined; 
  var nano : u32 = undefined;
  _ = gst.gst_init(&argc, @ptrCast([*c][*c][*c]u8,&args));
  _ = gst.gst_version (&major, &minor, &micro, &nano);

  var nano_str: []const u8 = switch (nano) {
    1 => "(CVS)",
    2 => "(Prerelease)",
    else => ""
  };

  const version: [*:0]const u8 = agora.agora_rtc_get_version();
  log.info("Agora SDK version: {s}", .{version});
  log.info("GStreamer {}.{}.{} {s}", .{major, minor, micro, nano_str});
  log.info("Hello World\n", .{});
}