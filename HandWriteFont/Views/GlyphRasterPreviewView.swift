import SwiftUI

/// 保存済み PNG グリフを並べて試し打ちする（フォント登録不要）
struct GlyphRasterPreviewView: View {
    let text: String
    let glyphStorage: GlyphStorageService
    let fontSize: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: fontSize * 0.35) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                WrappingHStack(spacing: fontSize * 0.08) {
                    ForEach(Array(line.enumerated()), id: \.offset) { _, character in
                        glyphView(for: character)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var lines: [[Character]] {
        text.components(separatedBy: "\n").map { Array($0) }
    }

    @ViewBuilder
    private func glyphView(for character: Character) -> some View {
        if let image = glyphStorage.image(for: character) {
            Image(uiImage: image)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: fontSize, height: fontSize)
        } else if character.isWhitespace {
            Color.clear
                .frame(width: fontSize * 0.35, height: fontSize)
        } else {
            Text(String(character))
                .font(.system(size: fontSize * 0.75))
                .foregroundStyle(AppTheme.secondaryText)
                .frame(width: fontSize, height: fontSize)
        }
    }
}

/// 横方向に折り返す簡易レイアウト
private struct WrappingHStack: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var frames: [CGRect] = []

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), frames)
    }
}
