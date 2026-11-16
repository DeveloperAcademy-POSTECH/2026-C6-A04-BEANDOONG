#include <metal_stdlib>
using namespace metal;

// 고정된 광원 아래에서 유리 가장자리의 방향이 달라지는 반사 모델.
// 회전하는 밝은 점 대신, 면의 방향과 시선·광원 사이의 각도로 밝기를 구한다.
[[ stitchable ]] half4 settingsIconRim(
    float2 position, half4 color, float2 size, float2 tilt, float sharpness
) {
    float2 p = position - size * 0.5;
    float2 corner = max(abs(p) - (size * 0.5 - 22.0), float2(0.0));
    float2 outward = corner / max(length(corner), 0.001) * sign(p);
    float3 normal = normalize(float3(outward * 0.37, 0.93));

    // 작은 회전을 법선에 적용한다. 두 축을 하나의 회전각으로 합치지 않는다.
    float pitch = tilt.y * 0.24;
    float roll = -tilt.x * 0.24;
    normal = float3(normal.x,
                    normal.y * cos(pitch) - normal.z * sin(pitch),
                    normal.y * sin(pitch) + normal.z * cos(pitch));
    normal = float3(normal.x * cos(roll) + normal.z * sin(roll),
                    normal.y,
                    -normal.x * sin(roll) + normal.z * cos(roll));

    float3 view = float3(0.0, 0.0, 1.0);
    float3 keyLight = normalize(float3(-0.65, -0.85, 1.1));
    float3 bounceLight = normalize(float3(0.7, 0.9, 1.0));
    float key = pow(max(dot(normal, normalize(keyLight + view)), 0.0), sharpness);
    float bounce = pow(max(dot(normal, normalize(bounceLight + view)), 0.0), sharpness * 0.65);
    float brightness = min(0.92, 0.035 + key * 0.82 + bounce * 0.20);

    // 원래 테두리의 알파를 유지하고 중앙에는 빛을 더하지 않는다.
    half alpha = color.a * half(brightness);
    return half4(half3(0.94, 0.97, 1.0) * alpha, alpha);
}
