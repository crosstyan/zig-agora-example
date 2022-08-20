# zig build-exe src/main.zig --name zig-agora -I agora_sdk/include -lc -L agora_sdk/lib/aarch64 -lagora-rtc-sdk
# it works even -l is placed before -L?
# https://github.com/ziglang/zig/issues/11801
zig build-exe src/main.zig --name zig-agora -lc -lagora-rtc-sdk -I agora_sdk/include -L agora_sdk/lib/aarch64 