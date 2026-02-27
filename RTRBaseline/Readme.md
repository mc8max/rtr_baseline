# RTRBaseline

A minimal macOS realtime rendering baseline using SwiftUI + MetalKit, with a C++ core layer for mesh generation and camera math.

## What It Does

- Renders an indexed, per-face-colored cube in Metal.
- Uses a depth buffer (`.depth32Float`) with depth testing enabled (`lessEqual`).
- Draws continuously at a target of 60 FPS (`MTKView`).
- Displays an on-screen HUD with FPS, frame time (ms), and active debug mode.

## Camera And Input

- Orbit camera around a target point using mouse drag.
- Zoom in/out using mouse wheel or trackpad scroll.
- Clamps pitch to about `[-1.4, +1.4]` radians for stable orbit behavior.
- Clamps camera radius to `[0.8, 20.0]` in the Swift renderer.

## Shader Debug Modes

Press numeric keys in the render view:

- `1` = `VertexColor`
- `2` = `FlatWhite`
- `3` = `RawDepth`
- `4` = `LinearDepth`

The fragment shader supports both raw depth and linearized depth visualization for quick depth/debug inspection.

## Project Structure

- `RTRBaseline/App`: SwiftUI app shell, Metal view integration, renderer, HUD, and input handling.
- `RTRBaseline/Shaders/BasicShaders.metal`: vertex/fragment shaders (`vs_main`, `fs_main`) and depth visualization logic.
- `RTRBaseline/Core`: C/C++ bridge (`CoreBridge`), math helpers (`CoreMath.hpp`), mesh generation, and orbit-camera MVP creation.

## Rendering Pipeline Summary

- Swift `Renderer` creates device/queue/pipeline, uploads mesh buffers from C++ core, and issues indexed draws.
- Vertex layout is `position: float3` and `color: float3`.
- Uniforms provide an `mvp` matrix as column-major `float[16]` from the C++ camera/matrix code.
- Fragment debug parameters include debug mode and near/far planes for depth visualizations.

## Build And Run

1. Open `RTRBaseline.xcodeproj` in Xcode.
2. Select the `RTRBaseline` scheme.
3. Build and run on macOS.

## Notes

- The bridge header (`RTRBaseline/Core/RTRBaseline-Bridging-Header.h`) exposes C APIs from `CoreBridge.h` to Swift.
- Geometry memory is allocated in C++ and released from Swift via `coreFreeMesh` after creating Metal buffers.
