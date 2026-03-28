import SwiftUI
import Combine
import ServiceManagement

final class SettingsViewModel: ObservableObject {
    @AppStorage("sensitivity") var sensitivity: Double = Constants.defaultSensitivity
    @AppStorage("cooldownSeconds") var cooldownSeconds: Double = Constants.defaultCooldown
    @AppStorage("launchAtLogin") private var _launchAtLogin: Bool = false
    @AppStorage("usbMoanerEnabled") var usbMoanerEnabled: Bool = false
    @AppStorage("screenFlashEnabled") var screenFlashEnabled: Bool = true
    @AppStorage("slapCount") var slapCount: Int = 0
    @AppStorage("selectedSoundPackId") var selectedSoundPackId: String = SoundPack.slapMacPack.id
    @AppStorage("selectedSoundId") var selectedSoundId: String = SoundPack.slapMacPack.sounds.first?.id ?? ""

    var launchAtLogin: Bool {
        get { _launchAtLogin }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                _launchAtLogin = newValue
            } catch {
                print("Failed to set launch at login: \(error)")
            }
        }
    }

    var selectedSoundPack: SoundPack {
        SoundPack.allPacks.first { $0.id == selectedSoundPackId } ?? .systemPack
    }

    func incrementSlapCount() {
        slapCount += 1
    }
}
