import SwiftUI
import Combine
import SlapPhoneCore

@main
struct SlapPhoneApp: App {
    @StateObject private var settingsVM = SettingsViewModel()
    @StateObject private var slapDetectorVM = SlapDetectorViewModel()
    @StateObject private var audioService = AudioService()
    @StateObject private var flashService = FlashService()
    @StateObject private var connectivityManager = WatchConnectivityManager.shared

    private let hapticService = HapticService()

    var body: some Scene {
        WindowGroup {
            ZStack {
                MainView()
                    .environmentObject(settingsVM)
                    .environmentObject(slapDetectorVM)
                    .environmentObject(audioService)
                    .onAppear { setupApp() }

                FlashOverlayView(flashService: flashService)
            }
        }
    }

    private func setupApp() {
        // Load initial sound pack
        audioService.loadSoundPack(settingsVM.selectedSoundPack)

        // Start detection if sensor available
        if slapDetectorVM.sensorAvailable {
            slapDetectorVM.startDetection(
                sensitivity: settingsVM.sensitivity,
                cooldown: settingsVM.cooldownSeconds
            )
        }

        // Handle slap events
        slapDetectorVM.slapPublisher
            .receive(on: DispatchQueue.main)
            .sink { event in
                if settingsVM.soundEnabled {
                    audioService.playSound(id: settingsVM.selectedSoundId, intensity: event.intensity)
                }

                if settingsVM.hapticEnabled {
                    hapticService.impact(intensity: event.intensity)
                }

                if settingsVM.screenFlashEnabled {
                    flashService.flash(intensity: event.intensity)
                }

                settingsVM.incrementSlapCount()

                // Sync to watch
                connectivityManager.syncSettings(settingsVM)
            }
            .store(in: &slapDetectorVM.cancellables)

        // Listen for settings changes
        settingsVM.objectWillChange
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { _ in
                slapDetectorVM.updateSettings(
                    sensitivity: settingsVM.sensitivity,
                    cooldown: settingsVM.cooldownSeconds
                )
                // Sync settings to watch
                connectivityManager.syncSettings(settingsVM)
            }
            .store(in: &slapDetectorVM.cancellables)
    }
}
