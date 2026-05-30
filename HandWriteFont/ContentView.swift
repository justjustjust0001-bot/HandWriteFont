import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var subscription: SubscriptionService
    @Environment(\.scenePhase) private var scenePhase

    @State private var showSplash = true
    @State private var showOnboarding = false

    var body: some View {
        ZStack {
            NavigationStack {
                CharacterListView()
            }
            .opacity(isMainVisible ? 1 : 0)
            .allowsHitTesting(isMainVisible)
            .accessibilityHidden(!isMainVisible)

            if showOnboarding {
                OnboardingTutorialView {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        showOnboarding = false
                    }
                }
                .transition(.opacity)
                .zIndex(2)
            }

            if showSplash {
                LaunchSplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .task(id: showSplash) {
            guard showSplash else { return }
            async let minimumDisplay: Void = {
                try? await Task.sleep(for: .seconds(1.4))
            }()
            async let refresh: Void = {
                await subscription.refreshEntitlements()
            }()
            _ = await (minimumDisplay, refresh)
            withAnimation(.easeInOut(duration: 0.35)) {
                showSplash = false
                if !OnboardingStorage.hasCompleted {
                    showOnboarding = true
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active, isMainVisible {
                Task { await subscription.refreshEntitlements() }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showOnboardingTutorial)) { _ in
            withAnimation(.easeInOut(duration: 0.35)) {
                showOnboarding = true
            }
        }
    }

    private var isMainVisible: Bool {
        !showSplash && !showOnboarding
    }
}

#Preview {
    ContentView()
        .environmentObject(FontProjectService())
        .environmentObject(SubscriptionService())
        .environmentObject(DrawingSettings())
}
