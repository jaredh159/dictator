# 💂 dictator

macos menu bar app for voice dictation. records your voice, transcribes with openai whisper, cleans up the text with gpt-4o-mini, and copies to clipboard.

## installation

1. clone the repo
2. open `Dictator.xcodeproj` in xcode
3. select your signing team in **Signing & Capabilities** (your personal team works fine)
4. build and run

## setup

create a config file at `~/.config/dictator.json`:

```json
{
  "openaiApiKey": "sk-your-key-here",
  "cleanupPrompt": "You are a light text editor. You receive raw transcriptions from a seasoned software engineer that were converted from audio to text. Your job is to do a very light cleanup:\n\n1. Add proper punctuation (periods, commas, etc.)\n2. Split the text into paragraphs at natural idea boundaries—use good granularity\n3. If something looks like a transcription error of a technical/software term, fix it (e.g., \"reacts\" → \"React\", \"know JS\" → \"Node.js\", \"get hub\" → \"GitHub\")\n4. Output as clean markdown\n\nIMPORTANT: Change as little as possible. Do NOT rephrase, summarize, or add content. Do NOT over-edit. Just punctuate, paragraph, and fix obvious transcription mistakes of technical terms. The engineer's voice and wording should remain intact.\n\nReturn ONLY the cleaned markdown, no explanations or preamble."
}
```

optional config keys:
- `hotkey`: customize the hotkey, e.g. `"cmd-shift-d"` or `"ctrl-opt-k"`. default is `"cmd-shift-k"`

## usage

- `cmd-shift-k` to summon the window and start recording
- `cmd-shift-k` again to stop recording
- transcription happens automatically
- cleaned text is copied to your clipboard
- window dismisses when done

the app runs in your menu bar. doesn't steal focus from your current app.

## requirements

- macos 15+
- openai api key with access to whisper and gpt-4o-mini

## microphone permissions

the app will request microphone access on first launch. if you don't see a prompt or recording isn't working:

1. open **System Settings → Privacy & Security → Microphone**
2. find Dictator in the list and enable it

if you previously denied permission, macos won't prompt again—you'll need to enable it manually in System Settings.
