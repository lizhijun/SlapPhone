import AVFoundation
import Combine
import SlapPhoneCore

final class AudioService: ObservableObject {
    @Published var currentPack: SoundPack?

    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private let audioSession = AVAudioSession.sharedInstance()

    init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            print("Audio session config failed: \(error)")
        }
    }

    func loadSoundPack(_ pack: SoundPack) {
        audioPlayers.removeAll()

        for sound in pack.sounds {
            guard let url = soundURL(for: sound, in: pack) else { continue }
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                audioPlayers[sound.id] = player
            } catch {
                print("Failed to load \(sound.fileName): \(error)")
            }
        }
        currentPack = pack
    }

    func play(intensity: Float) {
        guard let pack = currentPack else { return }

        let eligible = pack.sounds.filter { $0.intensityRange.contains(intensity) }
        guard let sound = eligible.randomElement() ?? pack.sounds.last else { return }

        playSound(id: sound.id, intensity: intensity)
    }

    func playSound(id: String, intensity: Float) {
        guard let player = audioPlayers[id] else { return }

        player.volume = Constants.minVolume + (intensity * (Constants.maxVolume - Constants.minVolume))
        player.currentTime = 0
        player.play()
    }

    private func soundURL(for sound: SoundFile, in pack: SoundPack) -> URL? {
        // 1. Check bundle first (for built-in packs)
        if let bundleURL = Bundle.main.url(forResource: sound.fileName, withExtension: sound.fileExtension) {
            return bundleURL
        }

        // 2. Check Documents for custom packs
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let customURL = documentsURL
            .appendingPathComponent(Constants.soundPacksDir)
            .appendingPathComponent(pack.id)
            .appendingPathComponent("\(sound.fileName).\(sound.fileExtension)")

        if FileManager.default.fileExists(atPath: customURL.path) {
            return customURL
        }

        return nil
    }
}
