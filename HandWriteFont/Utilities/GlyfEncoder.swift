import Foundation

enum GlyfEncoder {
    /// TrueType simple glyph 形式で輪郭をエンコードする
    static func encode(contours: [[FontPoint]]) -> Data {
        guard !contours.isEmpty else {
            var writer = BinaryWriter()
            writer.int16(0)
            return writer.data
        }

        var points: [FontPoint] = []
        var endIndices: [UInt16] = []
        for contour in contours where !contour.isEmpty {
            points.append(contentsOf: contour)
            endIndices.append(UInt16(points.count - 1))
        }

        guard !points.isEmpty else {
            var writer = BinaryWriter()
            writer.int16(0)
            return writer.data
        }

        let xs = points.map(\.x)
        let ys = points.map(\.y)

        var writer = BinaryWriter()
        writer.int16(Int16(contours.count))
        writer.int16(xs.min() ?? 0)
        writer.int16(ys.min() ?? 0)
        writer.int16(xs.max() ?? 0)
        writer.int16(ys.max() ?? 0)
        for index in endIndices {
            writer.uint16(index)
        }
        writer.uint16(0) // instruction length

        var flagsList: [UInt8] = []
        var xEncodings: [AxisEncoding] = []
        var yEncodings: [AxisEncoding] = []
        var previousX: Int16 = 0
        var previousY: Int16 = 0

        for point in points {
            var flags: UInt8 = 0x01 // on-curve point
            let dx = Int(point.x) - Int(previousX)
            let dy = Int(point.y) - Int(previousY)
            xEncodings.append(axisEncoding(for: dx, sameFlag: 0x10, shortFlag: 0x02, flags: &flags))
            yEncodings.append(axisEncoding(for: dy, sameFlag: 0x20, shortFlag: 0x04, flags: &flags))
            flagsList.append(flags)
            previousX = point.x
            previousY = point.y
        }

        for flags in flagsList {
            writer.uint8(flags)
        }
        for encoding in xEncodings {
            writeAxisEncoding(encoding, writer: &writer)
        }
        for encoding in yEncodings {
            writeAxisEncoding(encoding, writer: &writer)
        }

        return writer.data
    }

    private static func writeAxisEncoding(_ encoding: AxisEncoding, writer: inout BinaryWriter) {
        switch encoding {
        case .none:
            break
        case .singleByte(let value):
            writer.uint8(value)
        case .int16(let value):
            writer.int16(value)
        }
    }

    private enum AxisEncoding {
        case none
        case singleByte(UInt8)
        case int16(Int16)
    }

    private static func axisEncoding(
        for delta: Int,
        sameFlag: UInt8,
        shortFlag: UInt8,
        flags: inout UInt8
    ) -> AxisEncoding {
        if delta == 0 {
            flags |= sameFlag
            return .none
        }

        if delta >= -250 && delta <= -1 {
            flags |= shortFlag
            return .singleByte(UInt8(-delta))
        }

        if delta >= 1 && delta <= 250 {
            flags |= shortFlag | sameFlag
            return .singleByte(UInt8(delta))
        }

        return .int16(Int16(clamping: delta))
    }
}

private extension Int16 {
    init(clamping value: Int) {
        if value > Int(Int16.max) {
            self = Int16.max
        } else if value < Int(Int16.min) {
            self = Int16.min
        } else {
            self = Int16(value)
        }
    }
}
