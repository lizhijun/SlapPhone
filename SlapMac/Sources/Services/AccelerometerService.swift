import Foundation
import IOKit
import IOKit.hid
import Combine

final class AccelerometerService: ObservableObject {
    struct AccelerationData {
        let x: Double  // in g units
        let y: Double
        let z: Double
        let timestamp: UInt64
    }

    enum AccelerometerError: LocalizedError {
        case managerOpenFailed
        case deviceNotFound
        case deviceOpenFailed
        case notAvailable

        var errorDescription: String? {
            switch self {
            case .managerOpenFailed: return "Failed to open HID manager"
            case .deviceNotFound: return "Accelerometer sensor not found (requires Apple Silicon)"
            case .deviceOpenFailed: return "Failed to open accelerometer device"
            case .notAvailable: return "Accelerometer is not available on this Mac"
            }
        }
    }

    @Published var isRunning = false
    @Published var lastError: String?

    private var manager: IOHIDManager?
    private var accelerometerDevice: IOHIDDevice?
    private var reportBuffer: UnsafeMutablePointer<UInt8>?
    private let accelerationSubject = PassthroughSubject<AccelerationData, Never>()

    var accelerationPublisher: AnyPublisher<AccelerationData, Never> {
        accelerationSubject.eraseToAnyPublisher()
    }

    static func isAvailable() -> Bool {
        let matching = IOServiceMatching("AppleSPUHIDDevice") as NSDictionary as CFDictionary
        var iterator: io_iterator_t = 0
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)
        defer { IOObjectRelease(iterator) }
        if result != KERN_SUCCESS { return false }
        let service = IOIteratorNext(iterator)
        defer { if service != 0 { IOObjectRelease(service) } }
        return service != 0
    }

    func start() throws {
        guard AccelerometerService.isAvailable() else {
            throw AccelerometerError.notAvailable
        }

        // Create HID Manager
        let mgr = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        manager = mgr

        // Match Usage Page 0xFF00, Usage 3 (accelerometer)
        let matchDict: [String: Any] = [
            kIOHIDDeviceUsagePageKey as String: 0xFF00,
            kIOHIDDeviceUsageKey as String: 3
        ]
        IOHIDManagerSetDeviceMatching(mgr, matchDict as CFDictionary)

        // Open manager
        let openResult = IOHIDManagerOpen(mgr, IOOptionBits(kIOHIDOptionsTypeNone))
        guard openResult == kIOReturnSuccess else {
            throw AccelerometerError.managerOpenFailed
        }

        // Find the SPU transport device (the real accelerometer, not keyboard/trackpad)
        guard let deviceSet = IOHIDManagerCopyDevices(mgr) as? Set<IOHIDDevice> else {
            throw AccelerometerError.deviceNotFound
        }

        let spuDevice = deviceSet.first { device in
            let transport = IOHIDDeviceGetProperty(device, kIOHIDTransportKey as CFString) as? String
            return transport == "SPU"
        }

        // Fallback: if no SPU transport found, try any device
        guard let device = spuDevice ?? deviceSet.first else {
            throw AccelerometerError.deviceNotFound
        }

        accelerometerDevice = device

        // Open the device explicitly
        let devOpenResult = IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeNone))
        guard devOpenResult == kIOReturnSuccess else {
            throw AccelerometerError.deviceOpenFailed
        }

        // Set report interval to get continuous data
        // Apple SPU accelerometer uses property kIOHIDReportIntervalKey
        // 10000 microseconds = 10ms = 100Hz
        let interval = 10000
        IOHIDDeviceSetProperty(device, kIOHIDReportIntervalKey as CFString, interval as CFNumber)

        // Allocate report buffer and register callback
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 256)
        buffer.initialize(repeating: 0, count: 256)
        reportBuffer = buffer

        let context = Unmanaged.passUnretained(self).toOpaque()

        IOHIDDeviceRegisterInputReportCallback(
            device,
            buffer,
            256,
            accelerometerReportCallback,
            context
        )

        // Schedule device with run loop
        IOHIDDeviceScheduleWithRunLoop(device, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)

        isRunning = true
        lastError = nil
    }

    func stop() {
        if let device = accelerometerDevice {
            IOHIDDeviceUnscheduleFromRunLoop(device, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
            IOHIDDeviceClose(device, IOOptionBits(kIOHIDOptionsTypeNone))
        }
        if let mgr = manager {
            IOHIDManagerClose(mgr, IOOptionBits(kIOHIDOptionsTypeNone))
        }
        manager = nil
        accelerometerDevice = nil
        reportBuffer?.deallocate()
        reportBuffer = nil
        isRunning = false
    }

    fileprivate func handleReport(_ report: UnsafePointer<UInt8>, length: Int) {
        guard let data = parseReport(report, length: length) else { return }
        accelerationSubject.send(data)
    }

    private func parseReport(_ report: UnsafePointer<UInt8>, length: Int) -> AccelerationData? {
        // SPU HID report: at least 18 bytes
        // int32 LE: X at offset 6, Y at offset 10, Z at offset 14
        // Divide by 65536 to convert to g units
        guard length >= 18 else { return nil }

        let x = readInt32LE(report, offset: 6)
        let y = readInt32LE(report, offset: 10)
        let z = readInt32LE(report, offset: 14)

        return AccelerationData(
            x: Double(x) / 65536.0,
            y: Double(y) / 65536.0,
            z: Double(z) / 65536.0,
            timestamp: mach_absolute_time()
        )
    }

    private func readInt32LE(_ buffer: UnsafePointer<UInt8>, offset: Int) -> Int32 {
        let b0 = Int32(buffer[offset])
        let b1 = Int32(buffer[offset + 1]) << 8
        let b2 = Int32(buffer[offset + 2]) << 16
        let b3 = Int32(buffer[offset + 3]) << 24
        return b0 | b1 | b2 | b3
    }

    deinit {
        stop()
    }
}

// C-compatible callback function
private func accelerometerReportCallback(
    context: UnsafeMutableRawPointer?,
    result: IOReturn,
    sender: UnsafeMutableRawPointer?,
    type: IOHIDReportType,
    reportID: UInt32,
    report: UnsafeMutablePointer<UInt8>,
    reportLength: CFIndex
) {
    guard let context = context else { return }
    let service = Unmanaged<AccelerometerService>.fromOpaque(context).takeUnretainedValue()
    service.handleReport(report, length: reportLength)
}
