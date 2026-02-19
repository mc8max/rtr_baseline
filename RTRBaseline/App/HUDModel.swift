//
//  HUDModel.swift
//  RTRBaseline
//
//  Created by Hoàng Trí Tâm on 19/2/26.
//

import Foundation
import Combine

final class HUDModel: ObservableObject {
    @Published var fpsText: String = "FPS: --"
    @Published var msText: String = "Frame: -- ms"

    func update(fps: Double, frameMs: Double) {
        fpsText = String(format: "FPS: %.0f", fps)
        msText = String(format: "Frame: %.2f ms", frameMs)
    }
}
