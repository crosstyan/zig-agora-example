// https://github.com/ziglang/zig/issues/1059
// https://github.com/zigtools/zls/issues/313
const agora = @import("bindings/agora.zig");
const gst = @import("bindings/gst.zig");
const std = @import("std");
const toml = @import("toml");
const defaultHandler = @import("handlers.zig");
const log = std.log;
const File = std.fs.File;

fn panicWhenError(code: c_int) void {
    if (code != 0) {
        const err_str = agora.agora_rtc_err_2_str(code);
        std.debug.panic("agora_rtc_license_verify failed: {s}", .{err_str});
    }
}

fn logWhenError(code: c_int) void {
    if (code != 0) {
        const err_str = agora.agora_rtc_err_2_str(code);
        log.err("agora_rtc_license_verify failed: {s}", .{err_str});
    }
}

const NewSampleParams = struct {
    conn_id: u32,
    file_handle: ?File,
    video_info: *agora.video_frame_info_t,
};

// https://github.com/ziglang/zig/issues/1717
fn new_sample_cb(appsink: *gst.GstAppSink, user_data: ?*anyopaque) callconv(.C) gst.GstFlowReturn {
    var params = @ptrCast(*NewSampleParams, @alignCast(@alignOf(*NewSampleParams), user_data));
    var sample = gst.gst_app_sink_pull_sample(appsink);
    var buffer = gst.gst_sample_get_buffer(sample);
    var mem = gst.gst_buffer_get_all_memory(buffer);
    var info: gst.GstMapInfo = undefined;
    // Returns – TRUE if the map operation was successful.
    // https://github.com/ziglang/zig/issues/2841
    var success = gst.gst_memory_map(mem, &info, gst.GST_MAP_READ) != 0;
    defer if (success) {
        gst.gst_memory_unmap(mem, &info);
    };
    if (success) {
        var code = agora.agora_rtc_send_video_data(params.*.conn_id, info.data, info.size, params.*.video_info);
        if (code != 0) {
            logWhenError(code);
        } else {
            std.io.getStdOut().writer().print("*", .{}) catch unreachable;
        }
    } else {
        log.err("gst_memory_map failed", .{});
    }
    return gst.GST_FLOW_OK;
}

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator: std.mem.Allocator = gpa.allocator();

