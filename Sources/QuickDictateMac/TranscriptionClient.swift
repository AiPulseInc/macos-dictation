import Foundation

struct TranscriptionResponse: Decodable {
    let text: String
    let detectedLanguage: String?
    let languageProbability: Double?
    let requestedLanguage: String

    enum CodingKeys: String, CodingKey {
        case text
        case detectedLanguage = "detected_language"
        case languageProbability = "language_probability"
        case requestedLanguage = "requested_language"
    }
}

enum TranscriptionClientError: LocalizedError {
    case invalidResponse
    case httpError(Int, String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The local transcription service returned an invalid response."
        case let .httpError(statusCode, message):
            return "The local transcription service returned \(statusCode): \(message)"
        }
    }
}

struct TranscriptionClient {
    func transcribe(fileURL: URL, language: String, endpoint: URL) async throws -> TranscriptionResponse {
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = try buildRequestBody(fileURL: fileURL, language: language, boundary: boundary)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranscriptionClientError.invalidResponse
        }

        guard (200 ..< 300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw TranscriptionClientError.httpError(httpResponse.statusCode, message)
        }

        return try JSONDecoder().decode(TranscriptionResponse.self, from: data)
    }

    private func buildRequestBody(fileURL: URL, language: String, boundary: String) throws -> Data {
        var body = Data()
        let filename = fileURL.lastPathComponent
        let mimeType = mimeType(for: fileURL.pathExtension)
        let fileData = try Data(contentsOf: fileURL)

        append("--\(boundary)\r\n", to: &body)
        append("Content-Disposition: form-data; name=\"language\"\r\n\r\n", to: &body)
        append("\(language)\r\n", to: &body)

        append("--\(boundary)\r\n", to: &body)
        append(
            "Content-Disposition: form-data; name=\"audio\"; filename=\"\(filename)\"\r\n",
            to: &body
        )
        append("Content-Type: \(mimeType)\r\n\r\n", to: &body)
        body.append(fileData)
        append("\r\n", to: &body)
        append("--\(boundary)--\r\n", to: &body)

        return body
    }

    private func mimeType(for fileExtension: String) -> String {
        switch fileExtension.lowercased() {
        case "wav":
            return "audio/wav"
        case "m4a":
            return "audio/mp4"
        default:
            return "application/octet-stream"
        }
    }

    private func append(_ string: String, to data: inout Data) {
        data.append(Data(string.utf8))
    }
}
