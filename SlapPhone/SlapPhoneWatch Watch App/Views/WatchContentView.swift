import SwiftUI
import SlapPhoneCore

// MARK: - Watch Theme

enum WatchTheme {
    static let bgTop = Color(red: 0.10, green: 0.02, blue: 0.20)
    static let bgBottom = Color(red: 0.04, green: 0.04, blue: 0.06)
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
}

// MARK: - Watch Content View

struct WatchContentView: View {
    @StateObject private var viewModel = WatchViewModel()
    @State private var ringScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(
                colors: [WatchTheme.bgTop, WatchTheme.bgBottom],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 4) {
                // Status dot
                HStack(spacing: 4) {
                    Circle()
                        .fill(viewModel.isDetecting ? Color.green : Color.red.opacity(0.6))
                        .frame(width: 6, height: 6)
                        .shadow(color: viewModel.isDetecting ? .green.opacity(0.5) : .clear, radius: 3)
                    Text(viewModel.isDetecting ? "Active" : "Paused")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                }

                // Intensity ring with counter
                ZStack {
                    // Track
                    Circle()
                        .stroke(Color.white.opacity(0.06), lineWidth: 8)
                        .frame(width: 110, height: 110)

                    // Intensity arc
                    Circle()
                        .trim(from: 0, to: CGFloat(viewModel.lastIntensity))
                        .stroke(
                            WatchTheme.ringGradient,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 110, height: 110)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: viewModel.lastIntensity)

                    // Glow
                    Circle()
                        .trim(from: 0, to: CGFloat(viewModel.lastIntensity))
                        .stroke(
                            WatchTheme.ringGradient,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 110, height: 110)
                        .rotationEffect(.degrees(-90))
                        .blur(radius: 6)
                        .opacity(0.4)

                    // Counter
                    VStack(spacing: 0) {
                        Text("\(viewModel.slapCount)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                            .contentTransition(.numericText())

                        Text("SLAPS")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white.opacity(0.35))
                            .tracking(2)
                    }
                }
                .scaleEffect(ringScale)

                // Intensity percentage
                if viewModel.lastIntensity > 0 {
                    Text("\(String(format: "%.0f%%", viewModel.lastIntensity * 100))")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(WatchTheme.accentStart)
                }
            }
        }
        .onAppear {
            viewModel.startDetection()
        }
        .onDisappear {
            viewModel.stopDetection()
        }
        .onReceive(viewModel.$lastIntensity) { intensity in
            guard intensity > 0 else { return }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                ringScale = 1.08
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    ringScale = 1.0
                }
            }
        }
    }
}
