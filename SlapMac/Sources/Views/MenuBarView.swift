import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var slapDetectorVM: SlapDetectorViewModel
    @EnvironmentObject var soundPackManager: SoundPackManager
    var importWindowController: SoundPackImportWindowController?
    @State private var showSettings = false
    @State private var showSoundPacks = false
    @State private var showAbout = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "hand.tap.fill")
                    .font(.title2)
                    .foregroundStyle(.primary)
                Text(Constants.appName)
                    .font(.headline)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(settingsVM.slapCount)")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                    Text("slaps")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 4)

            Divider()

            // Status
            HStack {
                Circle()
                    .fill(slapDetectorVM.isDetecting ? .green : .red)
                    .frame(width: 8, height: 8)
                Text(slapDetectorVM.isDetecting ? "Detecting" : "Stopped")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if !slapDetectorVM.sensorAvailable {
                    Text("Sensor N/A")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            // Last slap intensity bar
            if slapDetectorVM.lastSlapIntensity > 0 {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Last slap")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(.quaternary)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(intensityColor(slapDetectorVM.lastSlapIntensity))
                                .frame(width: geo.size.width * CGFloat(slapDetectorVM.lastSlapIntensity))
                        }
                    }
                    .frame(height: 6)
                }
            }

            Divider()

            // Quick toggles
            Toggle("USB Moaner", isOn: $settingsVM.usbMoanerEnabled)
                .toggleStyle(.switch)
                .controlSize(.small)

            Toggle("Screen Flash", isOn: $settingsVM.screenFlashEnabled)
                .toggleStyle(.switch)
                .controlSize(.small)

            // Sensitivity
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Sensitivity")
                        .font(.caption)
                    Spacer()
                    Text(sensitivityLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Slider(value: $settingsVM.sensitivity, in: 0.1...1.0)
                    .controlSize(.small)
            }

            // Cooldown
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Cooldown")
                        .font(.caption)
                    Spacer()
                    Text(String(format: "%.1fs", settingsVM.cooldownSeconds))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Slider(value: $settingsVM.cooldownSeconds, in: Constants.minCooldown...Constants.maxCooldown, step: 0.1)
                    .controlSize(.small)
            }

            Divider()

            // Sound pack
            HStack {
                Text("Sound Pack")
                    .font(.caption)
                Spacer()
                Picker("", selection: $settingsVM.selectedSoundPackId) {
                    ForEach(soundPackManager.allPacks) { pack in
                        Text(pack.name).tag(pack.id)
                    }
                }
                .labelsHidden()
                .fixedSize()
            }

            // Sound selection
            HStack {
                Text("Sound")
                    .font(.caption)
                Spacer()
                Picker("", selection: $settingsVM.selectedSoundId) {
                    ForEach(currentPackSounds) { sound in
                        Text(sound.fileName).tag(sound.id)
                    }
                }
                .labelsHidden()
                .fixedSize()
            }

            HStack(spacing: 8) {
                Button("Import Pack...") {
                    importWindowController?.showWindow()
                }

                if !soundPackManager.customPacks.isEmpty {
                    let selectedIsCustom = soundPackManager.customPacks.contains(where: { $0.id == settingsVM.selectedSoundPackId })
                    if selectedIsCustom {
                        Button("Delete Pack") {
                            try? soundPackManager.deletePack(id: settingsVM.selectedSoundPackId)
                            settingsVM.selectedSoundPackId = SoundPack.slapMacPack.id
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
            .font(.caption)
            .buttonStyle(.plain)

            Divider()

            // Bottom buttons
            HStack {
                Button("About") {
                    showAbout = true
                }
                .popover(isPresented: $showAbout) {
                    AboutView()
                }

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .buttonStyle(.plain)
            .font(.caption)
        }
        .padding(12)
        .frame(width: 260)
    }

    private var currentPackSounds: [SoundFile] {
        let pack = soundPackManager.allPacks.first { $0.id == settingsVM.selectedSoundPackId }
        return pack?.sounds ?? []
    }

    private var sensitivityLabel: String {
        switch settingsVM.sensitivity {
        case 0..<0.3: return "Low"
        case 0.3..<0.7: return "Medium"
        default: return "High"
        }
    }

    private func intensityColor(_ intensity: Float) -> Color {
        if intensity < 0.3 { return .green }
        if intensity < 0.7 { return .orange }
        return .red
    }
}
