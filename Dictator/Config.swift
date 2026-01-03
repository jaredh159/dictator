import Carbon.HIToolbox
import Foundation
import TOMLKit
import os.log

private let log = Logger(subsystem: "com.jaredh159.dictator", category: "Config")

struct Personality: Identifiable {
    let name: String
    let hotkey: String
    let prompt: String

    var id: String { name }

    var parsedHotkey: (keyCode: UInt32, modifiers: UInt32) {
        parseHotkey(hotkey)
    }
}

struct Config {
    let openaiApiKey: String
    let personalities: [Personality]

    static let shared: Config? = {
        let configDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config")
            .appendingPathComponent("dictator")

        let secretsPath = configDir.appendingPathComponent("dictator.secrets.toml")
        let personalitiesPath = configDir.appendingPathComponent("dictator.personalities.toml")

        // Load secrets
        guard FileManager.default.fileExists(atPath: secretsPath.path) else {
            log.error("Secrets file not found at \(secretsPath.path, privacy: .public)")
            return nil
        }

        guard FileManager.default.fileExists(atPath: personalitiesPath.path) else {
            log.error("Personalities file not found at \(personalitiesPath.path, privacy: .public)")
            return nil
        }

        do {
            // Parse secrets TOML
            let secretsContent = try String(contentsOf: secretsPath, encoding: .utf8)
            let secretsTable = try TOMLTable(string: secretsContent)

            guard let apiKey = secretsTable["openai_api_key"]?.string else {
                log.error("openai_api_key not found in secrets file")
                return nil
            }

            // Parse personalities TOML
            let personalitiesContent = try String(contentsOf: personalitiesPath, encoding: .utf8)
            let personalitiesTable = try TOMLTable(string: personalitiesContent)

            guard let personalityArray = personalitiesTable["personality"]?.array else {
                log.error("No [[personality]] entries found in personalities file")
                return nil
            }

            var personalities: [Personality] = []
            for item in personalityArray {
                guard let table = item.table,
                      let name = table["name"]?.string,
                      let hotkey = table["hotkey"]?.string,
                      let prompt = table["prompt"]?.string else {
                    log.warning("Skipping invalid personality entry")
                    continue
                }
                personalities.append(Personality(name: name, hotkey: hotkey, prompt: prompt))
            }

            guard !personalities.isEmpty else {
                log.error("No valid personalities found")
                return nil
            }

            log.info("Config loaded successfully with \(personalities.count) personalities")
            return Config(openaiApiKey: apiKey, personalities: personalities)
        } catch {
            log.error("Failed to load config: \(error.localizedDescription)")
            return nil
        }
    }()
}

private func parseHotkey(_ str: String) -> (keyCode: UInt32, modifiers: UInt32) {
    let parts = str.lowercased().split(separator: "-").map(String.init)
    var modifiers: UInt32 = 0
    var keyCode: UInt32 = 0x28 // default to 'k'

    for part in parts {
        switch part {
        case "cmd", "command":
            modifiers |= UInt32(cmdKey)
        case "shift":
            modifiers |= UInt32(shiftKey)
        case "opt", "option", "alt":
            modifiers |= UInt32(optionKey)
        case "ctrl", "control":
            modifiers |= UInt32(controlKey)
        default:
            if let code = keyCodeMap[part] {
                keyCode = code
            }
        }
    }

    return (keyCode, modifiers)
}

private let keyCodeMap: [String: UInt32] = [
    "a": 0x00, "b": 0x0B, "c": 0x08, "d": 0x02, "e": 0x0E,
    "f": 0x03, "g": 0x05, "h": 0x04, "i": 0x22, "j": 0x26,
    "k": 0x28, "l": 0x25, "m": 0x2E, "n": 0x2D, "o": 0x1F,
    "p": 0x23, "q": 0x0C, "r": 0x0F, "s": 0x01, "t": 0x11,
    "u": 0x20, "v": 0x09, "w": 0x0D, "x": 0x07, "y": 0x10,
    "z": 0x06,
]
