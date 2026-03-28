import Foundation
import Combine

public protocol AccelerationProvider {
    var accelerationPublisher: AnyPublisher<AccelerationData, Never> { get }
}

public struct AccelerationData: Sendable {
    public let x: Double
    public let y: Double
    public let z: Double
    public let timestamp: UInt64

    public init(x: Double, y: Double, z: Double, timestamp: UInt64) {
        self.x = x
        self.y = y
        self.z = z
        self.timestamp = timestamp
    }
}

public final class SlapDetectionService: ObservableObject {
    @Published public var isActive = false

    public var sensitivity: Double = Constants.defaultSensitivity
    public var cooldownSeconds: Double = Constants.defaultCooldown

    private var cancellables = Set<AnyCancellable>()
    private var lastSlapTime: Date?
    private var startTime: Date?

    private let slapSubject = PassthroughSubject<SlapEvent, Never>()
    public var slapPublisher: AnyPublisher<SlapEvent, Never> {
        slapSubject.eraseToAnyPublisher()
    }

    // Gravity estimation (low-pass filter)
    private var gravityX: Double = 0
    private var gravityY: Double = 0
    private var gravityZ: Double = -1.0

    public init() {}

    public func start(with provider: any AccelerationProvider) {
        startTime = Date()

        provider.accelerationPublisher
            .sink { [weak self] data in
                self?.processAcceleration(data)
            }
            .store(in: &cancellables)

        isActive = true
    }

    public func stop() {
        cancellables.removeAll()
        isActive = false
    }

    private func processAcceleration(_ data: AccelerationData) {
        let alpha = Constants.gravityFilterAlpha

        // Low-pass gravity filter
        gravityX = alpha * gravityX + (1 - alpha) * data.x
        gravityY = alpha * gravityY + (1 - alpha) * data.y
        gravityZ = alpha * gravityZ + (1 - alpha) * data.z

        // Warmup period
        if let start = startTime, Date().timeIntervalSince(start) < Constants.warmupSeconds {
            return
        }

        // Dynamic acceleration (gravity removed)
        let dx = data.x - gravityX
        let dy = data.y - gravityY
        let dz = data.z - gravityZ
        let magnitude = sqrt(dx * dx + dy * dy + dz * dz)

        // Threshold check
        let adjustedThreshold = Constants.baseThresholdG * (2.0 - sensitivity)
        guard magnitude > adjustedThreshold else { return }

        // Cooldown check
        if let lastSlap = lastSlapTime, Date().timeIntervalSince(lastSlap) < cooldownSeconds {
            return
        }

        // Normalize intensity
        let intensity = Float(min(1.0, (magnitude - adjustedThreshold) / (Constants.maxExpectedG - adjustedThreshold)))

        let event = SlapEvent(
            timestamp: Date(),
            intensity: max(0.01, intensity),
            rawAcceleration: (data.x, data.y, data.z)
        )

        lastSlapTime = Date()
        slapSubject.send(event)
    }
}
