import Carbon.HIToolbox
import Foundation
import os.log

private let log = Logger(subsystem: "com.jaredh159.dictator", category: "Config")

struct Config: Codable {
    let openaiApiKey: String
    let cleanupPrompt: String?
    let hotkey: String?

    var parsedHotkey: (keyCode: UInt32, modifiers: UInt32) {
        parseHotkey(hotkey ?? "cmd-shift-k")
    }

    static let shared: Config? = {
        let configPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config")
            .appendingPathComponent("dictator.json")

        guard FileManager.default.fileExists(atPath: configPath.path) else {
            log.error("Config file not found at \(configPath.path, privacy: .public)")
            return nil
        }

        do {
            let data = try Data(contentsOf: configPath)
            let config = try JSONDecoder().decode(Config.self, from: data)
            log.info("Config loaded successfully")
            return config
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
