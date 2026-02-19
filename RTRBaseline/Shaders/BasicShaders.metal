//
//  BasicShaders.metal
//  RTRBaseline
//
//  Created by Hoàng Trí Tâm on 19/2/26.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float3 position [[attribute(0)]];
    float3 color    [[attribute(1)]];
};

struct Uniforms {
    float4x4 mvp;
};

struct VSOut {
    float4 position [[position]];
    float3 color;
};

vertex VSOut vs_main(VertexIn in [[stage_in]],
                     constant Uniforms& u [[buffer(1)]]) {
    VSOut out;
    out.position = u.mvp * float4(in.position, 1.0);
    out.color = in.color;
    return out;
}

fragment float4 fs_main(VSOut in [[stage_in]]) {
    return float4(in.color, 1.0);
}
