import AppKit
import SwiftUI

@MainActor
final class RecordingOverlayController {
    enum State {
        case recording
        case transcribing
    }

    private var panel: NSPanel?

    func show(_ state: State) {
        let panel = panel ?? makePanel()
        self.panel = panel
        if let hostingView = panel.contentView as? NSHostingView<RecordingOverlayView> {
            hostingView.rootView = RecordingOverlayView(state: state)
        }
        position(panel)
        panel.orderFrontRegardless()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func makePanel() -> NSPanel {
        let hostingView = NSHostingView(rootView: RecordingOverlayView(state: .recording))
        hostingView.frame = NSRect(x: 0, y: 0, width: 170, height: 170)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 170, height: 170),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.contentView = hostingView
        return panel
    }

    private func position(_ panel: NSPanel) {
        let screen = NSScreen.main ?? NSScreen.screens.first
        let visibleFrame = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let size = panel.frame.size
        let origin = NSPoint(
            x: visibleFrame.midX - size.width / 2,
            y: visibleFrame.minY + (visibleFrame.height * 0.33) - (size.height / 2)
        )
        panel.setFrameOrigin(origin)
    }
}

private struct RecordingOverlayView: View {
    let state: RecordingOverlayController.State

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: gradientColors,
                        center: .center,
                        startRadius: 10,
                        endRadius: 92
                    )
                )
                .frame(width: 170, height: 170)
                .overlay {
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                }
                .overlay {
                    Circle()
                        .stroke(ringColor, lineWidth: 18)
                        .scaleEffect(1.07)
                }
                .shadow(color: shadowColor, radius: 24, y: 12)

            VStack(spacing: 8) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 70, weight: .medium))
                    .foregroundStyle(.white)

                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.95))
                Text(subtitle)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .frame(width: 170, height: 170)
        .background(Color.clear)
    }

    private var title: String {
        switch state {
        case .recording:
            return "Recording"
        case .transcribing:
            return "Transcribing"
        }
    }

    private var subtitle: String {
        switch state {
        case .recording:
            return "Listening now"
        case .transcribing:
            return "Processing speech"
        }
    }

    private var gradientColors: [Color] {
        switch state {
        case .recording:
            return [Color.red.opacity(0.95), Color.red.opacity(0.74)]
        case .transcribing:
            return [Color.yellow.opacity(0.96), Color.orange.opacity(0.82)]
        }
    }

    private var shadowColor: Color {
        switch state {
        case .recording:
            return .red.opacity(0.28)
        case .transcribing:
            return .yellow.opacity(0.28)
        }
    }

    private var ringColor: Color {
        switch state {
        case .recording:
            return .red.opacity(0.18)
        case .transcribing:
            return .yellow.opacity(0.18)
        }
    }
}
