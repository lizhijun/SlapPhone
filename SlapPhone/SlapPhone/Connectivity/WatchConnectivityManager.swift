import WatchConnectivity
import Combine
import SlapPhoneCore

final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    @Published var isReachable = false
    @Published var watchSlapCount: Int = 0

    private var session: WCSession?

    override init() {
        super.init()

        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    /// Send current settings to the watch
    func syncSettings(_ settings: SettingsViewModel) {
        guard let session = session, session.activationState == .activated else { return }

        let context: [String: Any] = [
            "sensitivity": settings.sensitivity,
            "cooldownSeconds": settings.cooldownSeconds,
            "selectedSoundPackId": settings.selectedSoundPackId,
            "selectedSoundId": settings.selectedSoundId,
            "slapCount": settings.slapCount
        ]

        do {
            try session.updateApplicationContext(context)
        } catch {
            print("Failed to sync settings to watch: \(error)")
        }
    }

    /// Transfer a sound pack file to the watch
    func transferSoundPack(_ pack: SoundPack, urls: [URL]) {
        guard let session = session, session.activationState == .activated else { return }

        for url in urls {
            let metadata: [String: Any] = [
                "packId": pack.id,
                "packName": pack.name
            ]
            session.transferFile(url, metadata: metadata)
        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        if let watchCount = applicationContext["watchSlapCount"] as? Int {
            DispatchQueue.main.async {
                self.watchSlapCount = watchCount
            }
        }
    }
}
