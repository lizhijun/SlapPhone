import Foundation

enum Constants {
    static let appName = "SlapMac"
    static let defaultSensitivity: Double = 0.8
    static let defaultCooldown: Double = 0.5
    static let minCooldown: Double = 0.2
    static let maxCooldown: Double = 5.0

    // Accelerometer
    static let baseThresholdG: Double = 0.02
    static let maxExpectedG: Double = 0.10
    static let gravityFilterAlpha: Double = 0.9

    // Audio
    static let minVolume: Float = 0.3
    static let maxVolume: Float = 1.0

    // System sound paths
    static let systemSoundsPath = "/System/Library/Sounds"
}
