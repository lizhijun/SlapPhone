# SlapMac 👋

A macOS menu bar app that detects physical slaps on your MacBook trackpad and plays hilarious sound reactions.

![SlapMac Icon](SlapMac/Resources/AppIcon.icns)

## Features

🎯 **Slap Detection**
- Uses Apple Silicon accelerometer to detect trackpad impacts in real-time
- Adjustable sensitivity slider (Low/Medium/High)
- Configurable cooldown to prevent accidental re-triggers

🔊 **11 Built-in Sound Effects**
- **SlapMac Pack** (default): combo, fart, gentleman, goat, knock, male, muyu, punch, sexy, wtf, yamete
- **System Pack**: Classic macOS system sounds
- **Alert Pack**: Notification sounds
- **Dramatic Pack**: Dramatic sound effects

🎵 **Custom Sound Pack Import**
- Import your own audio files (MP3, WAV, AIFF, M4A, AAC, CAF)
- Organize sounds by intensity levels
- Manage multiple custom packs

⚡ **Additional Features**
- **Screen Flash**: Visual feedback with intensity-mapped white screen overlay
- **USB Moaner**: Optional sounds on USB device connect/disconnect
- **Launch at Login**: Automatically start with your Mac
- **Slap Counter**: Tracks total slaps in your session
- **Sound Selector**: Pick any specific sound to always play on slaps

## Installation

### Download DMG
Download the latest `SlapMac.dmg` from the releases page and drag `SlapMac.app` to your Applications folder.

### Build from Source
```bash
git clone https://github.com/lizhijun/SlapPhone.git
cd SlapPhone/SlapMac
bash build.sh
open SlapMac.app
```

## Requirements

- **macOS 14.6+** (Sonoma or later)
- **Apple Silicon Mac** (M1, M2, M3, M4, etc.) - Uses built-in accelerometer
- Trackpad access enabled

## Usage

1. **Launch** SlapMac from Applications or Launchpad
2. **Look at menu bar** for the hand-tap icon
3. **Click menu bar icon** to open quick settings
4. **Slap your trackpad** to trigger sound reactions
5. **Adjust settings**:
   - Sensitivity: Increase to detect lighter slaps
   - Cooldown: Minimum time between detections
   - Sound Pack: Choose preset or custom pack
   - Sound: Select specific sound to play
   - Screen Flash: Toggle visual feedback
   - USB Moaner: Toggle USB event sounds

## Settings

### Detection Settings
- **Sensitivity** (0.1–1.0): Controls detection threshold
  - Lower = more sensitive (detects lighter touches)
  - Higher = less sensitive (requires harder slaps)
- **Cooldown** (0.2–5.0 seconds): Minimum time between detections

### Audio Settings
- **Sound Pack**: Choose from built-in or imported packs
- **Sound**: Select specific sound from current pack (no random)
- **Import Pack**: Add custom audio files
- **Delete Pack**: Remove custom packs

### Features
- **USB Moaner**: Play sound on USB device connect/disconnect
- **Screen Flash**: Full-screen white flash on detection

## Architecture

### Core Components

**AccelerometerService** - Reads Apple Silicon SPU accelerometer via IOKit HID
- ~100Hz sampling rate
- Parses raw acceleration data (X, Y, Z in g units)

**SlapDetectionService** - Intelligent impact detection
- Low-pass gravity filter separates device tilt from motion
- Converts raw acceleration to impact magnitude
- Sensitivity-adjusted threshold for customizable detection
- Enforces cooldown period

**AudioService** - Sound playback engine
- Loads sound packs into memory
- Direct sound-to-file mapping (no intensity-based selection)
- Volume scales with impact intensity
- Supports system sounds and custom packs

**ScreenFlashService** - Visual feedback
- Borderless NSWindow overlay on all screens
- Intensity-mapped opacity (0.0–0.6)
- 0.15s fade-out animation

**SoundPackManager** - Custom sound management
- Stores custom packs in `~/Library/Application Support/SlapMac/SoundPacks/`
- Import: copies files + creates pack.json metadata
- Delete: removes pack directory
- Auto-fallback if selected pack deleted

### Tech Stack
- **Swift 5.9+**
- **SwiftUI** (UI framework)
- **Combine** (reactive state management)
- **IOKit** (hardware access)
- **ServiceManagement** (launch at login)
- **No external dependencies** (100% system frameworks)

## How It Works

### Slap Detection Algorithm

1. **Raw Data**: Accelerometer publishes X/Y/Z acceleration at 100Hz
2. **Gravity Filter**: Low-pass filter (alpha=0.9) estimates device orientation
3. **Dynamic Acceleration**: Subtracts gravity to get motion only
4. **Magnitude**: Computes Euclidean norm of dynamic acceleration
5. **Threshold**: Compares magnitude to sensitivity-adjusted baseline
6. **Cooldown**: Enforces minimum time since last detection
7. **Normalization**: Clamps magnitude to 0.0–1.0 intensity
8. **Event**: Publishes SlapEvent with timestamp, intensity, raw acceleration

