import SwiftUI

/// アルファベット用の基準線。描画レイヤーの下に表示し、保存画像には含めない。
struct AlphabetGuideOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            ZStack {
                guideLine(
                    y: height * AlphabetGuideMetrics.capLine,
                    width: width,
                    label: "Cap"
                )
                guideLine(
                    y: height * AlphabetGuideMetrics.xHeightLine,
                    width: width,
                    label: "x"
                )
                guideLine(
                    y: height * AlphabetGuideMetrics.baseline,
                    width: width,
                    label: "Base",
                    emphasized: true
                )
                guideLine(
                    y: height * AlphabetGuideMetrics.descenderLine,
                    width: width,
                    label: "Desc"
                )
            }
        }
        .allowsHitTesting(false)
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
                emphasized ? Color.blue.opacity(0.55) : Color.gray.opacity(0.35),
                style: StrokeStyle(
                    lineWidth: emphasized ? 1.5 : 1,
                    dash: emphasized ? [] : [6, 4]
                )
            )

            Text(label)
                .font(.caption2)
                .foregroundStyle(emphasized ? Color.blue.opacity(0.7) : Color.gray.opacity(0.6))
                .padding(.leading, 8)
                .offset(y: y - 14)
        }
    }
}

enum AlphabetGuideMetrics {
    static let capLine: CGFloat = 0.18
    static let xHeightLine: CGFloat = 0.42
    static let baseline: CGFloat = 0.78
    static let descenderLine: CGFloat = 0.92
}

#Preview {
    AlphabetGuideOverlay()
        .frame(height: 320)
        .background(Color.white)
}
