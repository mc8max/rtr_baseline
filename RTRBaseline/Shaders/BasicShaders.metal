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

struct FragmentDebugParams {
    int mode;   // 0 vertexColor, 1 flatWhite, 2 rawDepth
    int pad0;
    int pad1;
    int pad2;
};

vertex VSOut vs_main(VertexIn in [[stage_in]],
                     constant Uniforms& u [[buffer(1)]]) {
    VSOut out;
    out.position = u.mvp * float4(in.position, 1.0);
    out.color = in.color;
    return out;
}

fragment float4 fs_main(VSOut in [[stage_in]],
                        constant FragmentDebugParams& dbg [[buffer(0)]]) {
    switch (dbg.mode) {
        case 1: // Flat white
            return float4(1.0, 1.0, 1.0, 1.0);

        case 2: {
            // Raw depth grayscale (post-projection depth in [0,1] for Metal)
            // `in.position` in fragment stage is screen-space position.
            // z is depth value after viewport transform convention.
            float d = 1 - saturate(in.position.z);
            return float4(d, d, d, 1.0);
        }

        case 0: // Vertex color
        default:
            return float4(in.color, 1.0);
    }
}		
