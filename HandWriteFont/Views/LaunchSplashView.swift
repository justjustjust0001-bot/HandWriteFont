import SwiftUI

struct LaunchSplashView: View {
    @State private var contentOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.88
    @State private var taglineOffset: CGFloat = 8

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            // 背景の柔らかいグラデーション
            RadialGradient(
                colors: [
                    AppTheme.accentSoft.opacity(0.55),
                    AppTheme.background.opacity(0)
                ],
                center: .center,
                startRadius: 40,
                endRadius: 320
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                AppBrandTitle(size: .large)

                VStack(spacing: 10) {
                    Text("あなただけの、オリジナルなフォント")
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.regular)
                        .foregroundStyle(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .offset(y: taglineOffset)

                    ProgressView()
                        .tint(AppTheme.accent)
                        .scaleEffect(1.05)
                        .accessibilityLabel("読み込み中")
                }
            }
            .opacity(contentOpacity)
            .scaleEffect(logoScale)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                contentOpacity = 1
                logoScale = 1
                taglineOffset = 0
            }
        }
    }
}

#Preview {
    LaunchSplashView()
}
