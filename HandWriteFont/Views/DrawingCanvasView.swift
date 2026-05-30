import SwiftUI

struct DrawingCanvasView: View {
    @Binding var strokes: [DrawingStroke]
    var strokeWidth: CGFloat
    var guideStyle: CharacterGuideStyle

    @State private var activeStrokeID: UUID?
    @State private var activePoints: [CGPoint] = []

    private let minimumPointDistance: CGFloat = 1.5

    var body: some View {
        GeometryReader { geometry in
            let displayScale = CanonicalCanvas.displayScale(for: geometry.size)

            ZStack {
                Color.white

                CharacterGuideOverlay(style: guideStyle)

                Canvas { context, _ in
                    for stroke in displayStrokes(displayScale: displayScale) where stroke.points.count > 1 {
                        drawStroke(stroke, in: &context)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .gesture(drawingGesture(in: geometry.size, displayScale: displayScale))
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func displayStrokes(displayScale: CGFloat) -> [DrawingStroke] {
        let displaySize = CGSize(
            width: CanonicalCanvas.size.width * displayScale,
            height: CanonicalCanvas.size.height * displayScale
        )
        var result = CanonicalCanvas.scale(strokes: strokes, from: CanonicalCanvas.size, to: displaySize)
        if !activePoints.isEmpty {
            result.append(
                DrawingStroke(
                    id: activeStrokeID ?? UUID(),
                    points: activePoints,
                    strokeWidth: strokeWidth * displayScale
                )
            )
        }
        return result
    }

    private func drawStroke(_ stroke: DrawingStroke, in context: inout GraphicsContext) {
        let path = Path(StrokeSmoother.smoothedPath(from: stroke.points))
        context.stroke(
            path,
            with: .color(.black),
            style: StrokeStyle(
                lineWidth: stroke.resolvedWidth(fallback: strokeWidth),
                lineCap: .round,
                lineJoin: .round
            )
        )
    }

    private func drawingGesture(in size: CGSize, displayScale: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                let displayPoint = clampedPoint(value.location, in: size)

                if activeStrokeID == nil {
                    activeStrokeID = UUID()
                    activePoints = [displayPoint]
                    return
                }

                guard shouldAppend(displayPoint) else { return }
                activePoints.append(displayPoint)
            }
            .onEnded { _ in
                guard activePoints.count >= 2, let strokeID = activeStrokeID else {
                    resetActiveStroke()
                    return
                }

                let displaySize = CGSize(
                    width: CanonicalCanvas.size.width * displayScale,
                    height: CanonicalCanvas.size.height * displayScale
                )
                let canonicalPoints = activePoints.map {
                    CanonicalCanvas.scale($0, from: displaySize, to: CanonicalCanvas.size)
                }

                strokes.append(
                    DrawingStroke(
                        id: strokeID,
                        points: canonicalPoints,
                        strokeWidth: strokeWidth
                    )
                )
                resetActiveStroke()
            }
    }

    private func shouldAppend(_ point: CGPoint) -> Bool {
        guard let last = activePoints.last else { return true }
        let dx = point.x - last.x
        let dy = point.y - last.y
        return (dx * dx + dy * dy) >= minimumPointDistance * minimumPointDistance
    }

    private func clampedPoint(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: min(max(point.x, 0), size.width),
            y: min(max(point.y, 0), size.height)
        )
    }

    private func resetActiveStroke() {
        activeStrokeID = nil
        activePoints = []
    }
}

#Preview {
    DrawingCanvasPreviewContainer()
}

private struct DrawingCanvasPreviewContainer: View {
    @State private var strokes: [DrawingStroke] = []

    var body: some View {
        DrawingCanvasView(strokes: $strokes, strokeWidth: 4, guideStyle: .latin)
            .padding()
    }
}
