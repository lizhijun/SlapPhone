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

    func playRandom() {
        let randomIntensity = Float.random(in: 0.5...1.0)
        play(intensity: randomIntensity)
    }

    private func soundURL(for sound: SoundFile, in pack: SoundPack) -> URL? {
        if pack.isSystem {
            let path = "\(Constants.systemSoundsPath)/\(sound.fileName).\(sound.fileExtension)"
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
            return nil
        }
        return Bundle.main.url(forResource: sound.fileName, withExtension: sound.fileExtension)
    }
}
