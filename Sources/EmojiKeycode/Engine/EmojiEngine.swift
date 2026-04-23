import AppKit
import Carbon.HIToolbox
import CoreGraphics

final class EmojiEngine: KeyboardMonitorDelegate {
    private let repository: EmojiRepository
    private let monitor: KeyboardMonitor
    private let buffer: InputBuffer
    private let replacer: Replacer
    private let suggestion: SuggestionController

    var autoReplaceEnabled: Bool {
        get { buffer.autoReplaceEnabled }
        set { buffer.autoReplaceEnabled = newValue }
    }

    var popupEnabled: Bool {
        get { buffer.popupEnabled }
        set {
            buffer.popupEnabled = newValue
            if !newValue { suggestion.hide() }
        }
    }

    init(repository: EmojiRepository) {
        self.repository = repository
        self.monitor = KeyboardMonitor()
        self.buffer = InputBuffer(repository: repository)
        self.replacer = Replacer()
        self.suggestion = SuggestionController(repository: repository)
    }

    @discardableResult
    func start() -> Bool {
        monitor.delegate = self
        return monitor.start()
    }

    func stop() {
        monitor.stop()
        suggestion.hide()
    }

    func keyboard(_ monitor: KeyboardMonitor, receivedKey input: KeyInput, flags: KeyFlags, keyCode: CGKeyCode) -> KeyDecision {
        if suggestion.isVisible {
            switch Int(keyCode) {
            case kVK_UpArrow:
                suggestion.moveSelection(delta: -1)
                return .swallow
            case kVK_DownArrow:
                suggestion.moveSelection(delta: 1)
                return .swallow
            case kVK_Return, kVK_ANSI_KeypadEnter, kVK_Tab:
                if let match = suggestion.selectedMatch {
                    let events = buffer.commitSelected(shortcode: match.shortcode, emoji: match.emoji)
                    process(events)
                    return .swallow
                }
                suggestion.hide()
                _ = buffer.reset()
                return .pass
            case kVK_Escape:
                suggestion.hide()
                _ = buffer.reset()
                return .swallow
            default:
                break
            }
        }

        let events = buffer.handle(input, flags: flags)
        process(events)
        return .pass
    }

    func keyboardTapDisabled(_ monitor: KeyboardMonitor) {
        NSLog("EmojiEngine: event tap disabled; re-enabling")
        monitor.reenable()
    }

    private func process(_ events: [BufferEvent]) {
        for event in events {
            switch event {
            case .popupOpen(let prefix):
                if !prefix.isEmpty { suggestion.show(prefix: prefix) }
            case .popupUpdate(let prefix):
                if prefix.isEmpty {
                    suggestion.hide()
                } else {
                    suggestion.update(prefix: prefix)
                }
            case .popupClose:
                suggestion.hide()
            case .replace(_, let emoji, let deleteCount):
                replacer.replace(deleteCount: deleteCount, with: emoji)
            }
        }
    }
}
