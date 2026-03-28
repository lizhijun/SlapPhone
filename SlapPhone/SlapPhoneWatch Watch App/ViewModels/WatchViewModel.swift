import SwiftUI
import Combine
import SlapPhoneCore

@MainActor
final class WatchViewModel: ObservableObject {
    @Published var slapCount: Int = 0
    @Published var lastIntensity: Float = 0
    @Published var isDetecting = false

    @AppStorage("sensitivity") var sensitivity: Double = Constants.defaultSensitivity
    @AppStorage("cooldownSeconds") var cooldownSeconds: Double = Constants.defaultCooldown

    let motionService = WatchMotionService()
    let slapDetectionService = SlapDetectionService()
    let hapticService = WatchHapticService()
    let sessionManager = WatchSessionManager.shared

    private var cancellables = Set<AnyCancellable>()

    func startDetection() {
        slapDetectionService.sensitivity = sensitivity
        slapDetectionService.cooldownSeconds = cooldownSeconds

        do {
            try motionService.start()
            slapDetectionService.start(with: motionService)

            slapDetectionService.slapPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] event in
                    self?.handleSlap(event)
                }
                .store(in: &cancellables)

            isDetecting = true
        } catch {
            print("Watch motion error: \(error)")
        }
    }

    func stopDetection() {
        slapDetectionService.stop()
        motionService.stop()
        cancellables.removeAll()
        isDetecting = false
    }

    private func handleSlap(_ event: SlapEvent) {
        lastIntensity = event.intensity
        slapCount += 1
        hapticService.play(intensity: event.intensity)
        sessionManager.sendSlapCount(slapCount)
    }

    func applyRemoteSettings() {
        // Apply settings synced from iPhone
        sensitivity = sessionManager.sensitivity
        cooldownSeconds = sessionManager.cooldownSeconds
        slapDetectionService.sensitivity = sensitivity
        slapDetectionService.cooldownSeconds = cooldownSeconds
    }
}
