import Foundation
import AppKit
import CoreGraphics
import Carbon.HIToolbox

enum KeyDecision {
    case pass
    case swallow
}

protocol KeyboardMonitorDelegate: AnyObject {
    func keyboard(_ monitor: KeyboardMonitor, receivedKey input: KeyInput, flags: KeyFlags, keyCode: CGKeyCode) -> KeyDecision
    func keyboardTapDisabled(_ monitor: KeyboardMonitor)
}

final class KeyboardMonitor {
    weak var delegate: KeyboardMonitorDelegate?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    func start() -> Bool {
        guard eventTap == nil else { return true }
        let mask: CGEventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: KeyboardMonitor.callback,
            userInfo: selfPtr
        ) else {
            return false
        }
        self.eventTap = tap

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    func stop() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            self.runLoopSource = nil
        }
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            self.eventTap = nil
        }
    }

    func reenable() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
    }

    private static let callback: CGEventTapCallBack = { _, type, event, refcon in
        guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
        let monitor = Unmanaged<KeyboardMonitor>.fromOpaque(refcon).takeUnretainedValue()
        return monitor.handle(type: type, event: event)
    }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.keyboardTapDisabled(self)
            }
            return Unmanaged.passUnretained(event)

        case .keyDown:
            if EventTagging.isOurs(event) {
                return Unmanaged.passUnretained(event)
            }
            if IsSecureEventInputEnabled() {
                return Unmanaged.passUnretained(event)
            }
            return dispatchKeyDown(event)

        case .flagsChanged:
            return Unmanaged.passUnretained(event)

        default:
            return Unmanaged.passUnretained(event)
        }
    }

    private func dispatchKeyDown(_ event: CGEvent) -> Unmanaged<CGEvent>? {
        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = translateFlags(event.flags)
        let input = translateInput(event: event, keyCode: keyCode, flags: flags)

        guard let delegate = delegate else {
            return Unmanaged.passUnretained(event)
        }
        let decision = delegate.keyboard(self, receivedKey: input, flags: flags, keyCode: keyCode)
        switch decision {
        case .pass:
            return Unmanaged.passUnretained(event)
        case .swallow:
            return nil
        }
    }

    private func translateFlags(_ cgFlags: CGEventFlags) -> KeyFlags {
        var out: KeyFlags = []
        if cgFlags.contains(.maskCommand) { out.insert(.command) }
        if cgFlags.contains(.maskControl) { out.insert(.control) }
        if cgFlags.contains(.maskAlternate) { out.insert(.option) }
        return out
    }

    private func translateInput(event: CGEvent, keyCode: CGKeyCode, flags: KeyFlags) -> KeyInput {
        switch Int(keyCode) {
        case kVK_Delete, kVK_ForwardDelete:
            return .backspace
        case kVK_Return, kVK_ANSI_KeypadEnter:
            return .enter
        case kVK_Escape:
            return .escape
        case kVK_Space:
            return .commitSpace
        case kVK_Tab:
            return .other
        case kVK_LeftArrow, kVK_RightArrow, kVK_UpArrow, kVK_DownArrow:
            return .other
        default:
            break
        }

        var length: Int = 0
        var buf = [UniChar](repeating: 0, count: 8)
        event.keyboardGetUnicodeString(maxStringLength: buf.count, actualStringLength: &length, unicodeString: &buf)
        guard length > 0 else { return .other }
        let str = String(utf16CodeUnits: buf, count: length)
        guard let first = str.first else { return .other }
        return .character(first)
    }
}
