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
        setupHotkey()
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
        menu.addItem(NSMenuItem(title: "Show Window (⌘⇧K)", action: #selector(showPopup), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    private func setupHotkey() {
        let (keyCode, modifiers) = Config.shared?.parsedHotkey ?? (0x28, UInt32(cmdKey | shiftKey))
        hotkeyManager = HotkeyManager()
        hotkeyManager?.register(keyCode: keyCode, modifiers: modifiers) { [weak self] in
            DispatchQueue.main.async {
                self?.handleHotkey()
            }
        }
    }

    @objc private func showPopup() {
        showWindowAndRecord()
    }

    private func handleHotkey() {
        if recorder.isRecording {
            recorder.stopRecording()
        } else {
            showWindowAndRecord()
        }
    }

    private func showWindowAndRecord() {
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
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 40),
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
