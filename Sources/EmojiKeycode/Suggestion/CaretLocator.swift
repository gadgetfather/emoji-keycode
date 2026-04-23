import Foundation
import AppKit
import ApplicationServices

enum CaretLocator {
    static func locate() -> NSPoint {
        if let p = locateViaAX() {
            return p
        }
        if let p = locateViaFocusedWindow() {
            return p
        }
        return mouseFallback()
    }

    private static func locateViaAX() -> NSPoint? {
        let systemWide = AXUIElementCreateSystemWide()

        var focused: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(systemWide, kAXFocusedUIElementAttribute as CFString, &focused)
        guard result == .success, let focusedAny = focused else { return nil }
        let focusedElement = focusedAny as! AXUIElement

        var rangeValue: CFTypeRef?
        let rangeResult = AXUIElementCopyAttributeValue(focusedElement, kAXSelectedTextRangeAttribute as CFString, &rangeValue)
        guard rangeResult == .success, let rangeAny = rangeValue else { return nil }
        let axRange = rangeAny as! AXValue

        var boundsValue: CFTypeRef?
        let boundsResult = AXUIElementCopyParameterizedAttributeValue(
            focusedElement,
            kAXBoundsForRangeParameterizedAttribute as CFString,
            axRange,
            &boundsValue
        )
        guard boundsResult == .success, let boundsAny = boundsValue else { return nil }
        let axBounds = boundsAny as! AXValue

        var rect = CGRect.zero
        guard AXValueGetValue(axBounds, .cgRect, &rect) else { return nil }

        let screenHeight = NSScreen.screens.first(where: { $0.frame.origin == .zero })?.frame.height
            ?? NSScreen.main?.frame.height
            ?? 0
        let flippedY = screenHeight - (rect.origin.y + rect.size.height)
        return NSPoint(x: rect.origin.x, y: flippedY)
    }

    private static func locateViaFocusedWindow() -> NSPoint? {
        guard let window = NSApplication.shared.windows.first(where: { $0.isKeyWindow }) else {
            return nil
        }
        return NSPoint(x: window.frame.minX, y: window.frame.minY)
    }

    private static func mouseFallback() -> NSPoint {
        let location = NSEvent.mouseLocation
        return NSPoint(x: location.x, y: location.y - 24)
    }
}
