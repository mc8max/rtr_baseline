//
//  OrbitMTKView.swift
//  RTRBaseline
//
//  Created by Hoàng Trí Tâm on 22/2/26.
//

import MetalKit
import AppKit

final class OrbitMTKView: MTKView {
    var onOrbitDrag: ((Float, Float) -> Void)?
    var onZoom: ((Float) -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        super.mouseDown(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        onOrbitDrag?(Float(event.deltaX), Float(event.deltaY))
    }

    override func scrollWheel(with event: NSEvent) {
        // Optional: ignore inertial/momentum scroll for more controllable zoom
        if !event.momentumPhase.isEmpty {
            return
        }

        // Trackpad usually reports precise deltas; mouse wheel is coarse "step" deltas.
        let rawY: CGFloat
        if event.hasPreciseScrollingDeltas {
            rawY = event.scrollingDeltaY
        } else {
            // Mouse wheel: amplify a bit because wheel steps are coarse
            rawY = event.scrollingDeltaY * 8.0
        }

        onZoom?(Float(rawY))
    }
}
