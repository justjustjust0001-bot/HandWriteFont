import Foundation

enum OnboardingStorage {
    private static let completedKey = "FontMaker.hasCompletedOnboarding"

    static var hasCompleted: Bool {
        get { UserDefaults.standard.bool(forKey: completedKey) }
        set { UserDefaults.standard.set(newValue, forKey: completedKey) }
    }

    static func markCompleted() {
        hasCompleted = true
    }

    static func reset() {
        hasCompleted = false
    }
}
