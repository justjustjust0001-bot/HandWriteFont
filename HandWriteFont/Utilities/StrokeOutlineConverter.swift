import CoreGraphics

struct FontPoint: Equatable {
    let x: Int16
    let y: Int16
}

enum StrokeOutlineConverter {
    private static let unitsPerEm: CGFloat = 1024

    /// 手書きストロークをフォント座標系（y 上向き）の輪郭点列に変換する
    static func fontContours(
        from strokes: [DrawingStroke],
        canvasSize: CGSize,
        strokeWidth: CGFloat
    ) -> [[FontPoint]] {
        guard canvasSize.width > 0, canvasSize.height > 0, !strokes.isEmpty else {
            return []
        }

        let baseline = canvasSize.height * AlphabetGuideMetrics.baseline
        let scale = unitsPerEm / canvasSize.height

        var allContours: [[FontPoint]] = []

        for stroke in strokes where stroke.points.count > 1 {
            let width = stroke.resolvedWidth(fallback: strokeWidth)
            let path = StrokeSmoother.smoothedPath(from: stroke.points)
            let stroked = path.copy(
                strokingWithWidth: width,
                lineCap: .round,
                lineJoin: .round,
                miterLimit: 10
            )

            let canvasContours = CGPathContourExtractor.extractContours(from: stroked)
            let fontContours = canvasContours.map { contour in
                contour.map { point in
                    let x = Int16(clamping: (point.x * scale).rounded())
                    let y = Int16(clamping: ((baseline - point.y) * scale).rounded())
                    return FontPoint(x: x, y: y)
                }
            }.filter { $0.count >= 3 }

            allContours.append(contentsOf: fontContours)
        }

        return allContours
    }
}

private extension Int16 {
    init(clamping value: CGFloat) {
        let rounded = Int(clamping: Int(value.rounded()))
        self = Int16(clamping: rounded)
    }
}

private extension Int {
    init(clamping value: Int) {
        if value > Int(Int16.max) {
            self = Int(Int16.max)
        } else if value < Int(Int16.min) {
            self = Int(Int16.min)
        } else {
            self = value
        }
    }
}
