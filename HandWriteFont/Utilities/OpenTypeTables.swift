import Foundation

struct EncodedGlyphMetrics {
    let data: Data
    let pointCount: Int
    let contourCount: Int
    let minX: Int16
    let minY: Int16
    let maxX: Int16
    let maxY: Int16

    static func encode(contours: [[FontPoint]]) -> EncodedGlyphMetrics {
        let data = GlyfEncoder.encode(contours: contours)
        guard !contours.isEmpty else {
            return EncodedGlyphMetrics(
                data: data,
                pointCount: 0,
                contourCount: 0,
                minX: 0,
                minY: 0,
                maxX: 0,
                maxY: 0
            )
        }

        let points = contours.flatMap { $0 }
        return EncodedGlyphMetrics(
            data: data,
            pointCount: points.count,
            contourCount: contours.count,
            minX: points.map(\.x).min() ?? 0,
            minY: points.map(\.y).min() ?? 0,
            maxX: points.map(\.x).max() ?? 0,
            maxY: points.map(\.y).max() ?? 0
        )
    }
}

enum OpenTypeTables {
    static let unitsPerEm: UInt16 = 1024
    static let ascender: Int16 = 820
    static let descender: Int16 = -204
    static let advanceWidth: UInt16 = 1024

    static func makeHeadTable(useLongLoca: Bool, metrics: [EncodedGlyphMetrics], fontRevision: Float = 1.0) -> Data {
        let bounds = combinedBounds(metrics)
        var writer = BinaryWriter()
        writer.fixed32(1.0)
        writer.fixed32(fontRevision)
        writer.uint32(0)
        writer.uint32(0x5F0F3CF5)
        writer.uint16(0b0000_0000_0001_0001)
        writer.uint16(unitsPerEm)
        let macEpoch = Int64(Date().timeIntervalSince1970 - 978_307_200)
        writer.int64(macEpoch)
        writer.int64(macEpoch)
        writer.int16(bounds.minX)
        writer.int16(bounds.minY)
        writer.int16(bounds.maxX)
        writer.int16(bounds.maxY)
        writer.uint16(0)
        writer.uint16(1)
        writer.int16(1)
        writer.int16(useLongLoca ? 1 : 0)
        writer.int16(0)
        return writer.data
    }

    static func makeHheaTable(glyphCount: Int, metrics: [EncodedGlyphMetrics] = []) -> Data {
        let advanceWidthMax = advanceWidth
        let bearingMetrics = horizontalBearings(from: metrics)
        var writer = BinaryWriter()
        writer.fixed32(1.0)
        writer.int16(ascender)
        writer.int16(descender)
        writer.int16(0)
        writer.uint16(advanceWidthMax)
        writer.int16(bearingMetrics.minLeftSideBearing)
        writer.int16(bearingMetrics.minRightSideBearing)
        writer.int16(bearingMetrics.xMaxExtent)
        writer.int16(1) // caretSlopeRise
        writer.int16(0) // caretSlopeRun
        writer.int16(0) // caretOffset
        for _ in 0 ..< 4 { writer.int16(0) } // reserved
        writer.int16(0) // metricDataFormat
        writer.uint16(UInt16(glyphCount))
        return writer.data
    }

    private static func horizontalBearings(from metrics: [EncodedGlyphMetrics]) -> (
        minLeftSideBearing: Int16,
        minRightSideBearing: Int16,
        xMaxExtent: Int16
    ) {
        guard !metrics.isEmpty else {
            return (0, 0, Int16(advanceWidth))
        }

        var minLeft = Int16.max
        var minRight = Int16.max
        var maxExtent = Int16.min

        for metric in metrics {
            let leftSideBearing = metric.minX
            let rightSideBearing = Int16(advanceWidth) - metric.maxX
            minLeft = min(minLeft, leftSideBearing)
            minRight = min(minRight, rightSideBearing)
            let extent = Int(leftSideBearing) + Int(advanceWidth)
            maxExtent = max(maxExtent, clampInt16(extent))
        }

        return (
            minLeftSideBearing: minLeft == Int16.max ? 0 : minLeft,
            minRightSideBearing: minRight == Int16.max ? 0 : minRight,
            xMaxExtent: maxExtent == Int16.min ? Int16(advanceWidth) : maxExtent
        )
    }

