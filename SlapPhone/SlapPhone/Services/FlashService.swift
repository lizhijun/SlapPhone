import SwiftUI
import SlapPhoneCore

final class FlashService: ObservableObject {
    @Published var flashIntensity: Float = 0
    @Published var isFlashing = false

    func flash(intensity: Float) {
        flashIntensity = intensity
        isFlashing = true

        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.flashDuration) { [weak self] in
            withAnimation(.easeOut(duration: Constants.flashDuration)) {
                self?.isFlashing = false
            }
        }
    }
}

struct FlashOverlayView: View {
    @ObservedObject var flashService: FlashService

    var body: some View {
        if flashService.isFlashing {
            Color.white
                .opacity(Double(flashService.flashIntensity) * Constants.flashMaxAlpha)
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .transition(.opacity)
        }
    }
}
