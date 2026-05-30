import UIKit

enum DrawingRenderer {
    static let strokeColor = UIColor.black
    static let backgroundColor = UIColor.white

    /// 基準線を含めず、描画ストロークのみを画像としてレンダリングする
    static func renderImage(
        from strokes: [DrawingStroke],
        size: CGSize,
        fallbackStrokeWidth: CGFloat = DrawingSettings.defaultWidth
    ) -> UIImage? {
        guard size.width > 0, size.height > 0 else { return nil }

        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = true
        format.scale = 3

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let cgContext = context.cgContext
            cgContext.setStrokeColor(strokeColor.cgColor)
            cgContext.setLineCap(.round)
            cgContext.setLineJoin(.round)

            for stroke in strokes where !stroke.points.isEmpty {
                cgContext.setLineWidth(stroke.resolvedWidth(fallback: fallbackStrokeWidth))
                let path = StrokeSmoother.smoothedPath(from: stroke.points)
                cgContext.addPath(path)
                cgContext.strokePath()
            }
        }
    }
}
