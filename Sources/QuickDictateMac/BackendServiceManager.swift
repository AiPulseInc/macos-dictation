import Foundation

@MainActor
final class BackendServiceManager {
    static let shared = BackendServiceManager()

    private let healthURL = URL(string: "http://127.0.0.1:8765/health")!
    private var process: Process?
    private var managedProcess = false

    private init() {}

    func ensureRunning() async throws {
        if await isHealthy() {
            return
        }

        if process == nil {
            try launchBundledBackend()
        }

        let deadline = Date().addingTimeInterval(20)
        while Date() < deadline {
            if await isHealthy() {
                return
            }

            if let process, !process.isRunning {
                throw BackendServiceError.processExited
            }

            try await Task.sleep(for: .milliseconds(350))
        }

        throw BackendServiceError.startupTimedOut
    }

    func stopIfManaged() {
        guard managedProcess, let process else { return }
        if process.isRunning {
            process.terminate()
        }
        self.process = nil
        managedProcess = false
    }

    private func launchBundledBackend() throws {
        let backendURL = try bundledBackendURL()
        let pythonURL = try bundledPythonURL(in: backendURL)

        let process = Process()
        process.executableURL = pythonURL
        process.currentDirectoryURL = backendURL
        process.arguments = [
            "-m",
            "uvicorn",
            "app:app",
            "--host",
            "127.0.0.1",
            "--port",
            "8765",
        ]

        var environment = ProcessInfo.processInfo.environment
        environment["HF_HOME"] = backendURL.appendingPathComponent(".cache/huggingface").path
        environment["PYTHONPYCACHEPREFIX"] = backendURL.appendingPathComponent(".pycache").path
        environment["PATH"] = [
            backendURL.appendingPathComponent(".venv/bin").path,
            environment["PATH"] ?? "",
        ]
        .joined(separator: ":")
        process.environment = environment

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        do {
            try process.run()
            self.process = process
            managedProcess = true
        } catch {
            throw BackendServiceError.launchFailed(error.localizedDescription)
        }
    }

    private func bundledBackendURL() throws -> URL {
        guard let resourcesURL = Bundle.main.resourceURL else {
            throw BackendServiceError.missingBundledBackend
        }

        let backendURL = resourcesURL.appendingPathComponent("quickdictate-asr")
        guard FileManager.default.fileExists(atPath: backendURL.path) else {
            throw BackendServiceError.missingBundledBackend
        }

        return backendURL
    }

    private func bundledPythonURL(in backendURL: URL) throws -> URL {
        let candidates = [
            backendURL.appendingPathComponent(".venv/bin/python3"),
            backendURL.appendingPathComponent(".venv/bin/python"),
        ]

        for candidate in candidates where FileManager.default.isExecutableFile(atPath: candidate.path) {
            return candidate
        }

        throw BackendServiceError.missingBundledPython
    }

    private func isHealthy() async -> Bool {
        var request = URLRequest(url: healthURL)
        request.timeoutInterval = 0.8

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { return false }
            return httpResponse.statusCode == 200
        } catch {
            return false
        }
    }
}

enum BackendServiceError: LocalizedError {
    case missingBundledBackend
    case missingBundledPython
    case launchFailed(String)
    case processExited
    case startupTimedOut

    var errorDescription: String? {
        switch self {
        case .missingBundledBackend:
            return "The bundled ASR backend was not found inside the app."
        case .missingBundledPython:
            return "The bundled Python environment for the ASR backend was not found."
        case let .launchFailed(message):
            return "The bundled ASR backend could not be launched: \(message)"
        case .processExited:
            return "The bundled ASR backend exited before it became ready."
        case .startupTimedOut:
            return "The bundled ASR backend did not become ready in time."
        }
    }
}
