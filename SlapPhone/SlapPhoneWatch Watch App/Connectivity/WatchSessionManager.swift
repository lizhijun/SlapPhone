import WatchConnectivity
import SlapPhoneCore

final class WatchSessionManager: NSObject, ObservableObject {
    static let shared = WatchSessionManager()

    @Published var sensitivity: Double = Constants.defaultSensitivity
    @Published var cooldownSeconds: Double = Constants.defaultCooldown
    @Published var phoneSlapCount: Int = 0

    private var session: WCSession?

    override init() {
        super.init()

        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    func sendSlapCount(_ count: Int) {
        guard let session = session, session.activationState == .activated else { return }

        try? session.updateApplicationContext(["watchSlapCount": count])
    }
}

extension WatchSessionManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async {
            if let sensitivity = applicationContext["sensitivity"] as? Double {
                self.sensitivity = sensitivity
            }
            if let cooldown = applicationContext["cooldownSeconds"] as? Double {
                self.cooldownSeconds = cooldown
            }
            if let count = applicationContext["slapCount"] as? Int {
                self.phoneSlapCount = count
            }
        }
    }

    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        let destURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent(Constants.soundPacksDir)

        if let packId = file.metadata?["packId"] as? String {
            let packDir = destURL.appendingPathComponent(packId)
            try? FileManager.default.createDirectory(at: packDir, withIntermediateDirectories: true)

            let fileName = file.fileURL.lastPathComponent
            let destFile = packDir.appendingPathComponent(fileName)
            try? FileManager.default.removeItem(at: destFile)
            try? FileManager.default.copyItem(at: file.fileURL, to: destFile)
        }
    }
}
