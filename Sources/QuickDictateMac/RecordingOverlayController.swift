import AppKit
import SwiftUI

@MainActor
final class RecordingOverlayController {
    enum State {
        case recording
        case transcribing
    }

    private var panel: NSPanel?
    private let overlaySize = NSSize(width: 132, height: 132)

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
        hostingView.frame = NSRect(origin: .zero, size: overlaySize)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: overlaySize),
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
    private let panelDiameter: CGFloat = 132
    private let haloDiameter: CGFloat = 124
    private let mainDiameter: CGFloat = 108
    private let iconSize: CGFloat = 36

    var body: some View {
        ZStack {
            Circle()
                .fill(ringColor)
                .frame(width: haloDiameter, height: haloDiameter)

            Circle()
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: mainDiameter, height: mainDiameter)
                .overlay {
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 1.2)
                }
                .shadow(color: shadowColor, radius: 10, y: 5)

            VStack(spacing: 4) {
                Image(systemName: "mic.fill")
                    .font(.system(size: iconSize, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.top, 4)

                Text(title)
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.95))
                Text(subtitle)
                    .font(.system(size: 7.5, weight: .medium))
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 12)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .frame(width: panelDiameter, height: panelDiameter)
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
        [Color.red.opacity(0.95), Color.red.opacity(0.74)]
    }

    private var shadowColor: Color {
        .red.opacity(0.28)
    }

    private var ringColor: Color {
        .red.opacity(0.16)
    }
}
