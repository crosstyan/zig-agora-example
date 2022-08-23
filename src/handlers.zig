const agora = @import("bindings/agora.zig");
const std = @import("std");
const log = std.log;

pub fn on_join_channel_success(conn_id: u32, uid: u32, elapsed: c_int) callconv(.C) void {
    log.info("on_join_channel_success: conn_id={} uid={} elapsed={}", .{conn_id, uid, elapsed});
}

pub fn on_connection_lost(conn_id: u32) callconv(.C) void {
    log.err("on_connection_lost: conn_id={}", .{conn_id});
}

pub fn on_rejoin_channel_success(conn_id: u32, uid: u32, elapsed: c_int) callconv(.C) void {
  log.info("on_rejoin_channel_success: conn_id={} uid={} elapsed={}", .{conn_id, uid, elapsed});
}

pub fn on_error(conn_id: u32, error_code: c_int, err: [*:0]const u8) callconv(.C) void {
    log.err("on_error: conn_id={} error_code={} err={s}", .{conn_id, error_code, err});
}

pub fn on_user_joined(conn_id: u32, uid: u32, elapsed: c_int) callconv(.C) void {
    log.info("on_user_joined: conn_id={} uid={} elapsed={}", .{conn_id, uid, elapsed});
}

pub fn on_user_offline(conn_id: u32, uid: u32, reason: c_int) callconv(.C) void {
  log.warn("on_user_offline: conn_id={} uid={} reason={}", .{conn_id, uid, reason});
}

pub fn on_user_mute_audio(conn_id: u32, uid: u32, muted: bool) callconv(.C) void {
  log.info("on_user_mute_audio: conn_id={} uid={} muted={}", .{conn_id, uid, muted});
}

pub fn on_user_mute_video(conn_id: u32, uid: u32, muted: bool) callconv(.C) void {
  log.info("on_user_mute_video: conn_id={} uid={} muted={}", .{conn_id, uid, muted});
}

pub fn on_target_bitrate_changed(conn_id: u32, bitrate: u32) callconv(.C) void {
  log.info("on_target_bitrate_changed: conn_id={} bitrate={}", .{conn_id, bitrate});
}

pub fn on_token_privilege_will_expire(conn_id: u32, token: [*:0]const u8) callconv(.C) void {
  log.info("on_token_privilege_will_expire: conn_id={} token={s}", .{conn_id, token});
}