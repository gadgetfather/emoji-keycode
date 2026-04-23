import AppKit
import Foundation

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let permissions = PermissionsManager()
    private var statusItem: StatusItemController!
    private var settings: SettingsWindowController!
    private var engine: EmojiEngine?
    private var permissionTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let repository: EmojiRepository
        do {
            repository = try EmojiRepository.loadBundled()
        } catch {
            presentFatal("Could not load emoji database: \(error.localizedDescription)")
            NSApp.terminate(nil)
            return
        }

        let model = SettingsModel(
            axTrusted: permissions.isTrusted,
            autoReplace: true,
            popup: true
        )
        model.openAccessibility = { [weak self] in self?.permissions.openSystemSettingsAccessibility() }
        self.settings = SettingsWindowController(model: model)

        self.statusItem = StatusItemController()
        self.statusItem.onOpenSettings = { [weak self] in self?.settings.show() }
        self.statusItem.onQuit = { NSApp.terminate(nil) }
        self.statusItem.onToggleAutoReplace = { [weak self] in
            guard let self = self else { return }
            model.autoReplace.toggle()
            self.statusItem.setAutoReplace(model.autoReplace)
        }
        self.statusItem.onTogglePopup = { [weak self] in
            guard let self = self else { return }
            model.popup.toggle()
            self.statusItem.setPopup(model.popup)
        }

        let engine = EmojiEngine(repository: repository)
        engine.autoReplaceEnabled = model.autoReplace
        engine.popupEnabled = model.popup
        self.engine = engine

        model.onAutoReplaceChange = { [weak self] value in
            self?.engine?.autoReplaceEnabled = value
            self?.statusItem.setAutoReplace(value)
        }
        model.onPopupChange = { [weak self] value in
            self?.engine?.popupEnabled = value
            self?.statusItem.setPopup(value)
        }

        if permissions.isTrusted {
            activateEngine()
        } else {
            permissions.requestPrompt()
            statusItem.setTrusted(false)
            settings.show()
            startPermissionPolling()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        engine?.stop()
        permissionTimer?.invalidate()
    }

    private func activateEngine() {
        guard let engine = engine else { return }
        if engine.start() {
            statusItem.setTrusted(true)
            settings.model.axTrusted = true
            permissionTimer?.invalidate()
            permissionTimer = nil
        } else {
            statusItem.setTrusted(false)
            settings.model.axTrusted = false
            startPermissionPolling()
        }
    }

    private func startPermissionPolling() {
        permissionTimer?.invalidate()
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.permissions.isTrusted {
                self.activateEngine()
            } else {
                self.statusItem.setTrusted(false)
                self.settings.model.axTrusted = false
            }
        }
    }

    private func presentFatal(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "EmojiKeycode"
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

enum EmojiKeycodeApp {
    static func run() -> Int32 {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
        return 0
    }
}
