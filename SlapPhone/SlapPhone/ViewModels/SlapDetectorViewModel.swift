import SwiftUI
import Combine
import SlapPhoneCore

final class SlapDetectorViewModel: ObservableObject {
    @Published var lastSlapIntensity: Float = 0
    @Published var isDetecting = false
    @Published var sensorAvailable = false
    @Published var errorMessage: String?

    let motionService = MotionService()
    let slapDetectionService = SlapDetectionService()

    var cancellables = Set<AnyCancellable>()

    var slapPublisher: AnyPublisher<SlapEvent, Never> {
        slapDetectionService.slapPublisher
    }

    init() {
        sensorAvailable = MotionService.isAvailable
    }

    func startDetection(sensitivity: Double, cooldown: Double) {
        slapDetectionService.sensitivity = sensitivity
        slapDetectionService.cooldownSeconds = cooldown

        do {
            try motionService.start()
            slapDetectionService.start(with: motionService)

            slapDetectionService.slapPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] event in
                    self?.lastSlapIntensity = event.intensity
                }
                .store(in: &cancellables)

            isDetecting = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func stopDetection() {
        slapDetectionService.stop()
        motionService.stop()
        cancellables.removeAll()
        isDetecting = false
    }

    func updateSettings(sensitivity: Double, cooldown: Double) {
        slapDetectionService.sensitivity = sensitivity
        slapDetectionService.cooldownSeconds = cooldown
    }
}
