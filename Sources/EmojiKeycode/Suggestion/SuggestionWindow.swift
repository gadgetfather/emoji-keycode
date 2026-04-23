import AppKit
import SwiftUI

final class SuggestionWindow: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 260, height: 10),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        self.isFloatingPanel = true
        self.level = .popUpMenu
        self.hasShadow = true
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hidesOnDeactivate = false
        self.collectionBehavior = [.canJoinAllSpaces, .transient, .fullScreenAuxiliary, .ignoresCycle]
        self.animationBehavior = .none
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func show(at point: NSPoint) {
        guard let screen = NSScreen.screens.first(where: { NSMouseInRect(point, $0.frame, false) }) ?? NSScreen.main else {
            self.orderFrontRegardless()
            return
        }
        let size = self.frame.size
        var origin = NSPoint(x: point.x, y: point.y - size.height - 6)
        if origin.y < screen.visibleFrame.minY {
            origin.y = point.y + 22
        }
        if origin.x + size.width > screen.visibleFrame.maxX {
            origin.x = screen.visibleFrame.maxX - size.width - 8
        }
        if origin.x < screen.visibleFrame.minX {
            origin.x = screen.visibleFrame.minX + 8
        }
        self.setFrameOrigin(origin)
        self.orderFrontRegardless()
    }

    func hide() {
        self.orderOut(nil)
    }
}
