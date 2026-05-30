import CoreGraphics

enum StrokeSmoother {
    /// 隣接する点の中点を通る二次ベジェ曲線で滑らかなパスを生成する
    static func smoothedPath(from points: [CGPoint]) -> CGPath {
        let path = CGMutablePath()
        guard let first = points.first else { return path }

        if points.count == 1 {
            path.addEllipse(in: CGRect(x: first.x - 1, y: first.y - 1, width: 2, height: 2))
            return path
        }

        if points.count == 2 {
            path.move(to: points[0])
            path.addLine(to: points[1])
            return path
        }

        path.move(to: first)

        for index in 1 ..< points.count - 1 {
            let current = points[index]
            let next = points[index + 1]
            let midPoint = CGPoint(
                x: (current.x + next.x) * 0.5,
                y: (current.y + next.y) * 0.5
            )
            path.addQuadCurve(to: midPoint, control: current)
        }

        if let last = points.last {
            path.addLine(to: last)
        }

        return path
    }
}
