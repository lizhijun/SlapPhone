import Foundation
import Combine

final class SlapDetectionService: ObservableObject {
    @Published var isActive = false

    private let accelerometerService: AccelerometerService
    private var cancellables = Set<AnyCancellable>()
    private var lastSlapTime: Date?
    private var startTime: Date?

    private let slapSubject = PassthroughSubject<SlapEvent, Never>()
    var slapPublisher: AnyPublisher<SlapEvent, Never> {
        slapSubject.eraseToAnyPublisher()
    }

    // Configurable from settings
    var sensitivity: Double = Constants.defaultSensitivity
    var cooldownSeconds: Double = Constants.defaultCooldown

    // Gravity estimation (low-pass filter)
    private var gravityX: Double = 0
    private var gravityY: Double = 0
    private var gravityZ: Double = -1.0

    // Warmup: skip detection for first N seconds to let gravity filter stabilize
    private let warmupSeconds: Double = 2.0

    init(accelerometerService: AccelerometerService) {
        self.accelerometerService = accelerometerService
    }

    func start() {
        do {
            try accelerometerService.start()
        } catch {
            print("Accelerometer start failed: \(error)")
            return
        }

        startTime = Date()

        accelerometerService.accelerationPublisher
            .sink { [weak self] data in
                self?.processAcceleration(data)
            }
            .store(in: &cancellables)

        isActive = true
    }

    func stop() {
        cancellables.removeAll()
        accelerometerService.stop()
        isActive = false
    }

    private func processAcceleration(_ data: AccelerometerService.AccelerationData) {
        let alpha = Constants.gravityFilterAlpha

        // Update gravity estimate with low-pass filter
        gravityX = alpha * gravityX + (1 - alpha) * data.x
        gravityY = alpha * gravityY + (1 - alpha) * data.y
        gravityZ = alpha * gravityZ + (1 - alpha) * data.z

        // Skip detection during warmup period
        if let start = startTime, Date().timeIntervalSince(start) < warmupSeconds {
            return
        }

        // Remove gravity to get dynamic acceleration
        let dx = data.x - gravityX
        let dy = data.y - gravityY
        let dz = data.z - gravityZ

        // Calculate magnitude of dynamic acceleration
        let magnitude = sqrt(dx * dx + dy * dy + dz * dz)

        // Adjust threshold based on sensitivity (higher sensitivity = lower threshold)
        let adjustedThreshold = Constants.baseThresholdG * (2.0 - sensitivity)

        guard magnitude > adjustedThreshold else { return }

        // Check cooldown
        if let lastSlap = lastSlapTime,
           Date().timeIntervalSince(lastSlap) < cooldownSeconds {
            return
        }

        // Normalize intensity to 0.0-1.0
        let intensity = Float(min(1.0, (magnitude - adjustedThreshold) / (Constants.maxExpectedG - adjustedThreshold)))

        let event = SlapEvent(
            timestamp: Date(),
            intensity: max(0.01, intensity),
            rawAcceleration: (data.x, data.y, data.z)
        )

        lastSlapTime = Date()
        slapSubject.send(event)
    }

    deinit {
        stop()
    }
}
