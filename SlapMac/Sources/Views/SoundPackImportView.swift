import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// Manages the import window as an independent NSWindow (not a popover)
/// to avoid MenuBarExtra dismissal issues when NSOpenPanel appears.
final class SoundPackImportWindowController {
    private var window: NSWindow?
    private var packManager: SoundPackManager

    init(packManager: SoundPackManager) {
        self.packManager = packManager
    }

    func showWindow() {
        // If already showing, just bring to front
        if let existing = window, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let importView = SoundPackImportView(
            packManager: packManager,
            onDismiss: { [weak self] in
                self?.window?.close()
                self?.window = nil
            }
        )

        let hostingView = NSHostingView(rootView: importView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 380, height: 340)

        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 340),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        win.title = "Import Sound Pack"
        win.contentView = hostingView
        win.center()
        win.isReleasedWhenClosed = false
        win.level = .floating
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.window = win
    }
}

struct SoundPackImportView: View {
    @ObservedObject var packManager: SoundPackManager
    var onDismiss: () -> Void

    @State private var packName = ""
    @State private var selectedFiles: [URL] = []
    @State private var errorMessage: String?
    @State private var isImporting = false

    var body: some View {
        VStack(spacing: 16) {
            // Name field
            TextField("Pack Name", text: $packName)
                .textFieldStyle(.roundedBorder)

            // File list
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Audio Files (\(selectedFiles.count))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Choose Files...") {
                        chooseFiles()
                    }
                    .controlSize(.small)
                }

                if selectedFiles.isEmpty {
                    Text("No files selected.\nSupports: mp3, wav, aiff, m4a, aac, caf")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, minHeight: 60)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(selectedFiles, id: \.path) { url in
                                HStack {
                                    Image(systemName: "music.note")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(url.lastPathComponent)
                                        .font(.caption)
                                        .lineLimit(1)
                                    Spacer()
                                    Button {
                                        selectedFiles.removeAll { $0 == url }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 120)
                }
            }
            .padding(8)
            .background(.quaternary.opacity(0.5))
            .cornerRadius(6)

            // Error
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            // Actions
            HStack {
                Button("Cancel") {
                    onDismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Import") {
                    doImport()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(packName.isEmpty || selectedFiles.isEmpty || isImporting)
            }
        }
        .padding(20)
        .frame(width: 360)
    }

    private func chooseFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = Constants.supportedAudioExtensions.compactMap {
            UTType(filenameExtension: $0)
        }
        panel.message = "Select audio files for the sound pack"

        if panel.runModal() == .OK {
            selectedFiles = panel.urls.sorted { $0.lastPathComponent < $1.lastPathComponent }
        }
    }

    private func doImport() {
        isImporting = true
        errorMessage = nil

        // Start accessing security-scoped resources
        var accessedURLs: [URL] = []
        for url in selectedFiles {
            if url.startAccessingSecurityScopedResource() {
                accessedURLs.append(url)
            }
        }

        do {
            try packManager.importPack(name: packName, audioURLs: selectedFiles)
            for url in accessedURLs {
                url.stopAccessingSecurityScopedResource()
            }
            onDismiss()
        } catch {
            for url in accessedURLs {
                url.stopAccessingSecurityScopedResource()
            }
            errorMessage = "Import failed: \(error.localizedDescription)"
            isImporting = false
        }
    }
}
