import Carbon
import Foundation

enum GlobalHotKeyError: LocalizedError {
    case installHandlerFailed(OSStatus)
    case registerHotKeyFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case let .installHandlerFailed(status):
            return "Could not install the global hotkey handler (OSStatus \(status))."
        case let .registerHotKeyFailed(status):
            return "Could not register the global hotkey (OSStatus \(status))."
        }
    }
}

final class GlobalHotKey {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private let handler: () -> Void

    init(keyCode: UInt32, modifiers: UInt32, handler: @escaping () -> Void) throws {
        self.handler = handler

        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let userData = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else { return noErr }

                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                guard status == noErr, hotKeyID.id == 1 else {
                    return noErr
                }

                let hotKey = Unmanaged<GlobalHotKey>.fromOpaque(userData).takeUnretainedValue()
                hotKey.handler()
                return noErr
            },
            1,
            &eventSpec,
            userData,
            &eventHandlerRef
        )
        guard installStatus == noErr else {
            throw GlobalHotKeyError.installHandlerFailed(installStatus)
        }

        let hotKeyID = EventHotKeyID(signature: makeFourCharCode(from: "QDKT"), id: 1)
        let registerStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        guard registerStatus == noErr else {
            throw GlobalHotKeyError.registerHotKeyFailed(registerStatus)
        }
    }

    deinit {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
    }

}

private func makeFourCharCode(from string: String) -> OSType {
    string.utf8.reduce(0) { partialResult, byte in
        (partialResult << 8) + OSType(byte)
    }
}
