import Foundation

public struct SoundPack: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public let name: String
    public let description: String
    public let sounds: [SoundFile]
    public let isSystem: Bool

    public init(id: String, name: String, description: String, sounds: [SoundFile], isSystem: Bool) {
        self.id = id
        self.name = name
        self.description = description
        self.sounds = sounds
        self.isSystem = isSystem
    }

    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
    public static func == (lhs: SoundPack, rhs: SoundPack) -> Bool { lhs.id == rhs.id }
}

public struct SoundFile: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public let fileName: String
    public let fileExtension: String
    public let minIntensity: Float
    public let maxIntensity: Float

    public var intensityRange: ClosedRange<Float> { minIntensity...maxIntensity }

    public init(id: String, fileName: String, fileExtension: String, minIntensity: Float, maxIntensity: Float) {
        self.id = id
        self.fileName = fileName
        self.fileExtension = fileExtension
        self.minIntensity = minIntensity
        self.maxIntensity = maxIntensity
    }
}

// Built-in packs
extension SoundPack {
    public static let slapPhonePack = SoundPack(
        id: "slapphone",
        name: "SlapPhone",
        description: "The original SlapPhone sound pack",
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

    public static let builtInPacks: [SoundPack] = [slapPhonePack]
}
