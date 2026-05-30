import CoreGraphics

/// 端末ごとの表示サイズ差を吸収するため、保存・出力は固定論理サイズで行う。
enum CanonicalCanvas {
    static let size = CGSize(width: 512, height: 512)

    static func scale(_ point: CGPoint, from source: CGSize, to target: CGSize) -> CGPoint {
        guard source.width > 0, source.height > 0, target.width > 0, target.height > 0 else {
            return point
        }
        return CGPoint(
            x: point.x * target.width / source.width,
            y: point.y * target.height / source.height
        )
    }

    static func scaleFactor(from source: CGSize, to target: CGSize) -> CGFloat {
        guard source.width > 0, source.height > 0, target.width > 0, target.height > 0 else {
            return 1
        }
        return min(target.width / source.width, target.height / source.height)
    }

    static func scale(strokes: [DrawingStroke], from source: CGSize, to target: CGSize) -> [DrawingStroke] {
        let factor = scaleFactor(from: source, to: target)
        guard abs(factor - 1) > 0.0001 else { return strokes }

        return strokes.map { stroke in
            var copy = stroke
            copy.points = stroke.points.map { scale($0, from: source, to: target) }
            let baseWidth = stroke.resolvedWidth(fallback: stroke.strokeWidth)
            copy.strokeWidth = baseWidth * factor
            return copy
        }
    }

    static func normalize(
        strokes: [DrawingStroke],
        from source: CGSize,
        strokeWidth: CGFloat
    ) -> (strokes: [DrawingStroke], strokeWidth: CGFloat) {
        let factor = scaleFactor(from: source, to: size)
        let normalized = scale(strokes: strokes, from: source, to: size)
        return (normalized, strokeWidth * factor)
    }

    static func displayScale(for displaySize: CGSize) -> CGFloat {
        guard displaySize.width > 0 else { return 1 }
        return displaySize.width / size.width
    }
}
