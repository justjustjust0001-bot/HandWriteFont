import SwiftUI

struct CharacterSectionHeader: View {
    let section: CharacterSection
    let savedCount: Int
    let totalCount: Int
    let isLocked: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(section.title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.warmText)
                Text("\(savedCount)/\(totalCount) 完了")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()

            if isLocked {
                Label("要サブスク", systemImage: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            } else {
                ProgressView(value: Double(savedCount), total: Double(max(totalCount, 1)))
                    .tint(AppTheme.accent)
                    .frame(width: 72)
            }
        }
        .padding(.vertical, 4)
    }
}
