import Foundation
import os.log

private let log = Logger(subsystem: "com.jaredh159.dictator", category: "TextCleanupService")

actor TextCleanupService {
    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!

    private let defaultPrompt = """
        You are a light text editor. You receive raw transcriptions from a seasoned software \
        engineer that were converted from audio to text. Your job is to do a very light cleanup:

        1. Add proper punctuation (periods, commas, etc.)
        2. Split the text into paragraphs at natural idea boundaries—use good granularity
        3. If something looks like a transcription error of a technical/software term, fix it \
        (e.g., "reacts" → "React", "know JS" → "Node.js", "get hub" → "GitHub")
        4. Output as clean markdown

        IMPORTANT: Change as little as possible. Do NOT rephrase, summarize, or add content. \
        Do NOT over-edit. Just punctuate, paragraph, and fix obvious transcription mistakes \
        of technical terms. The engineer's voice and wording should remain intact.

        Return ONLY the cleaned markdown, no explanations or preamble.
        """

    func cleanup(text: String) async throws -> String {
        guard let config = Config.shared else {
            throw CleanupError.apiError("Missing config. Create ~/.config/dictator.json")
        }

        let prompt = config.cleanupPrompt ?? defaultPrompt
        log.info("Starting text cleanup, input length: \(text.count)")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.openaiApiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": prompt],
                ["role": "user", "content": text],
            ],
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            log.error("Response is not HTTPURLResponse")
            throw CleanupError.invalidResponse
        }

        log.info("Response status: \(httpResponse.statusCode)")

        if httpResponse.statusCode != 200 {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            log.error("API error: \(errorText, privacy: .public)")
            throw CleanupError.apiError(errorText)
        }

        let result = try JSONDecoder().decode(ChatResponse.self, from: data)
        let cleanedText = result.choices.first?.message.content ?? text

        log.info("Cleanup complete, output length: \(cleanedText.count)")
        return cleanedText
    }
}

struct ChatResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: Message
    }

    struct Message: Codable {
        let content: String
    }
}

enum CleanupError: Error {
    case invalidResponse
    case apiError(String)
}
