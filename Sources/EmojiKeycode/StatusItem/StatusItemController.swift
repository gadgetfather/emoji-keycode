import AppKit

final class StatusItemController {
    private let statusItem: NSStatusItem
    private let menu = NSMenu()
    var onOpenSettings: (() -> Void)?
    var onQuit: (() -> Void)?
    var onToggleAutoReplace: (() -> Void)?
    var onTogglePopup: (() -> Void)?

    private let autoReplaceItem = NSMenuItem(title: "Auto-replace on closing colon", action: #selector(toggleAutoReplace), keyEquivalent: "")
    private let popupItem = NSMenuItem(title: "Show suggestion popup", action: #selector(togglePopup), keyEquivalent: "")
    private let statusLine = NSMenuItem(title: "Starting…", action: nil, keyEquivalent: "")

    init() {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        configureMenu()
        setBadge(trusted: false)
        statusItem.menu = menu
    }

    func setTrusted(_ trusted: Bool) {
        setBadge(trusted: trusted)
        statusLine.title = trusted ? "Ready" : "Grant Accessibility to activate"
    }

    func setAutoReplace(_ on: Bool) {
        autoReplaceItem.state = on ? .on : .off
    }

    func setPopup(_ on: Bool) {
        popupItem.state = on ? .on : .off
    }

    private func configureMenu() {
        statusLine.isEnabled = false
        menu.addItem(statusLine)
        menu.addItem(.separator())

        autoReplaceItem.target = self
        autoReplaceItem.state = .on
        menu.addItem(autoReplaceItem)

        popupItem.target = self
        popupItem.state = .on
        menu.addItem(popupItem)

        menu.addItem(.separator())
        let settings = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)

        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit EmojiKeycode", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
    }

    private func setBadge(trusted: Bool) {
        guard let button = statusItem.button else { return }
        let image = NSImage(systemSymbolName: "face.smiling", accessibilityDescription: "EmojiKeycode")
        image?.isTemplate = true
        button.image = image
        if trusted {
            button.attributedTitle = NSAttributedString(string: "")
        } else {
            let dot = NSAttributedString(string: " ●", attributes: [.foregroundColor: NSColor.systemRed])
            button.attributedTitle = dot
        }
    }

    @objc private func openSettings() { onOpenSettings?() }
    @objc private func quit() { onQuit?() }
    @objc private func toggleAutoReplace() { onToggleAutoReplace?() }
    @objc private func togglePopup() { onTogglePopup?() }
}
