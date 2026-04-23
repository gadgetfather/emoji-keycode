import Foundation
import CoreGraphics

enum EventTagging {
    static let sentinel: Int64 = 0x454D_4F4A_4931_3233

    static func tag(_ event: CGEvent) {
        event.setIntegerValueField(.eventSourceUserData, value: sentinel)
    }

    static func isOurs(_ event: CGEvent) -> Bool {
        event.getIntegerValueField(.eventSourceUserData) == sentinel
    }
}
