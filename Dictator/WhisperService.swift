import Foundation
import os.log

private let log = Logger(subsystem: "com.jaredh159.dictator", category: "WhisperService")

actor WhisperService {
    private let endpoint = URL(string: "https://api.openai.com/v1/audio/transcriptions")!

    func transcribe(audioURL: URL) async throws -> String {
        guard let apiKey = Config.shared?.openaiApiKey else {
            throw WhisperError.apiError("Missing API key. Create ~/.config/dictator.json")
        }

        log.info("Starting transcription for: \(audioURL.path, privacy: .public)")

        let audioData: Data
        do {
            audioData = try Data(contentsOf: audioURL)
            log.info("Loaded audio file, size: \(audioData.count) bytes")
        } catch {
            log.error("Failed to load audio file: \(error.localizedDescription)")
            throw error
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"recording.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)

        // Add model
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)

        // Add language
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
        body.append("en\r\n".data(using: .utf8)!)

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body
        log.info("Sending request to OpenAI, body size: \(body.count) bytes")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            log.error("Response is not HTTPURLResponse")
            throw WhisperError.apiError("Invalid response type")
        }

        log.info("Response status: \(httpResponse.statusCode)")

        if httpResponse.statusCode != 200 {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            log.error("API error: \(errorText)")
            throw WhisperError.apiError(errorText)
        }

        let responseText = String(data: data, encoding: .utf8) ?? ""
        log.info("Response body: \(responseText, privacy: .public)")

        let result = try JSONDecoder().decode(WhisperResponse.self, from: data)
        log.info("Transcription result: \(result.text, privacy: .public)")
        return result.text
    }
}

struct WhisperResponse: Codable {
    let text: String
}

enum WhisperError: Error {
    case apiError(String)
}
