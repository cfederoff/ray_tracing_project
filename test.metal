#include <metal_stdlib>
#include <metal_logging>

using namespace metal;

kernel void my_kernel(...) {
    // Correct usage of os_log_default
    os_log_default.log("Your debug message here");
}
