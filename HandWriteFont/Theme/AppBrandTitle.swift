import SwiftUI

/// FontMaker のロゴ＋アプリ名（起動画面・ナビゲーションバー共通）
struct AppBrandTitle: View {
    enum Size {
        case navigation
        case large

        var logoSide: CGFloat {
            switch self {
            case .navigation: return 28
            case .large: return 96
            }
        }

        var logoCornerRadius: CGFloat {
            switch self {
            case .navigation: return 7
            case .large: return 22
            }
        }

        var fontSize: CGFloat {
            switch self {
            case .navigation: return 20
            case .large: return 36
            }
        }

        var spacing: CGFloat {
            switch self {
            case .navigation: return 8
            case .large: return 18
            }
        }
    }

    var size: Size = .navigation
    var showsLogo: Bool = true

    var body: some View {
        HStack(spacing: size.spacing) {
            if showsLogo {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size.logoSide, height: size.logoSide)
                    .clipShape(
                        RoundedRectangle(cornerRadius: size.logoCornerRadius, style: .continuous)
                    )
                    .shadow(color: AppTheme.accent.opacity(size == .large ? 0.28 : 0.18), radius: size == .large ? 14 : 4, y: 2)
            }

            HStack(spacing: 0) {
                Text("Font")
                    .font(.system(size: size.fontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.warmText.opacity(0.88))
                Text("Maker")
                    .font(.system(size: size.fontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.accent)
            }
            .tracking(size == .large ? 0.3 : 0.15)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("FontMaker")
    }
}

extension View {
    func appBrandNavigationTitle() -> some View {
        navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    AppBrandTitle(size: .navigation)
                }
            }
    }
}
