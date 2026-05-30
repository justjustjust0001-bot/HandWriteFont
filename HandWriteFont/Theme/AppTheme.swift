import SwiftUI

enum AppTheme {
    static let background = Color(red: 1.0, green: 0.97, blue: 0.94)
    static let card = Color(red: 1.0, green: 0.99, blue: 0.96)
    static let accent = Color(red: 0.91, green: 0.52, blue: 0.38)
    static let accentDeep = Color(red: 0.78, green: 0.40, blue: 0.30)
    static let accentSoft = Color(red: 0.96, green: 0.82, blue: 0.74)
    static let warmText = Color(red: 0.28, green: 0.22, blue: 0.20)
    static let secondaryText = Color(red: 0.50, green: 0.42, blue: 0.38)
    static let saved = Color(red: 0.52, green: 0.70, blue: 0.52)
    static let guidePrimary = Color(red: 0.85, green: 0.55, blue: 0.45)
    static let guideSecondary = Color(red: 0.80, green: 0.74, blue: 0.68)

    static let cardCornerRadius: CGFloat = 16
    static let buttonCornerRadius: CGFloat = 12
}

struct WarmCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
            .shadow(color: AppTheme.accent.opacity(0.08), radius: 8, y: 3)
    }
}

extension View {
    func warmCard() -> some View {
        modifier(WarmCardModifier())
    }
}