    private static func clampInt16(_ value: Int) -> Int16 {
        if value > Int(Int16.max) { return Int16.max }
        if value < Int(Int16.min) { return Int16.min }
        return Int16(value)
    }

    static func makeHmtxTable(glyphCount: Int, metrics: [EncodedGlyphMetrics] = []) -> Data {
        var writer = BinaryWriter()
        for index in 0 ..< glyphCount {
            let leftSideBearing: Int16
            if index < metrics.count {
                leftSideBearing = metrics[index].minX
            } else {
                leftSideBearing = 0
            }
            writer.uint16(advanceWidth)
            writer.int16(leftSideBearing)
        }
        return writer.data
    }

    static func makeMaxpTable(glyphCount: Int, metrics: [EncodedGlyphMetrics]) -> Data {
        let maxPoints = metrics.map(\.pointCount).max() ?? 0
        let maxContours = metrics.map(\.contourCount).max() ?? 0
        var writer = BinaryWriter()
        writer.fixed32(1.0)
        writer.uint16(UInt16(glyphCount))
        writer.uint16(UInt16(min(maxPoints, Int(UInt16.max))))
        writer.uint16(UInt16(min(maxContours, Int(UInt16.max))))
        // maxCompositePoints … maxComponentDepth (11 fields)
        for _ in 0 ..< 11 { writer.uint16(0) }
        return writer.data
    }

    /// OS/2 version 4 (96 bytes)
    static func makeOS2Table(codepoints: [Int]) -> Data {
        var writer = BinaryWriter()
        writer.uint16(4)
        writer.int16(Int16(advanceWidth / 2))
        writer.uint16(400)
        writer.uint16(5)
        writer.uint16(0)
        for _ in 0 ..< 10 { writer.int16(0) }
        writer.int16(0)
        for _ in 0 ..< 10 { writer.uint8(0) }
        writer.uint32(0x0000_00DF)
        writer.uint32(0)
        writer.uint32(0)
        writer.uint32(0)
        writer.ascii("HWF ", length: 4)
        writer.uint16(0x0040)
        writer.uint16(UInt16(codepoints.first ?? 32))
        writer.uint16(UInt16(codepoints.last ?? 32))
        writer.int16(ascender)
        writer.int16(descender)
        writer.int16(0)
        writer.uint16(UInt16(max(Int(ascender), 0)))
        writer.uint16(UInt16(abs(Int(descender))))
        writer.uint32(1)
        writer.uint32(0)
        writer.int16(520)
        writer.int16(700)
        writer.uint16(0)
        writer.uint16(32)
        writer.uint16(1)
        return writer.data
    }

    static func makeCmapTable(codepoints: [Int]) -> Data {
        let windowsSubtable = makeCmapFormat4Subtable(codepoints: codepoints)
        let unicodeSubtable = makeCmapFormat4Subtable(codepoints: codepoints)

        let headerSize = 4 + 8 * 2
        let unicodeOffset = UInt32(headerSize)
        let paddedUnicodeLength = padLength(unicodeSubtable.count)
        let windowsOffset = UInt32(headerSize + paddedUnicodeLength)

        var writer = BinaryWriter()
        writer.uint16(0) // version
        writer.uint16(2) // numSubtables
        writer.uint16(0) // Unicode platform
        writer.uint16(3) // Unicode 2.0+
        writer.uint32(unicodeOffset)
        writer.uint16(3) // Windows platform
        writer.uint16(1) // Unicode BMP
        writer.uint32(windowsOffset)
        writer.bytes(padSubtable(unicodeSubtable))
        writer.bytes(padSubtable(windowsSubtable))
        return writer.data
    }

