import AVFoundation
import AppKit
import Combine

final class AudioService: ObservableObject {
    private var players: [String: NSSound] = [:]
    @Published var currentPack: SoundPack?

    func loadSoundPack(_ pack: SoundPack) {
        players.removeAll()

        for sound in pack.sounds {
            guard let url = soundURL(for: sound, in: pack) else { continue }
            if let nsSound = NSSound(contentsOf: url, byReference: true) {
                players[sound.id] = nsSound
            }
        }
        currentPack = pack
    }

    func play(intensity: Float) {
        guard let pack = currentPack else { return }

        let eligible = pack.sounds.filter { $0.intensityRange.contains(intensity) }
        guard let sound = eligible.randomElement() ?? pack.sounds.last else { return }

        guard let nsSound = players[sound.id] else { return }

        // Stop if already playing, then play
        nsSound.stop()
        nsSound.volume = Constants.minVolume + (intensity * (Constants.maxVolume - Constants.minVolume))
        nsSound.play()
    }

    /// Play a specific sound by ID
    func playSound(id: String, intensity: Float) {
        guard let nsSound = players[id] else { return }
        nsSound.stop()
        nsSound.volume = Constants.minVolume + (intensity * (Constants.maxVolume - Constants.minVolume))
        nsSound.play()
    }

    func playRandom() {
        let randomIntensity = Float.random(in: 0.5...1.0)
        play(intensity: randomIntensity)
    }

    /// Optional reference to SoundPackManager for resolving custom pack paths
    var soundPackManager: SoundPackManager?

    private func soundURL(for sound: SoundFile, in pack: SoundPack) -> URL? {
        if pack.isSystem {
            // First check bundle resources (for bundled packs like SlapMac)
            if let bundleURL = Bundle.main.url(forResource: sound.fileName, withExtension: sound.fileExtension) {
                return bundleURL
            }
            // Then check system sounds
            let path = "\(Constants.systemSoundsPath)/\(sound.fileName).\(sound.fileExtension)"
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
            return nil
        }

        // Custom pack: look in Application Support directory
        if let manager = soundPackManager {
            let packDir = manager.packDirectory(for: pack.id)
            let url = packDir.appendingPathComponent("\(sound.fileName).\(sound.fileExtension)")
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }

        // Fallback to bundle
        return Bundle.main.url(forResource: sound.fileName, withExtension: sound.fileExtension)
    }
}
