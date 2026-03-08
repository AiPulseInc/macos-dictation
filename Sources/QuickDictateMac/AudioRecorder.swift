import AVFoundation
import Foundation

enum AudioRecorderError: LocalizedError {
    case microphoneAccessDenied
    case recorderCreationFailed
    case recordingDidNotStart
    case noRecordingInProgress

    var errorDescription: String? {
        switch self {
        case .microphoneAccessDenied:
            return "Microphone access was denied. Enable it for this app in System Settings."
        case .recorderCreationFailed:
            return "Could not create the local audio recorder."
        case .recordingDidNotStart:
            return "Recording did not start."
        case .noRecordingInProgress:
            return "No recording is currently in progress."
        }
    }
}

@MainActor
final class AudioRecorder: NSObject {
    private var recorder: AVAudioRecorder?
    private var currentFileURL: URL?

    func startRecording() async throws {
        let permissionGranted = await AVCaptureDevice.requestAccess(for: .audio)
        guard permissionGranted else {
            throw AudioRecorderError.microphoneAccessDenied
        }

        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("quickdictate-\(UUID().uuidString)")
            .appendingPathExtension("m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        guard let recorder = try? AVAudioRecorder(url: fileURL, settings: settings) else {
            throw AudioRecorderError.recorderCreationFailed
        }

        recorder.prepareToRecord()
        guard recorder.record() else {
            throw AudioRecorderError.recordingDidNotStart
        }

        self.recorder = recorder
        currentFileURL = fileURL
    }

    func stopRecording() throws -> URL {
        guard let recorder, let currentFileURL else {
            throw AudioRecorderError.noRecordingInProgress
        }

        recorder.stop()
        self.recorder = nil
        self.currentFileURL = nil
        return currentFileURL
    }
}