    private static func makeCmapFormat4Subtable(codepoints: [Int]) -> Data {
        let mapping = codepoints.enumerated()
            .map { ($0.element, $0.offset + 1) }
            .filter { $0.0 >= 0 && $0.0 <= Int(UInt16.max) }
            .sorted { $0.0 < $1.0 }

        var endCount: [UInt16] = []
        var startCount: [UInt16] = []
        var idDelta: [Int16] = []
        var rangeOffset: [UInt16] = []

        for (codepoint, glyphID) in mapping {
            endCount.append(UInt16(codepoint))
            startCount.append(UInt16(codepoint))
            idDelta.append(Int16(glyphID - codepoint))
            rangeOffset.append(0)
        }

        endCount.append(0xFFFF)
        startCount.append(0xFFFF)
        idDelta.append(1)
        rangeOffset.append(0)

        let segCount = UInt16(endCount.count)
        let segCountX2 = segCount * 2
        let entrySelector = UInt16(max(0, Int(floor(log2(Double(segCount))))))
        let searchRange = UInt16((1 << Int(entrySelector)) * 2)
        let rangeShift = segCountX2 &- searchRange
        let subtableLength = UInt16(16 + Int(segCount) * 8)

        var subtable = BinaryWriter()
        subtable.uint16(4)
        subtable.uint16(subtableLength)
        subtable.uint16(0)
        subtable.uint16(segCountX2)
        subtable.uint16(searchRange)
        subtable.uint16(entrySelector)
        subtable.uint16(rangeShift)
        for value in endCount { subtable.uint16(value) }
        subtable.uint16(0)
        for value in startCount { subtable.uint16(value) }
        for value in idDelta { subtable.int16(value) }
        for value in rangeOffset { subtable.uint16(value) }
        return subtable.data
    }

    private static func padLength(_ length: Int) -> Int {
        let remainder = length % 4
        return remainder == 0 ? length : length + (4 - remainder)
    }

    private static func padSubtable(_ data: Data) -> Data {
        let remainder = data.count % 4
        guard remainder != 0 else { return data }
        var padded = data
        padded.append(Data(repeating: 0, count: 4 - remainder))
        return padded
    }

    static func makeLocaTable(glyphDataList: [Data]) -> Data {
        var writer = BinaryWriter()
        var offset: UInt32 = 0
        for data in glyphDataList {
            writer.uint32(offset)
            offset += UInt32(data.count)
        }
        writer.uint32(offset)
        return writer.data
    }

    static func makeNameTable(
        fontName: String,
        disambiguator: String? = nil,
        versionString: String = "Version 1.000"
    ) -> Data {
        let psName = postScriptName(from: fontName, disambiguator: disambiguator)
        let familyName = displayFamilyName(from: fontName)
        let macFamilyName = macRomanFamilyName(from: fontName, disambiguator: disambiguator)
        let subfamilyName = "Regular"
        let fullName = "\(familyName) \(subfamilyName)"
        let macFullName = "\(macFamilyName) \(subfamilyName)"
        let uniqueID = "1.000;HWF ;\(psName)"
        let version = versionString

        var entries: [(UInt16, UInt16, UInt16, UInt16, String)] = [
            (1, 3, 1, 0x0409, familyName),
            (2, 3, 1, 0x0409, subfamilyName),
            (3, 3, 1, 0x0409, uniqueID),
            (4, 3, 1, 0x0409, fullName),
            (5, 3, 1, 0x0409, version),
            (6, 3, 1, 0x0409, psName),
            (16, 3, 1, 0x0409, familyName),
            (17, 3, 1, 0x0409, subfamilyName),
            (1, 1, 0, 0, macFamilyName),
            (2, 1, 0, 0, subfamilyName),
            (3, 1, 0, 0, uniqueID),
            (4, 1, 0, 0, macFullName),
            (5, 1, 0, 0, version),
            (6, 1, 0, 0, psName),
            (16, 1, 0, 0, macFamilyName),
            (17, 1, 0, 0, subfamilyName)
        ]

        // OpenType 推奨: platform → encoding → language → nameID の順
        entries.sort { lhs, rhs in
            if lhs.1 != rhs.1 { return lhs.1 < rhs.1 }
            if lhs.2 != rhs.2 { return lhs.2 < rhs.2 }
            if lhs.3 != rhs.3 { return lhs.3 < rhs.3 }
            return lhs.0 < rhs.0
        }

        var stringStorage = Data()
        var nameRecords = BinaryWriter()
        var offset: UInt16 = 0

        for (nameID, platform, encoding, language, value) in entries {
            let stringData = encodeNameString(value, platform: platform)
            nameRecords.uint16(platform)
            nameRecords.uint16(encoding)
            nameRecords.uint16(language)
            nameRecords.uint16(nameID)
            nameRecords.uint16(UInt16(stringData.count))
            nameRecords.uint16(offset)
            stringStorage.append(stringData)
            offset += UInt16(stringData.count)
        }

        var writer = BinaryWriter()
        writer.uint16(0)
        writer.uint16(UInt16(entries.count))
        writer.uint16(6 + UInt16(entries.count) * 12)
        writer.bytes(nameRecords.data)
        writer.bytes(stringStorage)
        return writer.data
    }

