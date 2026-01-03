import AppKit
import SwiftUI
import Carbon.HIToolbox

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popupWindow: NSWindow?
    private var hotkeyManager: HotkeyManager?
    private let recorder = AudioRecorder()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupHotkeys()
        recorder.onComplete = { [weak self] in
            self?.popupWindow?.orderOut(nil)
        }
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "Dictator")
        }

        let menu = NSMenu()
        if let personalities = Config.shared?.personalities {
            for personality in personalities {
                let hotkeyDisplay = personality.hotkey
                    .replacingOccurrences(of: "cmd", with: "⌘")
                    .replacingOccurrences(of: "shift", with: "⇧")
                    .replacingOccurrences(of: "opt", with: "⌥")
                    .replacingOccurrences(of: "ctrl", with: "⌃")
                    .replacingOccurrences(of: "-", with: "")
                    .uppercased()
                menu.addItem(NSMenuItem(
                    title: "\(personality.name) (\(hotkeyDisplay))",
                    action: nil,
                    keyEquivalent: ""
                ))
            }
            menu.addItem(NSMenuItem.separator())
        }
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    private func setupHotkeys() {
        guard let personalities = Config.shared?.personalities else { return }

        hotkeyManager = HotkeyManager()
        var hotkeys: [(id: UInt32, keyCode: UInt32, modifiers: UInt32, handler: () -> Void)] = []

        for (index, personality) in personalities.enumerated() {
            let (keyCode, modifiers) = personality.parsedHotkey
            hotkeys.append((
                id: UInt32(index + 1),
                keyCode: keyCode,
                modifiers: modifiers,
                handler: { [weak self] in
                    DispatchQueue.main.async {
                        self?.handleHotkey(for: personality)
                    }
                }
            ))
        }

        hotkeyManager?.registerMultiple(hotkeys: hotkeys)
    }

    private func handleHotkey(for personality: Personality) {
        if recorder.isRecording {
            recorder.stopRecording()
        } else {
            showWindowAndRecord(with: personality)
        }
    }

    private func showWindowAndRecord(with personality: Personality) {
        recorder.currentPersonality = personality

        if popupWindow == nil {
            createPopupWindow()
        }

        if let window = popupWindow {
            positionWindowAtBottom()
            window.orderFrontRegardless()
        }

        if !recorder.isRecording && !recorder.isTranscribing && !recorder.isCleaningUp {
            recorder.startRecording()
        }
    }

    private func createPopupWindow() {
        let contentView = ContentView(recorder: recorder)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 240, height: 40),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true

        let hostingView = NSHostingView(rootView: contentView)
        hostingView.wantsLayer = true
        hostingView.layer?.cornerRadius = 12
        hostingView.layer?.masksToBounds = true
        hostingView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        window.contentView = hostingView
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.isMovableByWindowBackground = true

        popupWindow = window
    }

    private func positionWindowAtBottom() {
        guard let window = popupWindow, let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let windowFrame = window.frame
        let x = screenFrame.midX - windowFrame.width / 2
        let y = screenFrame.minY + 60
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
