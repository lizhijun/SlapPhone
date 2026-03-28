import SwiftUI
import Combine

/// AppDelegate handles all background services that must run at app launch,
/// independent of UI visibility.
final class AppDelegate: NSObject, NSApplicationDelegate {
    let settingsVM = SettingsViewModel()
    let slapDetectorVM = SlapDetectorViewModel()
    let audioService = AudioService()
    let usbMonitor = USBMonitorService()
    let screenFlash = ScreenFlashService()
    let soundPackManager = SoundPackManager()
    lazy var importWindowController = SoundPackImportWindowController(packManager: soundPackManager)

    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Wire audio service to sound pack manager
        audioService.soundPackManager = soundPackManager

        // Resolve selected pack from manager (supports custom packs)
        let initialPack = soundPackManager.allPacks.first { $0.id == settingsVM.selectedSoundPackId } ?? .systemPack
        audioService.loadSoundPack(initialPack)

        // Start slap detection
        if slapDetectorVM.sensorAvailable {
            slapDetectorVM.startDetection(
                sensitivity: settingsVM.sensitivity,
                cooldown: settingsVM.cooldownSeconds
            )
        }

        // Slap events -> play selected sound + increment counter + flash
        slapDetectorVM.slapPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self else { return }
                self.audioService.playSound(id: self.settingsVM.selectedSoundId, intensity: event.intensity)
                self.settingsVM.incrementSlapCount()
                if self.settingsVM.screenFlashEnabled {
                    self.screenFlash.flash(intensity: event.intensity)
                }
            }
            .store(in: &cancellables)

        // USB events -> play selected sound (if enabled)
        usbMonitor.start()
        usbMonitor.eventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self, self.settingsVM.usbMoanerEnabled else { return }
                self.audioService.playSound(id: self.settingsVM.selectedSoundId, intensity: Float.random(in: 0.5...1.0))
            }
            .store(in: &cancellables)

        // Settings changes -> update detection params and sound pack
        settingsVM.objectWillChange
            .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.slapDetectorVM.updateSettings(
                    sensitivity: self.settingsVM.sensitivity,
                    cooldown: self.settingsVM.cooldownSeconds
                )
                let newPack = self.soundPackManager.allPacks.first { $0.id == self.settingsVM.selectedSoundPackId } ?? .slapMacPack
                if self.audioService.currentPack?.id != newPack.id {
                    self.audioService.loadSoundPack(newPack)
                    // Auto-select first sound if current selection not in new pack
                    if !newPack.sounds.contains(where: { $0.id == self.settingsVM.selectedSoundId }) {
                        self.settingsVM.selectedSoundId = newPack.sounds.first?.id ?? ""
                    }
                }
            }
            .store(in: &cancellables)

        // Reload audio when custom packs change (import/delete)
        soundPackManager.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                // If current pack was deleted, fall back to system
                let packExists = self.soundPackManager.allPacks.contains { $0.id == self.settingsVM.selectedSoundPackId }
                if !packExists {
                    self.settingsVM.selectedSoundPackId = SoundPack.systemPack.id
                    self.audioService.loadSoundPack(.systemPack)
                }
            }
            .store(in: &cancellables)
    }
}

@main
struct SlapMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(importWindowController: appDelegate.importWindowController)
                .environmentObject(appDelegate.settingsVM)
                .environmentObject(appDelegate.slapDetectorVM)
                .environmentObject(appDelegate.soundPackManager)
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
                .environmentObject(appDelegate.soundPackManager)
        }
    }
}
