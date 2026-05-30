import SwiftUI

@main
struct FontMakerApp: App {
    @StateObject private var projectService = FontProjectService()
    @StateObject private var subscription = SubscriptionService()
    @StateObject private var drawingSettings = DrawingSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(projectService)
                .environmentObject(subscription)
                .environmentObject(drawingSettings)
                .tint(AppTheme.accent)
        }
    }
}
