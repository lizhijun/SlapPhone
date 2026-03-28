import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var soundPackManager: SoundPackManager

    var body: some View {
        Form {
            Section("Detection") {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Sensitivity")
                        Spacer()
                        Text(String(format: "%.0f%%", settingsVM.sensitivity * 100))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $settingsVM.sensitivity, in: 0.1...1.0)
                }

                VStack(alignment: .leading) {
                    HStack {
                        Text("Cooldown")
                        Spacer()
                        Text(String(format: "%.1f seconds", settingsVM.cooldownSeconds))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $settingsVM.cooldownSeconds, in: Constants.minCooldown...Constants.maxCooldown, step: 0.1)
                }
            }

            Section("Sound") {
                Picker("Sound Pack", selection: $settingsVM.selectedSoundPackId) {
                    ForEach(soundPackManager.allPacks) { pack in
                        VStack(alignment: .leading) {
                            Text(pack.name)
                            Text(pack.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(pack.id)
                    }
                }
            }

            Section("Features") {
                Toggle("USB Moaner", isOn: $settingsVM.usbMoanerEnabled)
                Toggle("Screen Flash", isOn: $settingsVM.screenFlashEnabled)
                Toggle("Launch at Login", isOn: Binding(
                    get: { settingsVM.launchAtLogin },
                    set: { settingsVM.launchAtLogin = $0 }
                ))
            }

            Section("Statistics") {
                LabeledContent("Total Slaps", value: "\(settingsVM.slapCount)")
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 420)
    }
}
