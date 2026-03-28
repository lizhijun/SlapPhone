import WatchKit

final class WatchHapticService {
    func play(intensity: Float) {
        let type: WKHapticType
        switch intensity {
        case 0..<0.3: type = .click
        case 0.3..<0.6: type = .directionUp
        case 0.6..<0.8: type = .notification
        default: type = .success
        }

        WKInterfaceDevice.current().play(type)
    }
}
