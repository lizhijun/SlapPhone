import SwiftUI
import SlapPhoneCore

// MARK: - Theme

enum AppTheme {
    static let bgTop = Color(red: 0.10, green: 0.02, blue: 0.20)
    static let bgBottom = Color(red: 0.04, green: 0.04, blue: 0.06)
    static let accent = LinearGradient(
        colors: [Color(red: 1.0, green: 0.45, blue: 0.2), Color(red: 1.0, green: 0.25, blue: 0.5)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let accentStart = Color(red: 1.0, green: 0.45, blue: 0.2)
    static let accentEnd = Color(red: 1.0, green: 0.25, blue: 0.5)
    static let ringGradient = AngularGradient(
        gradient: Gradient(colors: [
            Color(red: 1.0, green: 0.45, blue: 0.2),
            Color(red: 1.0, green: 0.25, blue: 0.5),
            Color(red: 0.7, green: 0.2, blue: 0.9),
            Color(red: 1.0, green: 0.45, blue: 0.2)
        ]),
        center: .center
    )
    static let glass = Color.white.opacity(0.08)
    static let glassBorder = Color.white.opacity(0.15)
}

// MARK: - Main View

struct MainView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var slapDetectorVM: SlapDetectorViewModel
    @State private var showSettings = false
    @State private var ringScale: CGFloat = 1.0
    @State private var counterBounce: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(
                colors: [AppTheme.bgTop, AppTheme.bgBottom],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Custom header
                headerView
                    .padding(.top, 8)
                    .padding(.horizontal, 20)

                Spacer()

                // Intensity ring with counter
                intensityRingView
                    .scaleEffect(ringScale)
                    .padding(.bottom, 12)

                // Status row
                statusRow
                    .padding(.bottom, 28)

                // Toggle buttons
                toggleRow
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)

                // Current sound card
                soundCard
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onReceive(slapDetectorVM.$lastSlapIntensity) { intensity in
            guard intensity > 0 else { return }
            // Pulse ring
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                ringScale = 1.06
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    ringScale = 1.0
                }
            }
            // Bounce counter
            withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) {
                counterBounce = 1.12
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    counterBounce = 1.0
                }
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "hand.tap.fill")
                    .font(.title3)
                    .foregroundStyle(AppTheme.accent)
                Text("SlapPhone")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
            }

            Spacer()

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 40, height: 40)
                    .background(AppTheme.glass, in: Circle())
            }
        }
    }

    // MARK: - Intensity Ring

    private var intensityRingView: some View {
        ZStack {
            // Track ring
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 14)
                .frame(width: 220, height: 220)

            // Intensity ring
            Circle()
                .trim(from: 0, to: CGFloat(slapDetectorVM.lastSlapIntensity))
                .stroke(
                    AppTheme.ringGradient,
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .frame(width: 220, height: 220)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: slapDetectorVM.lastSlapIntensity)

            // Glow effect behind ring
            Circle()
                .trim(from: 0, to: CGFloat(slapDetectorVM.lastSlapIntensity))
                .stroke(
                    AppTheme.ringGradient,
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .frame(width: 220, height: 220)
                .rotationEffect(.degrees(-90))
                .blur(radius: 12)
                .opacity(0.5)

            // Counter inside ring
            VStack(spacing: 2) {
                Text("\(settingsVM.slapCount)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .scaleEffect(counterBounce)

                Text("slaps")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .textCase(.uppercase)
                    .tracking(2)
            }
        }
    }

    // MARK: - Status Row

    private var statusRow: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                Circle()
                    .fill(slapDetectorVM.isDetecting ? Color.green : Color.red.opacity(0.7))
                    .frame(width: 8, height: 8)
                    .shadow(color: slapDetectorVM.isDetecting ? .green.opacity(0.6) : .clear, radius: 4)
                Text(slapDetectorVM.isDetecting ? "Detecting" : "Stopped")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.5))
            }

            if slapDetectorVM.lastSlapIntensity > 0 {
                Text("Intensity: \(String(format: "%.0f%%", slapDetectorVM.lastSlapIntensity * 100))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.accentStart)
            }
        }
    }

    // MARK: - Toggle Row

    private var toggleRow: some View {
        HStack(spacing: 14) {
            GlassToggle(icon: "speaker.wave.2.fill", label: "Sound", isOn: $settingsVM.soundEnabled)
            GlassToggle(icon: "waveform", label: "Haptic", isOn: $settingsVM.hapticEnabled)
            GlassToggle(icon: "bolt.fill", label: "Flash", isOn: $settingsVM.screenFlashEnabled)
        }
    }

    // MARK: - Sound Card

    private var soundCard: some View {
        Button {
            showSettings = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppTheme.accent)
                        .frame(width: 36, height: 36)
                    Image(systemName: "music.note")
                        .font(.body.weight(.bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(currentSoundName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(settingsVM.selectedSoundPack.name)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(14)
            .background(AppTheme.glass, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.glassBorder, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    private var currentSoundName: String {
        settingsVM.selectedSoundPack.sounds.first { $0.id == settingsVM.selectedSoundId }?.fileName ?? "Select Sound"
    }
}

// MARK: - Glass Toggle Button

struct GlassToggle: View {
    let icon: String
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isOn.toggle()
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isOn ? .white : .white.opacity(0.3))
                    .frame(height: 24)

                Text(label)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(isOn ? .white.opacity(0.8) : .white.opacity(0.3))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    if isOn {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(AppTheme.accent.opacity(0.2))
                    }
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AppTheme.glass)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isOn ? AnyShapeStyle(AppTheme.accent) : AnyShapeStyle(AppTheme.glassBorder),
                        lineWidth: isOn ? 1 : 0.5
                    )
            )
            .shadow(color: isOn ? AppTheme.accentStart.opacity(0.3) : .clear, radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }
}
