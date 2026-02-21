//
//  Renderer.swift
//  RTRBaseline
//
//  Created by Hoàng Trí Tâm on 19/2/26.
//

import Foundation
import Metal
import MetalKit
import QuartzCore
import simd

final class Renderer {
    private var device: MTLDevice!
    private var queue: MTLCommandQueue!
    private var pipeline: MTLRenderPipelineState!
    private var depthState: MTLDepthStencilState?

    private var vertexBuffer: MTLBuffer!
    private var indexBuffer: MTLBuffer!
    private var indexCount: Int = 0

    private var startTime = CACurrentMediaTime()
    private var lastFrameTime = CACurrentMediaTime()

    private var elapsedTime: Float = 0
    private var currentUniforms = CoreUniforms()
    
    private weak var hud: HUDModel?
    
    struct Vertex {
        var position: SIMD3<Float>
        var color: SIMD3<Float>
    }

    init(hud: HUDModel) {
        self.hud = hud
    }

    func attach(to view: MTKView) {
        guard let d = view.device else {
            fatalError("Metal is not supported on this device.")
        }
        self.device = d

        guard let q = d.makeCommandQueue() else {
            fatalError("Failed to create MTLCommandQueue.")
        }
        self.queue = q

        buildPipeline(view: view)
        uploadGeometry()
    }

    func drawableSizeWillChange(size: CGSize) {
        // Keep for later: projection updates, offscreen targets, etc.
    }

    func draw(in view: MTKView) {
        let now = CACurrentMediaTime()
        
        // Ensure minimum time change is 0.0001s, which shall avoid value overflow in the FPS
        let dt = max(0.0001, now - self.lastFrameTime)

        self.lastFrameTime = now
        
        self.updateHUD(dt: dt)
        self.update(dt: dt, view: view)
        self.render(in: view)
    }
    
    private func update(dt: Double, view: MTKView) {
        // Advance simulation time (useful once you have multiple animated objects/camera)
        self.elapsedTime += Float(dt)

        // Guard against temporary zero-sized drawable during resize/minimize
        let w = max(1.0, view.drawableSize.width)
        let h = max(1.0, view.drawableSize.height)
        let aspect = Float(w / h)

        // Build current frame uniforms (MVP) via C++ core
        coreMakeDefaultUniforms(&currentUniforms, self.elapsedTime, aspect)
    }
    
    private func render(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let rpd = view.currentRenderPassDescriptor else { return }
        
        guard let cmd = self.queue.makeCommandBuffer(),
              let enc = cmd.makeRenderCommandEncoder(descriptor: rpd) else { return }

        enc.setRenderPipelineState(self.pipeline)
        if let ds = self.depthState { enc.setDepthStencilState(ds) }

        enc.setVertexBuffer(self.vertexBuffer, offset: 0, index: 0)
        enc.setVertexBytes(&self.currentUniforms, length: MemoryLayout<CoreUniforms>.stride, index: 1)

        enc.drawIndexedPrimitives(
            type: .triangle,
            indexCount: self.indexCount,
            indexType: .uint16,
            indexBuffer: self.indexBuffer,
            indexBufferOffset: 0
        )

        enc.endEncoding()
        cmd.present(drawable)
        cmd.commit()
    }
    
    private func buildVertexDescriptor(view: MTKView) -> MTLVertexDescriptor {
        let vDesc = MTLVertexDescriptor()
        vDesc.attributes[0].format = .float3
        vDesc.attributes[0].offset = 0
        vDesc.attributes[0].bufferIndex = 0
        
        vDesc.attributes[1].format = .float3
        vDesc.attributes[1].offset = MemoryLayout<SIMD3<Float>>.stride
        vDesc.attributes[1].bufferIndex = 0
        
        vDesc.layouts[0].stride = MemoryLayout<Vertex>.stride
        vDesc.layouts[0].stepFunction = .perVertex
        vDesc.layouts[0].stepRate = 1
        return vDesc
    }

    private func buildPipeline(view: MTKView) {
        guard let library = self.device.makeDefaultLibrary() else {
            fatalError("Failed to load default Metal library. Ensure Shaders/*.metal is in the target.")
        }

        let vfn = library.makeFunction(name: "vs_main")
        let ffn = library.makeFunction(name: "fs_main")
        if vfn == nil || ffn == nil {
            fatalError("Missing shader functions vs_main/fs_main.")
        }

        let desc = MTLRenderPipelineDescriptor()
        desc.label = "RTRBaselinePipeline"
        desc.vertexFunction = vfn
        desc.fragmentFunction = ffn
        desc.colorAttachments[0].pixelFormat = view.colorPixelFormat
        desc.vertexDescriptor = self.buildVertexDescriptor(view: view)
        
        // Depth is optional in baseline. Uncomment when you add a depth attachment.
        // desc.depthAttachmentPixelFormat = .depth32Float

        do {
            self.pipeline = try self.device.makeRenderPipelineState(descriptor: desc)
        } catch {
            fatalError("Failed to create pipeline state: \(error)")
        }

        // Depth state placeholder (disabled by default because we don't create a depth texture yet)
        // let dsDesc = MTLDepthStencilDescriptor()
        // dsDesc.isDepthWriteEnabled = true
        // dsDesc.depthCompareFunction = .lessEqual
        // depthState = device.makeDepthStencilState(descriptor: dsDesc)
    }

    private func uploadGeometry() {
        // Get data from C++ core
        var vPtr: UnsafeMutablePointer<CoreVertex>?
        var vCount: Int32 = 0
        var iPtr: UnsafeMutablePointer<UInt16>?
        var iCount: Int32 = 0

        coreMakeTriangle(&vPtr, &vCount, &iPtr, &iCount)

        guard let vPtrUnwrapped = vPtr, let iPtrUnwrapped = iPtr else {
            fatalError("coreMakeTriangle returned null pointers.")
        }

        self.indexCount = Int(iCount)

        self.vertexBuffer = self.device.makeBuffer(
            bytes: vPtrUnwrapped,
            length: Int(vCount) * MemoryLayout<CoreVertex>.stride,
            options: [.storageModeShared]
        )

        self.indexBuffer = self.device.makeBuffer(
            bytes: iPtrUnwrapped,
            length: Int(iCount) * MemoryLayout<UInt16>.stride,
            options: [.storageModeShared]
        )

        // Free allocations from C++ core
        coreFreeTriangle(vPtrUnwrapped, iPtrUnwrapped)
    }

    private func updateHUD(dt: Double) {
        let fps = 1.0 / dt
        let ms = dt * 1000.0
        DispatchQueue.main.async { [weak hud] in
            hud?.update(fps: fps, frameMs: ms)
        }
    }
}
