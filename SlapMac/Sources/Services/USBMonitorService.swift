import Foundation
import IOKit
import IOKit.usb
import Combine

final class USBMonitorService: ObservableObject {
    enum USBEvent {
        case connected(deviceName: String)
        case disconnected(deviceName: String)
    }

    @Published var isRunning = false

    private var notificationPort: IONotificationPortRef?
    private var addedIterator: io_iterator_t = 0
    private var removedIterator: io_iterator_t = 0
    private var isInitialScan = true

    private let eventSubject = PassthroughSubject<USBEvent, Never>()
    var eventPublisher: AnyPublisher<USBEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    func start() {
        guard !isRunning else { return }

        notificationPort = IONotificationPortCreate(kIOMainPortDefault)
        guard let port = notificationPort else { return }

        let runLoopSource = IONotificationPortGetRunLoopSource(port).takeUnretainedValue()
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        // Register for device added
        var matchingDict = IOServiceMatching(kIOUSBDeviceClassName)
        IOServiceAddMatchingNotification(
            port,
            kIOMatchedNotification,
            matchingDict,
            usbDeviceAdded,
            selfPtr,
            &addedIterator
        )

        // Drain existing devices (arm the iterator) - skip emitting events
        isInitialScan = true
        drainIterator(addedIterator)
        isInitialScan = false

        // Register for device removed
        matchingDict = IOServiceMatching(kIOUSBDeviceClassName)
        IOServiceAddMatchingNotification(
            port,
            kIOTerminatedNotification,
            matchingDict,
            usbDeviceRemoved,
            selfPtr,
            &removedIterator
        )

        isInitialScan = true
        drainIterator(removedIterator)
        isInitialScan = false

        isRunning = true
    }

    func stop() {
        if let port = notificationPort {
            let source = IONotificationPortGetRunLoopSource(port).takeUnretainedValue()
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .defaultMode)
            IONotificationPortDestroy(port)
        }
        if addedIterator != 0 { IOObjectRelease(addedIterator); addedIterator = 0 }
        if removedIterator != 0 { IOObjectRelease(removedIterator); removedIterator = 0 }
        notificationPort = nil
        isRunning = false
    }

    fileprivate func handleDeviceAdded(_ iterator: io_iterator_t) {
        processIterator(iterator, isAdded: true)
    }

    fileprivate func handleDeviceRemoved(_ iterator: io_iterator_t) {
        processIterator(iterator, isAdded: false)
    }

    private func processIterator(_ iterator: io_iterator_t, isAdded: Bool) {
        while case let device = IOIteratorNext(iterator), device != 0 {
            defer { IOObjectRelease(device) }

            guard !isInitialScan else { continue }

            var name = [CChar](repeating: 0, count: 256)
            IORegistryEntryGetName(device, &name)
            let deviceName = String(cString: name)

            let event: USBEvent = isAdded
                ? .connected(deviceName: deviceName)
                : .disconnected(deviceName: deviceName)
            eventSubject.send(event)
        }
    }

    private func drainIterator(_ iterator: io_iterator_t) {
        while case let device = IOIteratorNext(iterator), device != 0 {
            IOObjectRelease(device)
        }
    }

    deinit {
        stop()
    }
}

// C callback functions
private func usbDeviceAdded(refcon: UnsafeMutableRawPointer?, iterator: io_iterator_t) {
    guard let refcon = refcon else { return }
    let service = Unmanaged<USBMonitorService>.fromOpaque(refcon).takeUnretainedValue()
    service.handleDeviceAdded(iterator)
}

private func usbDeviceRemoved(refcon: UnsafeMutableRawPointer?, iterator: io_iterator_t) {
    guard let refcon = refcon else { return }
    let service = Unmanaged<USBMonitorService>.fromOpaque(refcon).takeUnretainedValue()
    service.handleDeviceRemoved(iterator)
}
