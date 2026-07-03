import Carbon
import AppKit

class HotKeyManager {
    static let shared = HotKeyManager()
    private static let signature = UInt32(1297372499) // 'MOUS'

    private var actions: [UInt32: () -> Void] = [:]
    private var nextID: UInt32 = 1
    private var handlerInstalled = false
    private var handler: EventHandlerRef?

    func register(keyCode: Int, modifiers: UInt32, block: @escaping () -> Void) {
        let currentID = nextID
        actions[currentID] = block
        nextID += 1

        if !handlerInstalled {
            setupEventHandler()
        }

        let hotKeyID = EventHotKeyID(signature: HotKeyManager.signature, id: currentID)
        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(UInt32(keyCode), modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)

        if status != noErr {
            print("Failed to register hotkey with ID \(currentID): \(status)")
        }
    }

    private func setupEventHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let selfPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        let status = InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, theEvent, userData) -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }
            let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()

            var hotKeyID = EventHotKeyID()
            let err = GetEventParameter(theEvent, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)

            if err == noErr && hotKeyID.signature == HotKeyManager.signature {
                if let action = manager.actions[hotKeyID.id] {
                    action()
                    return OSStatus(noErr)
                }
            }

            return OSStatus(eventNotHandledErr)
        }, 1, &eventType, selfPtr, &handler)

        if status == noErr {
            handlerInstalled = true
        } else {
            print("Failed to install event handler: \(status)")
        }
    }
}
