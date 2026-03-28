import SwiftUI
import SlapPhoneCore

final class SettingsViewModel: ObservableObject {
    @AppStorage("sensitivity") var sensitivity: Double = Constants.defaultSensitivity
    @AppStorage("cooldownSeconds") var cooldownSeconds: Double = Constants.defaultCooldown
    @AppStorage("selectedSoundPackId") var selectedSoundPackId: String = SoundPack.slapPhonePack.id
    @AppStorage("selectedSoundId") var selectedSoundId: String = SoundPack.slapPhonePack.sounds.first?.id ?? ""
    @AppStorage("slapCount") var slapCount: Int = 0
    @AppStorage("hapticEnabled") var hapticEnabled: Bool = true
    @AppStorage("screenFlashEnabled") var screenFlashEnabled: Bool = true
    @AppStorage("soundEnabled") var soundEnabled: Bool = true

    var selectedSoundPack: SoundPack {
        SoundPack.builtInPacks.first { $0.id == selectedSoundPackId } ?? .slapPhonePack
    }

    func incrementSlapCount() {
        slapCount += 1
    }

    func resetSlapCount() {
        slapCount = 0
    }
}