    private static func encodeNameString(_ value: String, platform: UInt16) -> Data {
        if platform == 1 {
            // Mac Roman: ASCII のみ（非 ASCII は PostScript 名と同様に除去済み）
            return Data(value.utf8)
        }
        var utf16BE = Data()
        for scalar in value.utf16 {
            var bigEndian = scalar.bigEndian
            withUnsafeBytes(of: &bigEndian) { utf16BE.append(contentsOf: $0) }
        }
        return utf16BE
    }

    static func makePostTable() -> Data {
        var writer = BinaryWriter()
        writer.fixed32(3.0)
        writer.int32(0)
        writer.int16(0)
        writer.int16(0)
        for _ in 0 ..< 5 { writer.uint32(0) }
        return writer.data
    }

    static func postScriptName(from fontName: String, disambiguator: String? = nil) -> String {
        let filtered = fontName.unicodeScalars.map { scalar -> String in
            if CharacterSet.alphanumerics.contains(scalar) {
                return String(scalar)
            }
            if scalar == "-" || scalar == "_" {
                return String(scalar)
            }
            return "-"
        }.joined()
        let collapsed = filtered.replacingOccurrences(
            of: "-{2,}",
            with: "-",
            options: .regularExpression
        ).trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        var base = collapsed.isEmpty ? "FontMaker" : collapsed
        if let disambiguator {
            let tag = sanitizedDisambiguator(disambiguator)
            if !tag.isEmpty {
                base = "\(base)-\(tag)"
            }
        }
        return base + "-Regular"
    }

    static func macRomanFamilyName(from fontName: String, disambiguator: String? = nil) -> String {
        postScriptName(from: fontName, disambiguator: disambiguator)
            .replacingOccurrences(of: "-Regular", with: "")
    }

    static func displayFamilyName(from fontName: String) -> String {
        let trimmed = fontName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "FontMaker" : trimmed
    }

    static func safeFileName(from fontName: String, ext: String, disambiguator: String? = nil) -> String {
        let ps = postScriptName(from: fontName, disambiguator: disambiguator)
        return "\(ps).\(ext)"
    }

    private static func sanitizedDisambiguator(_ value: String) -> String {
        let filtered = value.unicodeScalars.map { scalar -> String in
            CharacterSet.alphanumerics.contains(scalar) ? String(scalar) : ""
        }.joined()
        return String(filtered.prefix(8)).uppercased()
    }

    static func safeFileName(from fontName: String, ext: String) -> String {
        safeFileName(from: fontName, ext: ext, disambiguator: nil)
    }

    private static func combinedBounds(_ metrics: [EncodedGlyphMetrics]) -> (minX: Int16, minY: Int16, maxX: Int16, maxY: Int16) {
        guard !metrics.isEmpty else {
            return (0, descender, Int16(unitsPerEm), ascender)
        }
        return (
            metrics.map(\.minX).min() ?? 0,
            min(metrics.map(\.minY).min() ?? descender, descender),
            metrics.map(\.maxX).max() ?? Int16(unitsPerEm),
            max(metrics.map(\.maxY).max() ?? ascender, ascender)
        )
    }
}
