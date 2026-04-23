import AppKit
import SwiftUI
import Carbon.HIToolbox

final class SuggestionController {
    private let repository: EmojiRepository
    private let window: SuggestionWindow
    private var hostingView: NSHostingView<SuggestionListView>?

    private(set) var matches: [EmojiMatch] = []
    private(set) var selectedIndex: Int = 0
    private(set) var isVisible: Bool = false

    init(repository: EmojiRepository) {
        self.repository = repository
        self.window = SuggestionWindow()
    }

    var selectedMatch: EmojiMatch? {
        guard isVisible, matches.indices.contains(selectedIndex) else { return nil }
        return matches[selectedIndex]
    }

    func show(prefix: String) {
        let results = repository.search(prefix: prefix, limit: 8)
        if results.isEmpty {
            hide()
            return
        }
        self.matches = results
        self.selectedIndex = 0
        render()
        let anchor = CaretLocator.locate()
        window.show(at: anchor)
        isVisible = true
    }

    func update(prefix: String) {
        let results = repository.search(prefix: prefix, limit: 8)
        if results.isEmpty {
            hide()
            return
        }
        self.matches = results
        if selectedIndex >= results.count { selectedIndex = 0 }
        render()
        if !isVisible {
            let anchor = CaretLocator.locate()
            window.show(at: anchor)
            isVisible = true
        }
    }

    func hide() {
        window.hide()
        matches = []
        selectedIndex = 0
        isVisible = false
    }

    func moveSelection(delta: Int) {
        guard !matches.isEmpty else { return }
        let count = matches.count
        selectedIndex = ((selectedIndex + delta) % count + count) % count
        render()
    }

    private func render() {
        let view = SuggestionListView(matches: matches, selectedIndex: selectedIndex)
        if let hosting = hostingView {
            hosting.rootView = view
            let fitting = hosting.fittingSize
            window.setContentSize(NSSize(width: 260, height: fitting.height))
        } else {
            let hosting = NSHostingView(rootView: view)
            let fitting = hosting.fittingSize
            hosting.frame = NSRect(x: 0, y: 0, width: 260, height: fitting.height)
            window.contentView = hosting
            window.setContentSize(NSSize(width: 260, height: fitting.height))
            self.hostingView = hosting
        }
    }
}