pub fn main() !void {
    const app_id: [:0]const u8 = "3759fd9101e04094869e7e69b9b3fe64";
    const channel_name: [:0]const u8 = "test";
    const app_token: [:0]const u8 = "007eJxTYGj+/iiralfpa76AYn8j3nwV82MezTuifDn7ws3WCPY901FgMDY3tUxLsTQ0MEw1MDGwNLEws0w1TzWzTLJMMk5LNTMJaGFJvnCVNfntww2sjAwQCOKzMJSkFpcwMAAA6z8gJA==";
    const log_path: [:0]const u8 = "logs";
    const uid: u32 = 1234;
    const pipeline: [:0]const u8 =
        \\ videotestsrc name=src is-live=true ! 
        \\ clockoverlay ! 
        \\ videoconvert ! 
        \\ x264enc ! 
        \\ appsink name=agora 
    ;

    const cwd = std.fs.cwd();
    const cert_file = try cwd.openFile("certificate.bin", std.fs.File.OpenFlags{ .mode = File.OpenMode.read_only });
    const cert_str: []u8 = try cert_file.readToEndAlloc(allocator, 10240);

    const version: [*:0]const u8 = agora.agora_rtc_get_version();
    log.info("Agora SDK version: {s}", .{version});

    var args = std.os.argv;
    var argc = @intCast(c_int, args.len);

    // See also /usr/include/gstreamer-1.0/gst/app
    // https://gstreamer.freedesktop.org/documentation/applib/gstappsink.html?gi-language=c#GstAppSinkCallbacks
    var appsink_cbs = gst.GstAppSinkCallbacks{ .eos = null, .new_preroll = null, .new_sample = new_sample_cb, .new_event = null, ._gst_reserved = std.mem.zeroes([3]gst.gpointer) };

    _ = gst.gst_init(&argc, @ptrCast(*[*][*:0]u8, &args));
    defer gst.gst_deinit();
    const gst_version_str = gst.gst_version_string();
    log.info("{s}", .{gst_version_str});
    var ctx = gst.gst_parse_context_new();
    defer gst.gst_parse_context_free(ctx);
    var pipe = gst.gst_parse_launch(pipeline, null); // don't care error
    defer gst.gst_object_unref(pipe);
    var appsink = gst.gst_bin_get_by_name(@ptrCast(*gst.GstBin, pipe), "agora");
    defer gst.gst_object_unref(appsink);
    // I can't do this shit any more!
    // manual annotation is Okay...but zls always crashes. "memory leak" she said.
    // How shoudld I regenrate ".zig" while preserving my annotation? I don't think there's official way to do this.

    var err: c_int = undefined;
    err = agora.agora_rtc_license_verify(@ptrCast([*]const u8, cert_str), @intCast(c_int, cert_str.len), null, 0);
    panicWhenError(err);
    log.info("agora_rtc_license_verify success", .{});

    const handler = agora.agora_rtc_event_handler_t{
        .on_join_channel_success = defaultHandler.on_join_channel_success,
        .on_connection_lost = defaultHandler.on_connection_lost,
        .on_rejoin_channel_success = defaultHandler.on_rejoin_channel_success,
        .on_error = defaultHandler.on_error,
        .on_user_joined = defaultHandler.on_user_joined,
        .on_user_offline = defaultHandler.on_user_offline,
        .on_user_mute_audio = defaultHandler.on_user_mute_audio,
        .on_user_mute_video = defaultHandler.on_user_mute_video,
        .on_audio_data = null,
        .on_mixed_audio_data = null,
        .on_video_data = null,
        .on_target_bitrate_changed = defaultHandler.on_target_bitrate_changed,
        .on_key_frame_gen_req = null,
        .on_token_privilege_will_expire = defaultHandler.on_token_privilege_will_expire,
    };

    const log_cfg = agora.log_config_t{ .log_disable = false, .log_disable_desensitize = true, .log_level = agora.RTC_LOG_INFO, .log_path = log_path };
    // I will say it will be good
    var service_option = agora.rtc_service_option_t{
        .area_code = agora.AREA_CODE_CN,
        .product_id = std.mem.zeroes([64]u8),
        .log_cfg = log_cfg,
        .license_value = std.mem.zeroes([33]u8),
    };
    var codec_opt = agora.audio_codec_option_t{
        .audio_codec_type = agora.AUDIO_CODEC_DISABLED,
        .pcm_sample_rate = 0,
        .pcm_channel_num = 0,
    };
    var chan_opt = agora.rtc_channel_options_t{
        .auto_subscribe_audio = false,
        .auto_subscribe_video = false,
        .subscribe_local_user = false,
        .enable_audio_jitter_buffer = false,
        .enable_audio_mixer = false,
        .audio_codec_opt = codec_opt,
        .enable_aut_encryption = false,
    };

    err = agora.agora_rtc_init(app_id, &handler, &service_option);
    panicWhenError(err);
    defer {
        err = agora.agora_rtc_fini();
        panicWhenError(err);
        log.info("agora_rtc_fini", .{});
    }
    log.info("agora_rtc_init success", .{});

    var conn_id: u32 = undefined;
    err = agora.agora_rtc_create_connection(&conn_id);
    panicWhenError(err);
    defer {
        err = agora.agora_rtc_destroy_connection(conn_id);
        panicWhenError(err);
        log.info("agora_rtc_destroy_connection", .{});
    }
    log.info("agora_rtc_create_connection success with conn_id {}", .{conn_id});

    err = agora.agora_rtc_join_channel(conn_id, channel_name, uid, app_token, &chan_opt);
    panicWhenError(err);
    defer {
        err = agora.agora_rtc_leave_channel(conn_id);
        panicWhenError(err);
        log.info("agora_rtc_leave_channel", .{});
    }
    log.info("agora_rtc joined channel {s}", .{channel_name});
    _ = agora.agora_rtc_mute_local_audio(conn_id, true);

    var video_info = agora.video_frame_info_t{
        .data_type = agora.VIDEO_DATA_TYPE_H264,
        .stream_type = agora.VIDEO_STREAM_LOW,
        .frame_type = agora.VIDEO_FRAME_AUTO_DETECT,
        .frame_rate = 0,
    };

    var user_data = NewSampleParams{
        .conn_id = conn_id,
        .file_handle = null,
        .video_info = &video_info,
    };

    gst.gst_app_sink_set_callbacks(@ptrCast(*gst.GstAppSink, appsink), &appsink_cbs, &user_data, null);
    _ = gst.gst_element_set_state(@ptrCast(*gst.GstElement, pipe), gst.GST_STATE_PLAYING);
    defer {
        _ = gst.gst_element_set_state(@ptrCast(*gst.GstElement, pipe), gst.GST_STATE_NULL);
    }
    // sleep for 30 seconds
    const secs = 30 * 1000 * 1000 * 1000;
    // parameter is in nanoseconds
    std.time.sleep(secs);
}
