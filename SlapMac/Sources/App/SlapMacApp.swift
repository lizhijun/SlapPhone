import SwiftUI
import Combine

/// AppDelegate handles all background services that must run at app launch,
/// independent of UI visibility.
final class AppDelegate: NSObject, NSApplicationDelegate {
    let settingsVM = SettingsViewModel()
    let slapDetectorVM = SlapDetectorViewModel()
    let audioService = AudioService()
    let usbMonitor = USBMonitorService()

    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Load sound pack
        audioService.loadSoundPack(settingsVM.selectedSoundPack)

        // Start slap detection
        if slapDetectorVM.sensorAvailable {
            slapDetectorVM.startDetection(
                sensitivity: settingsVM.sensitivity,
                cooldown: settingsVM.cooldownSeconds
            )
        }

        // Slap events -> play audio + increment counter
        slapDetectorVM.slapPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self else { return }
                self.audioService.play(intensity: event.intensity)
                self.settingsVM.incrementSlapCount()
            }
            .store(in: &cancellables)

        // USB events -> play audio (if enabled)
        usbMonitor.start()
        usbMonitor.eventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self, self.settingsVM.usbMoanerEnabled else { return }
                self.audioService.playRandom()
            }
            .store(in: &cancellables)

        // Settings changes -> update detection params
        settingsVM.objectWillChange
            .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.slapDetectorVM.updateSettings(
                    sensitivity: self.settingsVM.sensitivity,
                    cooldown: self.settingsVM.cooldownSeconds
                )
                let newPack = self.settingsVM.selectedSoundPack
                if self.audioService.currentPack?.id != newPack.id {
                    self.audioService.loadSoundPack(newPack)
                }
            }
            .store(in: &cancellables)

        print("[SlapMac] App launched successfully")
    }
}

@main
struct SlapMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appDelegate.settingsVM)
                .environmentObject(appDelegate.slapDetectorVM)
        } label: {
            Label {
                Text(Constants.appName)
            } icon: {
                Image(systemName: "hand.tap.fill")
            }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(appDelegate.settingsVM)
        }
    }
}
