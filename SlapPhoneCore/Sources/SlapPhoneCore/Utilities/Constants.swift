import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

public enum Constants {
    public static let appName = "SlapPhone"

    // Detection algorithm (platform-agnostic)
    public static let defaultSensitivity: Double = 0.8
    public static let defaultCooldown: Double = 0.5
    public static let minCooldown: Double = 0.2
    public static let maxCooldown: Double = 5.0
    public static let baseThresholdG: Double = 0.02
    public static let maxExpectedG: Double = 0.10
    public static let gravityFilterAlpha: Double = 0.9
    public static let warmupSeconds: Double = 2.0

    // Audio
    public static let minVolume: Float = 0.3
    public static let maxVolume: Float = 1.0
    public static let supportedAudioExtensions = ["mp3", "wav", "aiff", "m4a", "aac", "caf"]

    // Visual
    public static let flashMaxAlpha: CGFloat = 0.6
    public static let flashDuration: Double = 0.15

    // Storage
    public static let soundPacksDir = "SoundPacks"
    public static let packMetadataFile = "pack.json"

    // App Group for Watch sync
    public static let appGroupIdentifier = "group.com.slapphone.shared"
}