### Sound Selection

- User selects specific sound from current pack via dropdown
- On slap detection, plays selected sound
- Volume scales: `baseVolume + intensity * (maxVolume - baseVolume)`
- No randomness—always the same sound (user's choice)

## Project Structure

```
SlapMac/
├── Sources/
│   ├── App/               # Entry point + AppDelegate
│   ├── Models/            # SlapEvent, SoundPack, SoundFile
│   ├── Services/          # Accelerometer, detection, audio, screen, USB
│   ├── ViewModels/        # Settings state, detection state
│   ├── Views/             # MenuBar, Settings, About, Import
│   └── Utilities/         # Constants
├── soundpack/             # 11 bundled audio files
├── Resources/             # App icon (AppIcon.icns)
├── Package.swift          # Swift Package manifest
├── build.sh              # Build automation script
└── SlapMac.app/          # Built application bundle
```

## Building

### Requirements
- Xcode 15+ (or Swift 5.9+ command-line tools)
- macOS 14.6+ development environment

### Build Steps
```bash
cd SlapMac
swift build -c release      # Compile Swift code
bash build.sh              # Create app bundle + copy resources
open SlapMac.app           # Launch the app
```

The `build.sh` script handles:
- Compiling Swift source
- Creating `.app` bundle structure
- Copying app icon
- Copying bundled sound files
- Generating `Info.plist`

### Create DMG Installer
```bash
cd SlapMac
# After building, the DMG is created by:
bash build.sh  # (includes DMG creation)
```

## Troubleshooting

### Slap detection not working
- Ensure macOS 14.6+ (Apple Silicon only)
- Try increasing sensitivity slider
- Check if accelerometer is available: look for green "Detecting" status in menu

### Sounds not playing
- Check System Preferences → Sound → Output volume
- Verify audio files are in soundpack/ directory
- Try System or Alert sound pack first (macOS built-in sounds)

### Custom pack import fails
- Ensure audio files are in supported format (MP3, WAV, AIFF, M4A, AAC, CAF)
- Check file permissions
- Verify enough disk space in `~/Library/Application Support/`

### Can't enable "Launch at Login"
- Grant permissions if prompted
- Check System Preferences → General → Login Items

## Performance Notes

- Accelerometer sampling: ~100Hz (low power)
- Detection runs on main thread (< 1ms per sample)
- Audio playback is non-blocking
- Screen flash uses GPU acceleration
- Memory: ~50–100 MB at rest

## Privacy & Security

- **No network access** - App runs entirely offline
- **No tracking** - No analytics or telemetry
- **File access** - Only reads selected audio files
- **Permissions** - Requires IOKit access to accelerometer (built into macOS)
- **Data storage** - Settings saved locally via UserDefaults

## Development

### Key Files to Understand

1. **AccelerometerService.swift** - Hardware communication (IOKit HID)
2. **SlapDetectionService.swift** - Detection algorithm (gravity filter + threshold)
3. **AudioService.swift** - Sound playback logic
4. **MenuBarView.swift** - UI layout and state binding
5. **SlapMacApp.swift** - App lifecycle and service coordination

### Adding New Features

- **New sound pack**: Add SoundFile entries to `SoundPack.swift`
- **New visual effect**: Create new Service class like `ScreenFlashService.swift`
- **New detection mode**: Extend `SlapDetectionService.swift`
- **UI changes**: Modify SwiftUI views in `Sources/Views/`

## Known Limitations

- **Apple Silicon only** - Requires M1/M2/M3/M4+ Mac (accelerometer feature)
- **Menu bar only** - Cannot run in Dock
- **Single window** - No multi-window support
- **Intel Macs** - Not supported (no SPU accelerometer)

## Future Ideas

- [ ] Haptic feedback on slap detection
- [ ] Leaderboard/achievements
- [ ] Sound pack sharing
- [ ] Slap recording/replay
- [ ] Multiplayer slap battles
- [ ] Machine learning for slap gesture recognition
- [ ] Camera-based slap detection (alternative to accelerometer)

## License

MIT License - Feel free to fork, modify, and distribute

## Credits

Built with ❤️ using Swift, SwiftUI, and Apple's IOKit framework.

### Audio Sources
Sound effects sourced from public collections and custom recordings.

## Support

- Report issues: [GitHub Issues](https://github.com/lizhijun/SlapPhone/issues)
- Suggest features: [GitHub Discussions](https://github.com/lizhijun/SlapPhone/discussions)
- Contact: [@lizhijun](https://github.com/lizhijun)

---

**Have fun slapping! 👋**
