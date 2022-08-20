const agora = @cImport({
  @cInclude("agora_rtc_api.h");
});
const std = @import("std");
const log = std.log;

pub fn main() void {
  var version = agora.agora_rtc_get_version();
  log.info("Agora SDK version: {s}", .{version});
  log.info("Hello World\n", .{});
}