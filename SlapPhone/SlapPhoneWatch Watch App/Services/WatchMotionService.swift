import CoreMotion
import Combine
import SlapPhoneCore

final class WatchMotionService: NSObject, ObservableObject, AccelerationProvider {
    @Published var isRunning = false

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
        motionManager.accelerometerUpdateInterval = 0.02 // 50Hz on watch for battery

        motionManager.startAccelerometerUpdates(to: operationQueue) { [weak self] data, _ in
            guard let data = data else { return }
            let accelData = AccelerationData(
                x: data.acceleration.x,
                y: data.acceleration.y,
                z: data.acceleration.z,
                timestamp: UInt64(data.timestamp * 1_000_000_000)
            )
            self?.accelerationSubject.send(accelData)
        }

        DispatchQueue.main.async { self.isRunning = true }
    }

    func stop() {
        motionManager.stopAccelerometerUpdates()
        DispatchQueue.main.async { self.isRunning = false }
    }

    enum MotionError: Error {
        case notAvailable
    }
}
