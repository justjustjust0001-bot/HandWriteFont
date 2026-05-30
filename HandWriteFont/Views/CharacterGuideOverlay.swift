import SwiftUI

enum CharacterGuideStyle {
    case latin
    case japanese
    case digit
    case symbol

    static func style(for character: Character) -> CharacterGuideStyle {
        guard let scalar = character.unicodeScalars.first else { return .symbol }
        let value = scalar.value

        if character.isLetter, character.isASCII {
            return .latin
        }
        if character.isNumber {
            return .digit
        }
        if (0x3040 ... 0x309F).contains(value)
            || (0x30A0 ... 0x30FF).contains(value)
            || (0x4E00 ... 0x9FFF).contains(value) {
            return .japanese
        }
        return .symbol
    }
}

/// 文字種別の基準線。描画レイヤーの下に表示し、保存画像には含めない。
struct CharacterGuideOverlay: View {
    let style: CharacterGuideStyle

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            ZStack {
                switch style {
                case .latin:
                    latinGuides(width: width, height: height)
                case .japanese:
                    japaneseGuides(width: width, height: height)
                case .digit:
                    digitGuides(width: width, height: height)
                case .symbol:
                    symbolGuides(width: width, height: height)
                }
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func latinGuides(width: CGFloat, height: CGFloat) -> some View {
        guideLine(y: height * AlphabetGuideMetrics.capLine, width: width, label: "Cap")
        guideLine(y: height * AlphabetGuideMetrics.xHeightLine, width: width, label: "x")
        guideLine(y: height * AlphabetGuideMetrics.baseline, width: width, label: "Base", emphasized: true)
        guideLine(y: height * AlphabetGuideMetrics.descenderLine, width: width, label: "Desc")
    }

    @ViewBuilder
    private func japaneseGuides(width: CGFloat, height: CGFloat) -> some View {
        let inset = width * 0.10
        let box = CGRect(
            x: inset,
            y: height * JapaneseGuideMetrics.topLine,
            width: width - inset * 2,
            height: height * (JapaneseGuideMetrics.bottomLine - JapaneseGuideMetrics.topLine)
        )

        Path { path in
            path.addRect(box)
        }
        .stroke(AppTheme.guideSecondary.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))

        Path { path in
            path.move(to: CGPoint(x: width / 2, y: box.minY))
            path.addLine(to: CGPoint(x: width / 2, y: box.maxY))
        }
        .stroke(AppTheme.guideSecondary.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

        Path { path in
            path.move(to: CGPoint(x: box.minX, y: box.midY))
            path.addLine(to: CGPoint(x: box.maxX, y: box.midY))
        }
        .stroke(AppTheme.guideSecondary.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

        guideLine(
            y: height * AlphabetGuideMetrics.baseline,
            width: width,
            label: "Base",
            emphasized: true
        )
    }

    @ViewBuilder
    private func digitGuides(width: CGFloat, height: CGFloat) -> some View {
        guideLine(y: height * DigitGuideMetrics.topLine, width: width, label: "Top")
        guideLine(
            y: height * AlphabetGuideMetrics.baseline,
            width: width,
            label: "Base",
            emphasized: true
        )
        guideLine(y: height * DigitGuideMetrics.bottomLine, width: width, label: "Bottom")
    }

    @ViewBuilder
    private func symbolGuides(width: CGFloat, height: CGFloat) -> some View {
        Path { path in
            path.move(to: CGPoint(x: width / 2, y: height * 0.12))
            path.addLine(to: CGPoint(x: width / 2, y: height * 0.88))
        }
        .stroke(AppTheme.guideSecondary.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

        guideLine(
            y: height * AlphabetGuideMetrics.baseline,
            width: width,
            label: "Base",
            emphasized: true
        )
    }

    private func guideLine(
        y: CGFloat,
        width: CGFloat,
        label: String,
        emphasized: Bool = false
    ) -> some View {
        ZStack(alignment: .leading) {
            Path { path in
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: width, y: y))
            }
            .stroke(
                emphasized ? AppTheme.guidePrimary.opacity(0.65) : AppTheme.guideSecondary.opacity(0.40),
                style: StrokeStyle(
                    lineWidth: emphasized ? 1.5 : 1,
                    dash: emphasized ? [] : [6, 4]
                )
            )

            Text(label)
                .font(.caption2)
                .foregroundStyle(emphasized ? AppTheme.guidePrimary.opacity(0.85) : AppTheme.guideSecondary)
                .padding(.leading, 8)
                .offset(y: y - 14)
        }
    }
}

enum JapaneseGuideMetrics {
    static let topLine: CGFloat = 0.14
    static let bottomLine: CGFloat = 0.86
}

enum DigitGuideMetrics {
    static let topLine: CGFloat = 0.20
    static let bottomLine: CGFloat = 0.86
}
