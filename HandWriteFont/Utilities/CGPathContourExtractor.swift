import CoreGraphics

enum CGPathContourExtractor {
    /// CGPath をフラット化して輪郭ごとの点列に分解する
    static func extractContours(from path: CGPath, flatness: CGFloat = 0.8) -> [[CGPoint]] {
        var contours: [[CGPoint]] = []
        var current: [CGPoint] = []

        path.applyWithBlock { element in
            switch element.pointee.type {
            case .moveToPoint:
                if !current.isEmpty {
                    contours.append(current)
                    current = []
                }
                current.append(element.pointee.points[0])
            case .addLineToPoint:
                current.append(element.pointee.points[0])
            case .addQuadCurveToPoint:
                let start = current.last ?? element.pointee.points[0]
                let control = element.pointee.points[0]
                let end = element.pointee.points[1]
                current.append(contentsOf: flattenQuadCurve(from: start, control: control, to: end, flatness: flatness))
            case .addCurveToPoint:
                let start = current.last ?? element.pointee.points[0]
                let c1 = element.pointee.points[0]
                let c2 = element.pointee.points[1]
                let end = element.pointee.points[2]
                current.append(contentsOf: flattenCubicCurve(from: start, control1: c1, control2: c2, to: end, flatness: flatness))
            case .closeSubpath:
                if let first = current.first, let last = current.last, first != last {
                    current.append(first)
                }
                if !current.isEmpty {
                    contours.append(current)
                    current = []
                }
            @unknown default:
                break
            }
        }

        if !current.isEmpty {
            contours.append(current)
        }

        return contours.filter { $0.count >= 2 }
    }

    private static func flattenQuadCurve(
        from start: CGPoint,
        control: CGPoint,
        to end: CGPoint,
        flatness: CGFloat
    ) -> [CGPoint] {
        var points: [CGPoint] = []
        let steps = max(4, Int(hypot(end.x - start.x, end.y - start.y) / flatness))
        for step in 1 ... steps {
            let t = CGFloat(step) / CGFloat(steps)
            let oneMinusT = 1 - t
            let x = oneMinusT * oneMinusT * start.x + 2 * oneMinusT * t * control.x + t * t * end.x
            let y = oneMinusT * oneMinusT * start.y + 2 * oneMinusT * t * control.y + t * t * end.y
            points.append(CGPoint(x: x, y: y))
        }
        return points
    }

    private static func flattenCubicCurve(
        from start: CGPoint,
        control1: CGPoint,
        control2: CGPoint,
        to end: CGPoint,
        flatness: CGFloat
    ) -> [CGPoint] {
        var points: [CGPoint] = []
        let steps = max(6, Int(hypot(end.x - start.x, end.y - start.y) / flatness))
        for step in 1 ... steps {
            let t = CGFloat(step) / CGFloat(steps)
            let oneMinusT = 1 - t
            let x = oneMinusT * oneMinusT * oneMinusT * start.x
                + 3 * oneMinusT * oneMinusT * t * control1.x
                + 3 * oneMinusT * t * t * control2.x
                + t * t * t * end.x
            let y = oneMinusT * oneMinusT * oneMinusT * start.y
                + 3 * oneMinusT * oneMinusT * t * control1.y
                + 3 * oneMinusT * t * t * control2.y
                + t * t * t * end.y
            points.append(CGPoint(x: x, y: y))
        }
        return points
    }
}
