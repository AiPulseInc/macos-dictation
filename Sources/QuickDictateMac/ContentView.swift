import SwiftUI

struct ContentView: View {
    @ObservedObject var controller: DictationController

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("QuickDictate")
                        .font(.title2.bold())
                    Text("Local dictation via your FastAPI + faster-whisper service")
                        .foregroundStyle(.secondary)
                }

                Spacer()

                RecordingIndicatorView(isRecording: controller.isRecording, isBusy: controller.isBusy)
            }

            if controller.isRecording {
                RecordingBannerView(shortcutDisplay: controller.shortcutDisplay)
            }

            HStack {
                Label(controller.shortcutDisplay, systemImage: "keyboard")
                Spacer()
                Picker("Language", selection: $controller.selectedLanguage) {
                    ForEach(DictationController.Language.allCases) { language in
                        Text(language.label).tag(language)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 220)
            }

            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Model")
                        .font(.headline)
                    Picker("Model", selection: $controller.selectedModel) {
                        ForEach(DictationController.Model.allCases) { model in
                            Text(model.label).tag(model)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Spacer()

                Text(controller.selectedModel.helperText)
                    .foregroundStyle(.secondary)
            }

            Toggle("Paste transcript into previous app automatically", isOn: $controller.autoPasteEnabled)
            Toggle("Refine transcript after decoding", isOn: $controller.refineTranscriptEnabled)

            HStack(spacing: 12) {
                Button(controller.isRecording ? "Stop Recording" : "Start Recording") {
                    controller.startFromUI()
                }
                .keyboardShortcut("b", modifiers: [.control])
                .disabled(controller.isBusy)

                Button("Copy Transcript") {
                    controller.copyTranscript()
                }
                .disabled(controller.transcript.isEmpty)

                Spacer()

                Text(controller.statusMessage)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Transcript")
                    .font(.headline)

                TextEditor(text: $controller.transcript)
                    .font(.body.monospaced())
                    .frame(minHeight: 180)
                    .padding(8)
                    .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
            }

            HStack {
                Text("Detected language: \(controller.lastDetectedLanguage)")
                    .foregroundStyle(.secondary)

                Spacer()

                Text("Model: \(controller.lastModelUsed)")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("ASR: 127.0.0.1:8765")
                    .foregroundStyle(.secondary)

                Spacer()

                Text(controller.refineTranscriptEnabled ? "Cleanup on" : "Cleanup off")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text(controller.backendStatus)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            HStack {
                Text("Hotkey: \(controller.hotKeyStatus)")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Last trigger: \(controller.lastTriggerSource)")
                    .foregroundStyle(.secondary)
            }

            if !controller.lastError.isEmpty {
                Text(controller.lastError)
                    .foregroundStyle(.red)
            }
        }
        .padding(20)
        .frame(width: 520)
        .task {
            await controller.startup()
        }
    }
}

struct MenuBarContentView: View {
    @ObservedObject var controller: DictationController

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(controller.isRecording ? "Recording..." : "QuickDictate")
                .font(.headline)

            Text("Shortcut: \(controller.shortcutDisplay)")
                .foregroundStyle(.secondary)

            Picker("Language", selection: $controller.selectedLanguage) {
                ForEach(DictationController.Language.allCases) { language in
                    Text(language.label).tag(language)
                }
            }

            Picker("Model", selection: $controller.selectedModel) {
                ForEach(DictationController.Model.allCases) { model in
                    Text(model.label).tag(model)
                }
            }

            Toggle("Auto paste", isOn: $controller.autoPasteEnabled)
            Toggle("Refine transcript", isOn: $controller.refineTranscriptEnabled)

            Button(controller.isRecording ? "Stop Recording" : "Start Recording") {
                controller.startFromUI()
            }
            .disabled(controller.isBusy)

            if !controller.transcript.isEmpty {
                Divider()
                Text(controller.transcript)
                    .lineLimit(6)
                Button("Copy Transcript") {
                    controller.copyTranscript()
                }
            }

            Divider()
            Text(controller.statusMessage)
                .foregroundStyle(.secondary)

            Text(controller.hotKeyStatus)
                .foregroundStyle(.secondary)

            Text(controller.backendStatus)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(width: 320)
        .task {
            await controller.startup()
        }
    }
}

private struct RecordingIndicatorView: View {
    let isRecording: Bool
    let isBusy: Bool

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(isRecording ? .red : (isBusy ? .orange : .secondary.opacity(0.35)))
                .frame(width: 14, height: 14)
                .overlay {
                    if isRecording {
                        Circle()
                            .stroke(.red.opacity(0.35), lineWidth: 8)
                            .scaleEffect(1.55)
                    }
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(isRecording ? "Listening now" : (isBusy ? "Transcribing" : "Idle"))
                    .font(.headline)
                Text(isRecording ? "Microphone is live" : (isBusy ? "Processing your speech" : "Waiting for shortcut"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isRecording ? Color.red.opacity(0.12) : Color.secondary.opacity(0.08))
        )
    }
}

private struct RecordingBannerView: View {
    let shortcutDisplay: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "waveform")
                .font(.title3.bold())
            VStack(alignment: .leading, spacing: 3) {
                Text("Recording in progress")
                    .font(.headline)
                Text("Press \(shortcutDisplay) again to stop and transcribe")
                    .font(.caption)
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.red.opacity(0.18), Color.orange.opacity(0.10)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}
