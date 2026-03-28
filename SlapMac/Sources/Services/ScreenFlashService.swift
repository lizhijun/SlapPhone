import AppKit

final class ScreenFlashService {
    private var flashWindows: [NSWindow] = []

    /// Flash all screens with white overlay. Intensity 0.0-1.0 maps to opacity.
    func flash(intensity: Float) {
        // Remove any lingering windows
        flashWindows.forEach { $0.orderOut(nil) }
        flashWindows.removeAll()

        for screen in NSScreen.screens {
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false
            )
            window.level = .screenSaver
            window.backgroundColor = .white
            window.isOpaque = false
            window.ignoresMouseEvents = true
            window.hasShadow = false
            window.collectionBehavior = [.canJoinAllSpaces, .stationary]
            window.alphaValue = CGFloat(intensity) * Constants.flashMaxAlpha
            window.orderFrontRegardless()
            flashWindows.append(window)
        }

        // Fade out
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = Constants.flashDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            for window in flashWindows {
                window.animator().alphaValue = 0
            }
        }, completionHandler: { [weak self] in
            self?.flashWindows.forEach { $0.orderOut(nil) }
            self?.flashWindows.removeAll()
        })
    }
}
