// zig cc test.c -L agora_sdk/lib/aarch64 -lagora-rtc-sdk
// zig build-exe test.c -lc -L agora_sdk/lib/aarch64/ -lagora-rtc-sdk
// don't forget the final link
#include <stdio.h>
#include "agora_sdk/include/agora_rtc_api.h"

int main(){
 const char * version = agora_rtc_get_version();
 printf("Agora SDK Version: %s\n", version);
 return 0;
}