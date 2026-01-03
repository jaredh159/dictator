# Dictator

macOS menu bar app for voice dictation using OpenAI APIs.

## Tech Stack

- Swift 5 / SwiftUI
- macOS 15+
- OpenAI Whisper API (transcription)
- OpenAI GPT-4o-mini (text cleanup)

## Project Structure

```
Dictator/
├── DictatorApp.swift      # App entry point
├── AppDelegate.swift      # Menu bar setup, hotkey registration, window management
├── ContentView.swift      # Main UI (recording states, transcription display)
├── AudioRecorder.swift    # Recording logic, orchestrates transcription + cleanup
├── WhisperService.swift   # OpenAI Whisper API client
├── TextCleanupService.swift # GPT-4o-mini text cleanup
├── HotkeyManager.swift    # Global hotkey (Carbon Events)
├── Config.swift           # Loads TOML config from ~/.config/dictator/
└── Info.plist             # App metadata, mic permission string
```

## Config

Config is split into two TOML files in `~/.config/dictator/`:

**`dictator.secrets.toml`** (not version controlled):
```toml
openai_api_key = "sk-..."
```

**`dictator.personalities.toml`** (version controlled via stow):
```toml
[[personality]]
name = "Claude"
hotkey = "cmd-shift-k"
prompt = """
Your cleanup prompt here...
"""

[[personality]]
name = "Slack"
hotkey = "cmd-shift-s"
prompt = """
Another prompt...
"""
```

Each personality has its own hotkey and cleanup prompt. Multiple personalities can be defined.

For dotfiles users: personalities file can live at `~/.dotfiles/dictator/.config/dictator/dictator.personalities.toml` and be stowed.

## Build

```bash
# Using just
just run

# Or open Dictator.xcodeproj in Xcode
```

## Key Patterns

- `AppDelegate` manages the menu bar icon and floating window
- `AudioRecorder` is an `@MainActor` `ObservableObject` that drives the UI state
- Services (`WhisperService`, `TextCleanupService`) are actors for thread safety
- Global hotkey uses Carbon `RegisterEventHotKey` API
- App runs as `LSUIElement` (no dock icon, menu bar only)

## Flow

1. User presses a personality's hotkey → window appears with personality label, recording starts
2. User presses same hotkey again → recording stops
3. Audio sent to Whisper API → raw transcription
4. Transcription sent to GPT-4o-mini with personality's prompt → cleaned text
5. Cleaned text copied to clipboard, window dismisses
