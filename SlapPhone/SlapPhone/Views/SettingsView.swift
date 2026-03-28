import SwiftUI
import SlapPhoneCore

struct SettingsView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var audioService: AudioService
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [AppTheme.bgTop, AppTheme.bgBottom],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    settingsHeader
                        .padding(.bottom, 4)

                    // Detection section
                    detectionCard

                    // Sound Pack section
                    soundPackCard

                    // Sound selection grid
                    soundGrid

                    // Statistics section
                    statisticsCard

                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Header

    private var settingsHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Settings")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)
                Text("Customize your slap experience")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 32, height: 32)
                    .background(AppTheme.glass, in: Circle())
            }
        }
    }

    // MARK: - Detection Card

    private var detectionCard: some View {
        GlassCard {
            VStack(spacing: 16) {
                SectionHeader(icon: "sensor.tag.radiowaves.forward", title: "Detection")

                // Sensitivity
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Sensitivity")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.8))
                        Spacer()
                        Text(sensitivityLabel)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.accentStart)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(AppTheme.accentStart.opacity(0.15), in: Capsule())
                    }
                    GradientSlider(value: $settingsVM.sensitivity, range: 0.1...1.0)
                }

                Divider().overlay(Color.white.opacity(0.06))

                // Cooldown
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Cooldown")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.8))
                        Spacer()
                        Text(String(format: "%.1fs", settingsVM.cooldownSeconds))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.accentStart)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(AppTheme.accentStart.opacity(0.15), in: Capsule())
                    }
                    GradientSlider(value: $settingsVM.cooldownSeconds, range: Constants.minCooldown...Constants.maxCooldown, step: 0.1)
                }
            }
        }
    }

    // MARK: - Sound Pack Card

    private var soundPackCard: some View {
        GlassCard {
            VStack(spacing: 12) {
                SectionHeader(icon: "shippingbox.fill", title: "Sound Pack")

                ForEach(SoundPack.builtInPacks) { pack in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            settingsVM.selectedSoundPackId = pack.id
                            audioService.loadSoundPack(pack)
                            settingsVM.selectedSoundId = pack.sounds.first?.id ?? ""
                        }
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(pack.id == settingsVM.selectedSoundPackId ? AnyShapeStyle(AppTheme.accent) : AnyShapeStyle(Color.white.opacity(0.1)))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "music.note.list")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(pack.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                Text("\(pack.sounds.count) sounds")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.4))
                            }

                            Spacer()

                            if pack.id == settingsVM.selectedSoundPackId {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppTheme.accentStart)
                            }
                        }
                        .padding(10)
                        .background(
                            pack.id == settingsVM.selectedSoundPackId
                                ? AppTheme.accentStart.opacity(0.08)
                                : Color.clear,
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Sound Grid

    private var soundGrid: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(icon: "waveform", title: "Sound")

                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ], spacing: 8) {
                    ForEach(settingsVM.selectedSoundPack.sounds) { sound in
                        SoundPill(
                            name: sound.fileName,
                            isSelected: sound.id == settingsVM.selectedSoundId
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                settingsVM.selectedSoundId = sound.id
                            }
                            audioService.playSound(id: sound.id, intensity: 0.7)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Statistics Card

    private var statisticsCard: some View {
        GlassCard {
            VStack(spacing: 12) {
                SectionHeader(icon: "chart.bar.fill", title: "Statistics")

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Slaps")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                        Text("\(settingsVM.slapCount)")
                            .font(.title.weight(.bold))
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    Button {
                        settingsVM.resetSlapCount()
                    } label: {
                        Text("Reset")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.red.opacity(0.8))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Color.red.opacity(0.12), in: Capsule())
                    }
                }
            }
        }
    }

    var sensitivityLabel: String {
        switch settingsVM.sensitivity {
        case 0..<0.3: return "Low"
        case 0.3..<0.7: return "Medium"
        default: return "High"
        }
    }
}

// MARK: - Reusable Components

struct GlassCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .background(AppTheme.glass, in: RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(AppTheme.glassBorder, lineWidth: 0.5)
            )
    }
}

struct SectionHeader: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.accentStart)
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white.opacity(0.6))
                .textCase(.uppercase)
                .tracking(1)
            Spacer()
        }
    }
}

struct SoundPill: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.5))
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    isSelected
                        ? AnyShapeStyle(AppTheme.accent.opacity(0.3))
                        : AnyShapeStyle(Color.white.opacity(0.04))
                    , in: RoundedRectangle(cornerRadius: 10)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            isSelected ? AnyShapeStyle(AppTheme.accent) : AnyShapeStyle(Color.white.opacity(0.08)),
                            lineWidth: isSelected ? 1 : 0.5
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

struct GradientSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double? = nil

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track background
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 6)

                // Filled track
                Capsule()
                    .fill(AppTheme.accent)
                    .frame(width: max(0, geo.size.width * fillPercent), height: 6)

                // Thumb
                Circle()
                    .fill(.white)
                    .frame(width: 20, height: 20)
                    .shadow(color: AppTheme.accentStart.opacity(0.4), radius: 6)
                    .offset(x: max(0, min(geo.size.width - 20, (geo.size.width - 20) * fillPercent)))
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { drag in
                                let percent = Double(max(0, min(1, drag.location.x / geo.size.width)))
                                var newValue = range.lowerBound + percent * (range.upperBound - range.lowerBound)
                                if let step = step {
                                    newValue = (newValue / step).rounded() * step
                                }
                                value = min(range.upperBound, max(range.lowerBound, newValue))
                            }
                    )
            }
        }
        .frame(height: 20)
    }

    private var fillPercent: CGFloat {
        CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
    }
}
