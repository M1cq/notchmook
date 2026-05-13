import AppKit
import Carbon

enum MediaKeyService {
    enum Command {
        case playPause
        case next
        case previous

        var keyType: Int32 {
            switch self {
            case .playPause: Int32(NX_KEYTYPE_PLAY)
            case .next: Int32(NX_KEYTYPE_FAST)
            case .previous: Int32(NX_KEYTYPE_REWIND)
            }
        }
    }

    static func send(_ command: Command) {
        post(command, isKeyDown: true)
        post(command, isKeyDown: false)
    }

    private static func post(_ command: Command, isKeyDown: Bool) {
        let flags = NSEvent.ModifierFlags(rawValue: 0xA00)
        let keyState = isKeyDown ? 0xA : 0xB
        let data1 = (Int(command.keyType) << 16) | (keyState << 8)

        let event = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: flags,
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: data1,
            data2: -1
        )

        event?.cgEvent?.post(tap: .cghidEventTap)
    }
}
