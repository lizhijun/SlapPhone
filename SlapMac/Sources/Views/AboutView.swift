import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 40))
                .foregroundStyle(.blue)

            Text(Constants.appName)
                .font(.title2.bold())

            Text("Slap your MacBook. It screams back.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Divider()

            VStack(spacing: 4) {
                Text("Version 1.0.0")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("macOS 14.6+ | Apple Silicon")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(20)
        .frame(width: 220)
    }
}
