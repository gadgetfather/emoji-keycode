import XCTest
@testable import EmojiKeycode

final class InputBufferTests: XCTestCase {
    private func makeBuffer(timeout: TimeInterval = 10, now: @escaping () -> Date = Date.init) -> InputBuffer {
        let repo = EmojiRepository(entries: [
            EmojiEntry(emoji: "😄", names: ["smile"], tags: []),
            EmojiEntry(emoji: "❤️", names: ["heart"], tags: []),
            EmojiEntry(emoji: "👍", names: ["+1"], tags: []),
        ])
        return InputBuffer(repository: repo, timeout: timeout, now: now)
    }

    private func chars(_ s: String) -> [KeyInput] {
        s.map { .character($0) }
    }

    func testOpeningColonEntersCapture() {
        let buf = makeBuffer()
        let events = buf.handle(.character(":"))
        XCTAssertEqual(events, [.popupOpen(prefix: "")])
        XCTAssertTrue(buf.isCapturing)
        XCTAssertEqual(buf.currentPrefix, "")
    }

    func testTypeShortcodeThenColonReplaces() {
        let buf = makeBuffer()
        _ = buf.handle(.character(":"))
        for c in "smile" { _ = buf.handle(.character(c)) }
        XCTAssertEqual(buf.currentPrefix, "smile")
        let events = buf.handle(.character(":"))
        XCTAssertEqual(events, [
            .popupClose,
            .replace(shortcode: "smile", emoji: "😄", deleteCount: 7),
        ])
        XCTAssertFalse(buf.isCapturing)
    }

    func testUnknownShortcodeDoesNotReplace() {
        let buf = makeBuffer()
        _ = buf.handle(.character(":"))
        for c in "nonsense" { _ = buf.handle(.character(c)) }
        let events = buf.handle(.character(":"))
        XCTAssertEqual(events, [.popupClose])
        XCTAssertFalse(buf.isCapturing)
    }

    func testBackspaceShrinksBuffer() {
        let buf = makeBuffer()
        _ = buf.handle(.character(":"))
        _ = buf.handle(.character("s"))
        _ = buf.handle(.character("m"))
        let events = buf.handle(.backspace)
        XCTAssertEqual(events, [.popupUpdate(prefix: "s")])
        XCTAssertEqual(buf.currentPrefix, "s")
    }

    func testBackspaceFromEmptyExitsCapture() {
        let buf = makeBuffer()
        _ = buf.handle(.character(":"))
        let events = buf.handle(.backspace)
        XCTAssertEqual(events, [.popupClose])
        XCTAssertFalse(buf.isCapturing)
    }

    func testSpaceCancels() {
        let buf = makeBuffer()
        _ = buf.handle(.character(":"))
        _ = buf.handle(.character("s"))
        _ = buf.handle(.character("m"))
        let events = buf.handle(.commitSpace)
        XCTAssertEqual(events, [.popupClose])
        XCTAssertFalse(buf.isCapturing)
    }

    func testCmdChordCancels() {
        let buf = makeBuffer()
        _ = buf.handle(.character(":"))
        _ = buf.handle(.character("s"))
        let events = buf.handle(.character("a"), flags: [.command])
        XCTAssertEqual(events, [.popupClose])
        XCTAssertFalse(buf.isCapturing)
    }

    func testInvalidCharCancels() {
        let buf = makeBuffer()
        _ = buf.handle(.character(":"))
        _ = buf.handle(.character("s"))
        let events = buf.handle(.character("!"))
        XCTAssertEqual(events, [.popupClose])
        XCTAssertFalse(buf.isCapturing)
    }

    func testTimeoutResets() {
        var t = Date(timeIntervalSince1970: 1000)
        let buf = makeBuffer(timeout: 5, now: { t })
        _ = buf.handle(.character(":"))
        _ = buf.handle(.character("s"))
        t = t.addingTimeInterval(10)
        let events = buf.handle(.character("m"))
        XCTAssertTrue(events.contains(.popupClose))
    }

    func testPlusOneShortcode() {
        let buf = makeBuffer()
        _ = buf.handle(.character(":"))
        _ = buf.handle(.character("+"))
        _ = buf.handle(.character("1"))
        XCTAssertEqual(buf.currentPrefix, "+1")
        let events = buf.handle(.character(":"))
        XCTAssertTrue(events.contains(.replace(shortcode: "+1", emoji: "👍", deleteCount: 4)))
    }

    func testAutoReplaceDisabledKeepsBuffer() {
        let buf = makeBuffer()
        buf.autoReplaceEnabled = false
        _ = buf.handle(.character(":"))
        for c in "smile" { _ = buf.handle(.character(c)) }
        let events = buf.handle(.character(":"))
        XCTAssertEqual(events, [.popupClose])
        XCTAssertFalse(buf.isCapturing)
    }

    func testCommitSelectedDeletesOpenColonAndBuffer() {
        let buf = makeBuffer()
        _ = buf.handle(.character(":"))
        _ = buf.handle(.character("s"))
        _ = buf.handle(.character("m"))
        let events = buf.commitSelected(shortcode: "smile", emoji: "😄")
        XCTAssertEqual(events, [
            .popupClose,
            .replace(shortcode: "smile", emoji: "😄", deleteCount: 3),
        ])
    }

    func testPopupDisabledEmitsNoPopupEvents() {
        let buf = makeBuffer()
        buf.popupEnabled = false
        let e1 = buf.handle(.character(":"))
        XCTAssertTrue(e1.isEmpty)
        let e2 = buf.handle(.character("s"))
        XCTAssertTrue(e2.isEmpty)
    }
}
