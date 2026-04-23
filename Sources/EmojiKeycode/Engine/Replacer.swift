import Foundation
import CoreGraphics

final class Replacer {
    private static let deleteKeyCode: CGKeyCode = 51
    private let source: CGEventSource?

    init() {
        self.source = CGEventSource(stateID: .privateState)
    }

    func replace(deleteCount: Int, with emoji: String) {
        for _ in 0..<deleteCount {
            postDelete()
        }
        postUnicode(emoji)
    }

    private func postDelete() {
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: Self.deleteKeyCode, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: Self.deleteKeyCode, keyDown: false)
        else { return }
        EventTagging.tag(down)
        EventTagging.tag(up)
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }

    private func postUnicode(_ string: String) {
        let utf16 = Array(string.utf16)
        guard !utf16.isEmpty,
              let down = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
        else { return }

        utf16.withUnsafeBufferPointer { buffer in
            if let base = buffer.baseAddress {
                down.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: base)
                up.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: base)
            }
        }
        EventTagging.tag(down)
        EventTagging.tag(up)
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }
}
