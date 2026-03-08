import AppKit
import ApplicationServices
import Foundation

enum TextInsertionError: LocalizedError {
    case accessibilityPermissionDenied
    case noTargetApplication
    case keyEventCreationFailed

    var errorDescription: String? {
        switch self {
        case .accessibilityPermissionDenied:
            return "Accessibility access is required to paste into other apps. Enable it for QuickDictateMac in System Settings > Privacy & Security > Accessibility."
        case .noTargetApplication:
            return "There was no previously active app to paste into."
        case .keyEventCreationFailed:
            return "Could not synthesize the paste keystroke."
        }
    }
}

@MainActor
final class TextInsertionService {
    func insert(_ text: String, into targetApp: NSRunningApplication?) async throws {
        guard let targetApp else {
            throw TextInsertionError.noTargetApplication
        }

        guard ensureAccessibilityPermission() else {
            throw TextInsertionError.accessibilityPermissionDenied
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        targetApp.activate(options: [.activateIgnoringOtherApps])
        try await Task.sleep(for: .milliseconds(250))
        try postPasteShortcut()
    }

    private func ensureAccessibilityPermission() -> Bool {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    private func postPasteShortcut() throws {
        guard
            let source = CGEventSource(stateID: .combinedSessionState),
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true),
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false)
        else {
            throw TextInsertionError.keyEventCreationFailed
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}
