import SwiftUI
import Combine

final class SlapDetectorViewModel: ObservableObject {
    let accelerometerService = AccelerometerService()
    private(set) lazy var slapDetectionService = SlapDetectionService(accelerometerService: accelerometerService)

    @Published var lastSlapIntensity: Float = 0
    @Published var isDetecting = false
    @Published var sensorAvailable = false

    private var cancellables = Set<AnyCancellable>()

    var slapPublisher: AnyPublisher<SlapEvent, Never> {
        slapDetectionService.slapPublisher
    }

    init() {
        sensorAvailable = AccelerometerService.isAvailable()
    }

    func startDetection(sensitivity: Double, cooldown: Double) {
        slapDetectionService.sensitivity = sensitivity
        slapDetectionService.cooldownSeconds = cooldown

        slapDetectionService.slapPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.lastSlapIntensity = event.intensity
            }
            .store(in: &cancellables)

        slapDetectionService.start()
        isDetecting = true
    }

    func stopDetection() {
        slapDetectionService.stop()
        cancellables.removeAll()
        isDetecting = false
    }

    func updateSettings(sensitivity: Double, cooldown: Double) {
        slapDetectionService.sensitivity = sensitivity
        slapDetectionService.cooldownSeconds = cooldown
    }
}
