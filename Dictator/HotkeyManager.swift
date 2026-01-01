import Carbon.HIToolbox
import Foundation

class HotkeyManager {
    private var hotkeyRef: EventHotKeyRef?
    private var handler: (() -> Void)?

    private static var sharedHandler: (() -> Void)?

    func register(keyCode: UInt32, modifiers: UInt32, handler: @escaping () -> Void) {
        self.handler = handler
        HotkeyManager.sharedHandler = handler

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, _) -> OSStatus in
                HotkeyManager.sharedHandler?()
                return noErr
            },
            1,
            &eventType,
            nil,
            nil
        )

        guard status == noErr else {
            print("Failed to install event handler: \(status)")
            return
        }

        let hotkeyID = EventHotKeyID(signature: OSType(0x4454_4352), id: 1) // "DTCR"

        let registerStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )

        if registerStatus != noErr {
            print("Failed to register hotkey: \(registerStatus)")
        }
    }

    deinit {
        if let hotkeyRef = hotkeyRef {
            UnregisterEventHotKey(hotkeyRef)
        }
    }
}
