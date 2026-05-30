import CoreGraphics
import SwiftUI

@MainActor
final class DrawingSettings: ObservableObject {
    static let defaultWidth: CGFloat = 4
    static let widthRange: ClosedRange<CGFloat> = 1...20

    @Published var strokeWidth: CGFloat {
        didSet {
            let clamped = Self.clamp(strokeWidth)
            if clamped != strokeWidth {
                strokeWidth = clamped
                return
            }
            UserDefaults.standard.set(Double(strokeWidth), forKey: Self.storageKey)
        }
    }

    private static let storageKey = "FontMaker.strokeWidth"

    init() {
        let saved = UserDefaults.standard.double(forKey: Self.storageKey)
        strokeWidth = saved > 0 ? Self.clamp(CGFloat(saved)) : Self.defaultWidth
    }

    private static func clamp(_ value: CGFloat) -> CGFloat {
        min(max(value, widthRange.lowerBound), widthRange.upperBound)
    }
}
