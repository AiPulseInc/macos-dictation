import SwiftUI
import AppKit

@main
struct QuickDictateMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var controller = DictationController()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(controller: controller)
        } label: {
            Label(
                controller.isRecording ? "Recording" : "QuickDictate",
                systemImage: controller.isRecording ? "mic.circle.fill" : "mic.circle"
            )
        }

        WindowGroup("QuickDictate") {
            ContentView(controller: controller)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 520, height: 420)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)

        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
        }
    }
}
