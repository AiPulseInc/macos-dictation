import AppKit
import Carbon
import Foundation

@MainActor
final class DictationController: ObservableObject {
    enum Language: String, CaseIterable, Identifiable {
        case auto
        case en
        case pl

        var id: String { rawValue }

        var label: String {
            switch self {
            case .auto:
                return "Auto"
            case .en:
                return "English"
            case .pl:
                return "Polish"
            }
        }
    }

    enum Model: String, CaseIterable, Identifiable {
        case base
        case small
        case medium

        var id: String { rawValue }

        var label: String {
            rawValue.capitalized
        }

        var helperText: String {
            switch self {
            case .base:
                return "Fastest local model"
            case .small:
                return "Balanced quality"
            case .medium:
                return "Highest local quality"
            }
        }
    }

    @Published var isRecording = false
    @Published var isBusy = false
    @Published var selectedLanguage: Language = .auto
    @Published var selectedModel: Model = .small
    @Published var refineTranscriptEnabled = true
    @Published var transcript = ""
    @Published var rawTranscript = ""
    @Published var statusMessage = "Ready"
    @Published var lastDetectedLanguage = "-"
    @Published var lastError = ""
    @Published var hotKeyStatus = "Shortcut not installed yet"
    @Published var lastTriggerSource = "Manual"
    @Published var autoPasteEnabled = true
    @Published var lastModelUsed = "-"
    @Published var backendStatus = "Backend not checked"

    let shortcutDisplay = "Control + B"
    let serviceURL = URL(string: "http://127.0.0.1:8765/transcribe")!

    private let recorder = AudioRecorder()
    private let client = TranscriptionClient()
    private let textInsertionService = TextInsertionService()
    private let recordingOverlay = RecordingOverlayController()
    private let backendManager = BackendServiceManager.shared
    private var hotKey: GlobalHotKey?
    private var didInstallHotKey = false
    private var didStartup = false
    private var targetApplication: NSRunningApplication?

    init() {
        Task { @MainActor [weak self] in
            await self?.startup()
        }
    }

    func startup() async {
        guard !didStartup else { return }
        didStartup = true
        installHotKeyIfNeeded()
        await ensureBackendRunning()
    }

    func installHotKeyIfNeeded() {
        guard !didInstallHotKey else { return }
        didInstallHotKey = true

        do {
            hotKey = try GlobalHotKey(keyCode: UInt32(kVK_ANSI_B), modifiers: UInt32(controlKey)) { [weak self] in
                Task { @MainActor [weak self] in
                    self?.lastTriggerSource = "Global shortcut"
                    await self?.toggleRecording()
                }
            }
            hotKeyStatus = "Shortcut installed"
        } catch {
            hotKeyStatus = "Shortcut failed"
            lastError = error.localizedDescription
        }
    }

    func toggleRecording() async {
        if isBusy {
            return
        }

        if isRecording {
            await finishRecording()
        } else {
            await beginRecording()
        }
    }

    func copyTranscript() {
        guard !transcript.isEmpty else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(transcript, forType: .string)
        statusMessage = "Transcript copied to clipboard"
    }

    private func beginRecording() async {
        lastError = ""

        do {
            await ensureBackendRunning()
            statusMessage = "Requesting microphone access..."
            targetApplication = NSWorkspace.shared.frontmostApplication
            try await recorder.startRecording()
            isRecording = true
            recordingOverlay.show(.recording)
            statusMessage = "Recording... press \(shortcutDisplay) again to stop"
        } catch {
            isRecording = false
            recordingOverlay.hide()
            lastError = error.localizedDescription
            statusMessage = "Microphone error"
        }
    }

    private func finishRecording() async {
        isRecording = false
        isBusy = true
        recordingOverlay.show(.transcribing)
        statusMessage = "Transcribing..."
        lastError = ""

        do {
            let audioURL = try recorder.stopRecording()
            let response = try await client.transcribe(
                fileURL: audioURL,
                language: selectedLanguage.rawValue,
                model: selectedModel.rawValue,
                refineText: refineTranscriptEnabled,
                endpoint: serviceURL
            )

            transcript = response.text
            rawTranscript = response.rawText ?? response.text
            lastDetectedLanguage = response.detectedLanguage ?? "-"
            lastModelUsed = response.modelUsed ?? selectedModel.rawValue
            if response.text.isEmpty {
                copyTranscript()
                statusMessage = "No speech detected"
            } else if autoPasteEnabled {
                do {
                    try await textInsertionService.insert(response.text, into: targetApplication)
                    statusMessage = "Transcript pasted into the previous app"
                } catch {
                    copyTranscript()
                    lastError = error.localizedDescription
                    statusMessage = "Transcript copied to clipboard"
                }
            } else {
                copyTranscript()
                statusMessage = "Transcript copied to clipboard"
            }

            try? FileManager.default.removeItem(at: audioURL)
        } catch {
            lastError = error.localizedDescription
            statusMessage = "Transcription failed"
        }

        targetApplication = nil
        recordingOverlay.hide()
        isBusy = false
    }

    func startFromUI() {
        lastTriggerSource = "UI button"
        Task {
            await toggleRecording()
        }
    }

    private func ensureBackendRunning() async {
        do {
            backendStatus = "Starting local backend..."
            try await backendManager.ensureRunning()
            backendStatus = "Local backend ready"
        } catch {
            backendStatus = "Backend unavailable"
            lastError = error.localizedDescription
        }
    }
}
