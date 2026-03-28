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

struct SoundFile: Identifiable, Hashable, Codable {
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

    static let slapMacPack = SoundPack(
        id: "slapmac",
        name: "SlapMac",
        description: "The original SlapMac sound pack",
        sounds: [
            SoundFile(id: "combo", fileName: "combo", fileExtension: "mp3", minIntensity: 0.0, maxIntensity: 0.09),
            SoundFile(id: "fart", fileName: "fart", fileExtension: "mp3", minIntensity: 0.09, maxIntensity: 0.18),
            SoundFile(id: "gentleman", fileName: "gentleman", fileExtension: "wav", minIntensity: 0.18, maxIntensity: 0.27),
            SoundFile(id: "goat", fileName: "goat", fileExtension: "mp3", minIntensity: 0.27, maxIntensity: 0.36),
            SoundFile(id: "knock", fileName: "knock", fileExtension: "mp3", minIntensity: 0.36, maxIntensity: 0.45),
            SoundFile(id: "male", fileName: "male", fileExtension: "mp3", minIntensity: 0.45, maxIntensity: 0.54),
            SoundFile(id: "muyu", fileName: "muyu", fileExtension: "mp3", minIntensity: 0.54, maxIntensity: 0.63),
            SoundFile(id: "punch", fileName: "punch", fileExtension: "mp3", minIntensity: 0.63, maxIntensity: 0.72),
            SoundFile(id: "sexy", fileName: "sexy", fileExtension: "mp3", minIntensity: 0.72, maxIntensity: 0.81),
            SoundFile(id: "wtf", fileName: "wtf", fileExtension: "mp3", minIntensity: 0.81, maxIntensity: 0.90),
            SoundFile(id: "yamete", fileName: "yamete", fileExtension: "mp3", minIntensity: 0.90, maxIntensity: 1.0),
        ],
        isSystem: true
    )

    static let builtInPacks: [SoundPack] = [slapMacPack, systemPack, alertPack, dramaticPack]

    /// Use SoundPackManager.allPacks for full list including custom packs.
    /// This is kept for backward compatibility.
    static let allPacks: [SoundPack] = builtInPacks
}
