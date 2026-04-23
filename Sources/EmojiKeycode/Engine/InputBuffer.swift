import Foundation

enum BufferEvent: Equatable {
    case popupOpen(prefix: String)
    case popupUpdate(prefix: String)
    case popupClose
    case replace(shortcode: String, emoji: String, deleteCount: Int)
}

enum KeyInput: Equatable {
    case character(Character)
    case backspace
    case commitSpace
    case enter
    case escape
    case other
}

struct KeyFlags: OptionSet {
    let rawValue: Int
    static let command = KeyFlags(rawValue: 1 << 0)
    static let control = KeyFlags(rawValue: 1 << 1)
    static let option  = KeyFlags(rawValue: 1 << 2)

    var isChord: Bool {
        return contains(.command) || contains(.control) || contains(.option)
    }
}

final class InputBuffer {
    private enum State {
        case idle
        case capturing(buffer: String, startedAt: Date)
    }

    private var state: State = .idle
    private let repository: EmojiRepository
    private let timeout: TimeInterval
    private let now: () -> Date

    var autoReplaceEnabled: Bool = true
    var popupEnabled: Bool = true

    init(
        repository: EmojiRepository,
        timeout: TimeInterval = 10,
        now: @escaping () -> Date = Date.init
    ) {
        self.repository = repository
        self.timeout = timeout
        self.now = now
    }

    var isCapturing: Bool {
        if case .capturing = state { return true }
        return false
    }

    var currentPrefix: String? {
        if case .capturing(let buf, _) = state { return buf }
        return nil
    }

    @discardableResult
    func reset() -> [BufferEvent] {
        if case .capturing = state {
            state = .idle
            return [.popupClose]
        }
        return []
    }

    func handle(_ input: KeyInput, flags: KeyFlags = []) -> [BufferEvent] {
        if flags.isChord {
            return reset()
        }

        if case .capturing(_, let startedAt) = state,
           now().timeIntervalSince(startedAt) > timeout {
            state = .idle
            var events: [BufferEvent] = [.popupClose]
            events.append(contentsOf: handle(input, flags: flags))
            return events
        }

        switch (state, input) {
        case (.idle, .character(let c)) where c == ":":
            state = .capturing(buffer: "", startedAt: now())
            return popupEnabled ? [.popupOpen(prefix: "")] : []

        case (.idle, _):
            return []

        case (.capturing(let buf, _), .character(let c)) where c == ":":
            state = .idle
            if autoReplaceEnabled, let emoji = repository.lookup(buf) {
                let deleteCount = buf.utf16.count + 2
                return [.popupClose, .replace(shortcode: buf, emoji: emoji, deleteCount: deleteCount)]
            }
            return [.popupClose]

        case (.capturing(let buf, let ts), .character(let c)) where isShortcodeChar(c):
            let next = buf + String(c)
            state = .capturing(buffer: next, startedAt: ts)
            return popupEnabled ? [.popupUpdate(prefix: next)] : []

        case (.capturing(let buf, let ts), .backspace):
            if buf.isEmpty {
                state = .idle
                return [.popupClose]
            }
            let next = String(buf.dropLast())
            state = .capturing(buffer: next, startedAt: ts)
            return popupEnabled ? [.popupUpdate(prefix: next)] : []

        case (.capturing, .commitSpace),
             (.capturing, .enter),
             (.capturing, .escape),
             (.capturing, .other):
            state = .idle
            return [.popupClose]

        case (.capturing, .character):
            state = .idle
            return [.popupClose]
        }
    }

    func commitSelected(shortcode: String, emoji: String) -> [BufferEvent] {
        guard case .capturing(let buf, _) = state else { return [] }
        state = .idle
        let deleteCount = buf.utf16.count + 1
        return [.popupClose, .replace(shortcode: shortcode, emoji: emoji, deleteCount: deleteCount)]
    }

    private func isShortcodeChar(_ c: Character) -> Bool {
        guard let scalar = c.unicodeScalars.first, c.unicodeScalars.count == 1 else { return false }
        let v = scalar.value
        return (v >= 0x30 && v <= 0x39)
            || (v >= 0x41 && v <= 0x5A)
            || (v >= 0x61 && v <= 0x7A)
            || v == 0x5F
            || v == 0x2B
            || v == 0x2D
    }
}
