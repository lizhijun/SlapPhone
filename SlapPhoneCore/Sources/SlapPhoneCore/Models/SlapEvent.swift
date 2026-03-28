import Foundation

public struct SlapEvent: Sendable {
    public let timestamp: Date
    public let intensity: Float  // 0.0-1.0 normalized
    public let rawAcceleration: (x: Double, y: Double, z: Double)

    public init(timestamp: Date, intensity: Float, rawAcceleration: (x: Double, y: Double, z: Double)) {
        self.timestamp = timestamp
        self.intensity = intensity
        self.rawAcceleration = rawAcceleration
    }
}
