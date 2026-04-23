import XCTest
import CoreGraphics
@testable import EmojiKeycode

final class ReplacerTagTests: XCTestCase {
    func testTaggedEventRoundtrips() throws {
        let source = CGEventSource(stateID: .privateState)
        let event = try XCTUnwrap(CGEvent(keyboardEventSource: source, virtualKey: 51, keyDown: true))
        XCTAssertFalse(EventTagging.isOurs(event))
        EventTagging.tag(event)
        XCTAssertTrue(EventTagging.isOurs(event))
    }

    func testUntaggedEventNotOurs() throws {
        let source = CGEventSource(stateID: .privateState)
        let event = try XCTUnwrap(CGEvent(keyboardEventSource: source, virtualKey: 51, keyDown: true))
        XCTAssertFalse(EventTagging.isOurs(event))
    }
}
