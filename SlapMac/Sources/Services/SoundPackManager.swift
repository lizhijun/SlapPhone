import Foundation

/// Manages custom sound packs stored in ~/Library/Application Support/SlapMac/SoundPacks/
final class SoundPackManager: ObservableObject {
    @Published var customPacks: [SoundPack] = []

    /// All available packs (built-in + custom)
    var allPacks: [SoundPack] {
        SoundPack.builtInPacks + customPacks
    }

    private var baseDir: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport
            .appendingPathComponent(Constants.appSupportDir)
            .appendingPathComponent(Constants.soundPacksDir)
    }

    init() {
        ensureDirectoryExists()
        loadCustomPacks()
    }

    // MARK: - Import

    /// Import audio files as a new custom sound pack
    func importPack(name: String, audioURLs: [URL]) throws {
        let packId = UUID().uuidString
        let packDir = baseDir.appendingPathComponent(packId)

        try FileManager.default.createDirectory(at: packDir, withIntermediateDirectories: true)

        // Copy audio files
        var soundFiles: [SoundFile] = []
        let sorted = audioURLs.sorted { $0.lastPathComponent < $1.lastPathComponent }
        let count = sorted.count

        for (index, url) in sorted.enumerated() {
            let destURL = packDir.appendingPathComponent(url.lastPathComponent)
            try FileManager.default.copyItem(at: url, to: destURL)

            // Evenly distribute intensity ranges
            let min = Float(index) / Float(count)
            let max = Float(index + 1) / Float(count)

            soundFiles.append(SoundFile(
                id: UUID().uuidString,
                fileName: url.deletingPathExtension().lastPathComponent,
                fileExtension: url.pathExtension,
                minIntensity: min,
                maxIntensity: max
            ))
        }

        // Save metadata
        let metadata = PackMetadata(id: packId, name: name, sounds: soundFiles)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(metadata)
        try data.write(to: packDir.appendingPathComponent(Constants.packMetadataFile))

        // Reload
        loadCustomPacks()
    }

    // MARK: - Delete

    func deletePack(id: String) throws {
        let packDir = baseDir.appendingPathComponent(id)
        if FileManager.default.fileExists(atPath: packDir.path) {
            try FileManager.default.removeItem(at: packDir)
        }
        loadCustomPacks()
    }

    // MARK: - Load

    func loadCustomPacks() {
        var packs: [SoundPack] = []

        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: baseDir,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else {
            customPacks = []
            return
        }

        for dir in contents where dir.hasDirectoryPath {
            let metaURL = dir.appendingPathComponent(Constants.packMetadataFile)
            guard let data = try? Data(contentsOf: metaURL),
                  let metadata = try? JSONDecoder().decode(PackMetadata.self, from: data) else {
                continue
            }

            let pack = SoundPack(
                id: metadata.id,
                name: metadata.name,
                description: "Custom - \(metadata.sounds.count) sounds",
                sounds: metadata.sounds,
                isSystem: false
            )
            packs.append(pack)
        }

        customPacks = packs.sorted { $0.name < $1.name }
    }

    /// Get the directory URL for a custom pack
    func packDirectory(for packId: String) -> URL {
        baseDir.appendingPathComponent(packId)
    }

    // MARK: - Private

    private func ensureDirectoryExists() {
        try? FileManager.default.createDirectory(at: baseDir, withIntermediateDirectories: true)
    }
}

// MARK: - Pack Metadata (JSON)

private struct PackMetadata: Codable {
    let id: String
    let name: String
    let sounds: [SoundFile]
}
