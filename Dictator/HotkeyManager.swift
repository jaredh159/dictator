import Carbon.HIToolbox
import Foundation

class HotkeyManager {
    private var hotkeyRefs: [UInt32: EventHotKeyRef] = [:]
    private var eventHandlerRef: EventHandlerRef?

    private static var handlers: [UInt32: () -> Void] = [:]

    func registerMultiple(hotkeys: [(id: UInt32, keyCode: UInt32, modifiers: UInt32, handler: () -> Void)]) {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, _) -> OSStatus in
                var hotkeyID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotkeyID
                )
                HotkeyManager.handlers[hotkeyID.id]?()
                return noErr
            },
            1,
            &eventType,
            nil,
            &eventHandlerRef
        )

        guard status == noErr else {
            print("Failed to install event handler: \(status)")
            return
        }

        for hotkey in hotkeys {
            HotkeyManager.handlers[hotkey.id] = hotkey.handler

            let hotkeyID = EventHotKeyID(signature: OSType(0x4454_4352), id: hotkey.id)
            var hotkeyRef: EventHotKeyRef?

            let registerStatus = RegisterEventHotKey(
                hotkey.keyCode,
                hotkey.modifiers,
                hotkeyID,
                GetApplicationEventTarget(),
                0,
                &hotkeyRef
            )

            if registerStatus == noErr, let ref = hotkeyRef {
                hotkeyRefs[hotkey.id] = ref
            } else {
                print("Failed to register hotkey \(hotkey.id): \(registerStatus)")
            }
        }
    }

    deinit {
        for (_, ref) in hotkeyRefs {
            UnregisterEventHotKey(ref)
        }
    }
}
