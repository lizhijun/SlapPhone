import CoreMotion
import Combine
import SlapPhoneCore

final class MotionService: NSObject, ObservableObject, AccelerationProvider {
    @Published var isRunning = false
    @Published var errorMessage: String?

    private let motionManager = CMMotionManager()
    private let operationQueue = OperationQueue()
    private let accelerationSubject = PassthroughSubject<AccelerationData, Never>()

    var accelerationPublisher: AnyPublisher<AccelerationData, Never> {
        accelerationSubject.eraseToAnyPublisher()
    }

    static var isAvailable: Bool {
        CMMotionManager().isAccelerometerAvailable
    }

    func start() throws {
        guard motionManager.isAccelerometerAvailable else {
            throw MotionError.notAvailable
        }

        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.qualityOfService = .userInteractive

        // 100Hz sampling rate
        motionManager.accelerometerUpdateInterval = 0.01

        motionManager.startAccelerometerUpdates(to: operationQueue) { [weak self] data, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = error.localizedDescription
                }
                return
            }

            guard let data = data else { return }

            let accelData = AccelerationData(
                x: data.acceleration.x,
                y: data.acceleration.y,
                z: data.acceleration.z,
                timestamp: UInt64(data.timestamp * 1_000_000_000)
            )
            self?.accelerationSubject.send(accelData)
        }

        DispatchQueue.main.async {
            self.isRunning = true
            self.errorMessage = nil
        }
    }

    func stop() {
        motionManager.stopAccelerometerUpdates()
        DispatchQueue.main.async {
            self.isRunning = false
        }
    }

    enum MotionError: LocalizedError {
        case notAvailable
        case permissionDenied

        var errorDescription: String? {
            switch self {
            case .notAvailable: return "Motion sensors not available on this device"
            case .permissionDenied: return "Motion permission denied"
            }
        }
    }
}
