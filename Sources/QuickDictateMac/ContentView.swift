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

                Image(systemName: controller.isRecording ? "waveform.circle.fill" : "mic.circle")
                    .font(.system(size: 28))
                    .foregroundStyle(controller.isRecording ? .red : .accentColor)
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

            Toggle("Paste transcript into previous app automatically", isOn: $controller.autoPasteEnabled)

            HStack(spacing: 12) {
                Button(controller.isRecording ? "Stop Recording" : "Start Recording") {
                    controller.startFromUI()
                }
                .keyboardShortcut(.space, modifiers: [.control, .option])
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

                Text("ASR: 127.0.0.1:8765")
                    .foregroundStyle(.secondary)
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
            controller.installHotKeyIfNeeded()
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

            Toggle("Auto paste", isOn: $controller.autoPasteEnabled)

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
        }
        .padding()
        .frame(width: 320)
        .task {
            controller.installHotKeyIfNeeded()
        }
    }
}
