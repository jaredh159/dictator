# 💂 dictator

macos menu bar app for voice dictation. records your voice, transcribes with openai
whisper, cleans up the text with gpt-4o-mini, and copies to clipboard.

## installation

1. clone the repo
2. open `Dictator.xcodeproj` in xcode
3. select your signing team in **Signing & Capabilities** (your personal team works fine)
4. build and run

## setup

create two config files in `~/.config/dictator/`:

**`dictator.secrets.toml`** (your api key):
```toml
openai_api_key = "sk-your-key-here"
```

**`dictator.personalities.toml`** (your personalities):
```toml
[[personality]]
name = "Claude"
hotkey = "cmd-shift-k"
prompt = """
You are a light text editor. You receive raw transcriptions from a seasoned
software engineer that were converted from audio to text. Your job is to do
a very light cleanup...
"""

[[personality]]
name = "Slack"
hotkey = "cmd-shift-s"
prompt = """
Another cleanup prompt here...
"""
```

each personality has:

- `name`: displayed in the window while recording
- `hotkey`: unique hotkey to trigger this personality (e.g. `"cmd-shift-k"`,
  `"ctrl-opt-d"`)
- `prompt`: the system prompt sent to gpt-4o-mini for text cleanup

for dotfiles users: the personalities file can be stowed from
`~/.dotfiles/dictator/.config/dictator/dictator.personalities.toml`

## usage

- press a personality's hotkey to summon the window and start recording
- press the same hotkey again to stop recording
- transcription happens automatically
- cleaned text is copied to your clipboard
- window dismisses when done

the app runs in your menu bar. doesn't steal focus from your current app.

## requirements

- macos 15+
- openai api key with access to whisper and gpt-4o-mini

## microphone permissions

the app will request microphone access on first launch. if you don't see a prompt or
recording isn't working:

1. open **System Settings → Privacy & Security → Microphone**
2. find Dictator in the list and enable it

if you previously denied permission, macos won't prompt again—you'll need to enable it
manually in System Settings.
