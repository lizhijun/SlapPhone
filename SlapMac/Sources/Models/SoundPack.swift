import Foundation

struct SoundPack: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let sounds: [SoundFile]
    let isSystem: Bool

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: SoundPack, rhs: SoundPack) -> Bool {
        lhs.id == rhs.id
    }
}

struct SoundFile: Identifiable, Hashable {
    let id: String
    let fileName: String
    let fileExtension: String
    let minIntensity: Float  // 0.0-1.0
    let maxIntensity: Float  // 0.0-1.0

    var intensityRange: ClosedRange<Float> {
        minIntensity...maxIntensity
    }
}

// MARK: - Default Sound Packs

extension SoundPack {
    static let systemPack = SoundPack(
        id: "system",
        name: "System",
        description: "macOS system sounds",
        sounds: [
            SoundFile(id: "basso", fileName: "Basso", fileExtension: "aiff", minIntensity: 0.0, maxIntensity: 0.25),
            SoundFile(id: "funk", fileName: "Funk", fileExtension: "aiff", minIntensity: 0.25, maxIntensity: 0.5),
            SoundFile(id: "glass", fileName: "Glass", fileExtension: "aiff", minIntensity: 0.5, maxIntensity: 0.75),
            SoundFile(id: "hero", fileName: "Hero", fileExtension: "aiff", minIntensity: 0.75, maxIntensity: 1.0),
        ],
        isSystem: true
    )

    static let alertPack = SoundPack(
        id: "alert",
        name: "Alert",
        description: "Alert and notification sounds",
        sounds: [
            SoundFile(id: "tink", fileName: "Tink", fileExtension: "aiff", minIntensity: 0.0, maxIntensity: 0.3),
            SoundFile(id: "pop", fileName: "Pop", fileExtension: "aiff", minIntensity: 0.3, maxIntensity: 0.6),
            SoundFile(id: "sosumi", fileName: "Sosumi", fileExtension: "aiff", minIntensity: 0.6, maxIntensity: 0.85),
            SoundFile(id: "purr", fileName: "Purr", fileExtension: "aiff", minIntensity: 0.85, maxIntensity: 1.0),
        ],
        isSystem: true
    )

    static let dramaticPack = SoundPack(
        id: "dramatic",
        name: "Dramatic",
        description: "Dramatic impact sounds",
        sounds: [
            SoundFile(id: "morse", fileName: "Morse", fileExtension: "aiff", minIntensity: 0.0, maxIntensity: 0.3),
            SoundFile(id: "ping", fileName: "Ping", fileExtension: "aiff", minIntensity: 0.3, maxIntensity: 0.6),
            SoundFile(id: "submarine", fileName: "Submarine", fileExtension: "aiff", minIntensity: 0.6, maxIntensity: 0.85),
            SoundFile(id: "blow", fileName: "Blow", fileExtension: "aiff", minIntensity: 0.85, maxIntensity: 1.0),
        ],
        isSystem: true
    )

    static let allPacks: [SoundPack] = [systemPack, alertPack, dramaticPack]
}
