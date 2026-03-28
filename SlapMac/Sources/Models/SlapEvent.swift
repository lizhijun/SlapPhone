import Foundation

struct SlapEvent {
    let timestamp: Date
    let intensity: Float  // 0.0-1.0 normalized force
    let rawAcceleration: (x: Double, y: Double, z: Double)
}
