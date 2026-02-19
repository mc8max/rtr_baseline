//
//  CoreBridge.cpp
//  RTRBaseline
//
//  Created by Hoàng Trí Tâm on 19/2/26.
//

#include "CoreBridge.h"
#include "CoreMath.hpp"
#include <new>

void coreMakeTriangle(CoreVertex** outVertices, int32_t* outVertexCount,
                      uint16_t** outIndices, int32_t* outIndexCount) {
    if (!outVertices || !outVertexCount || !outIndices || !outIndexCount) return;

    *outVertexCount = 3;
    *outIndexCount = 3;

    CoreVertex* v = new CoreVertex[*outVertexCount];
    uint16_t* i = new uint16_t[*outIndexCount];

    // CCW triangle in clip-friendly space
    v[0] = { { -0.6f, -0.4f, 0.0f }, { 1.0f, 0.2f, 0.2f } };
    v[1] = { {  0.0f,  0.6f, 0.0f }, { 0.2f, 1.0f, 0.2f } };
    v[2] = { {  0.6f, -0.4f, 0.0f }, { 0.2f, 0.4f, 1.0f } };

    i[0] = 0; i[1] = 1; i[2] = 2;

    *outVertices = v;
    *outIndices = i;
}

void coreFreeTriangle(CoreVertex* vertices, uint16_t* indices) {
    delete[] vertices;
    delete[] indices;
}

void coreMakeDefaultUniforms(CoreUniforms* outUniforms, float timeSeconds, float aspect) {
    if (!outUniforms) return;

    using namespace coremath;

    const Mat4 model = rotationY(timeSeconds) * rotationX(timeSeconds * 0.5f);
    const Mat4 view  = lookAt({0.0f, 0.0f, 2.2f}, {0.0f, 0.0f, 0.0f}, {0.0f, 1.0f, 0.0f});
    const Mat4 proj  = perspective(60.0f * kDegToRad, aspect, 0.1f, 100.0f);

    const Mat4 mvp = proj * view * model;

    // Copy to float[16] column-major
    for (int c = 0; c < 4; ++c) {
        for (int r = 0; r < 4; ++r) {
            outUniforms->mvp[c*4 + r] = mvp.m[c][r];
        }
    }
}
