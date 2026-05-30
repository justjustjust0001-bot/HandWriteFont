import SwiftUI

struct CharacterGridCell: View {
    let character: Character
    let isSaved: Bool
    let isLocked: Bool

    private var accessibilityDescription: String {
        var parts = [String(character)]
        if isLocked {
            parts.append("漢字パックが必要")
        }
        parts.append(isSaved ? "保存済み" : "未保存")
        return parts.joined(separator: "、")
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 4) {
                Text(String(character))
                    .font(.title2.monospaced())
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(isLocked ? AppTheme.secondaryText : AppTheme.warmText)

                Circle()
                    .fill(isSaved ? AppTheme.saved : AppTheme.accentSoft.opacity(0.6))
                    .frame(width: 8, height: 8)
                    .accessibilityHidden(true)
            }
            .padding(8)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSaved ? AppTheme.saved.opacity(0.55) : AppTheme.accentSoft, lineWidth: 1)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityDescription)

            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.secondaryText)
                    .padding(6)
                    .accessibilityHidden(true)
            }
        }
    }
}

#Preview {
    HStack {
        CharacterGridCell(character: "A", isSaved: true, isLocked: false)
        CharacterGridCell(character: "漢", isSaved: false, isLocked: true)
    }
    .padding()
    .background(AppTheme.background)
}
