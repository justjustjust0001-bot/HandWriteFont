import Foundation
import UIKit

struct FontGlyphSource {
    let character: Character
    let pngData: Data
}

enum FontExportFormat: String, CaseIterable, Identifiable {
    case ttf

    var id: String { rawValue }

    var fileExtension: String { rawValue }

    var displayName: String {
        "TrueType (.ttf)"
    }
}

/// PNG ビットマップを sbix テーブルに埋め込んだ OpenType/TrueType フォントを生成する
enum SbixFontBuilder {
    private static let unitsPerEm: UInt16 = 1024
    private static let ascender: Int16 = 820
    private static let descender: Int16 = -204
    private static let ppem: UInt16 = 128
    private static let advanceWidth: UInt16 = 1024
    private static let bitmapSize = 128

    static func build(
        fontName: String,
        disambiguator: String? = nil,
        glyphs: [FontGlyphSource],
        metadata: FontBuildMetadata = .default
    ) throws -> Data {
        guard !glyphs.isEmpty else {
            throw FontExportError.noGlyphs
        }

        let sortedGlyphs = glyphs.sorted {
            ($0.character.unicodeScalars.first?.value ?? 0) < ($1.character.unicodeScalars.first?.value ?? 0)
        }

        let glyphCount = sortedGlyphs.count + 1 // .notdef
        let codepoints = sortedGlyphs.map { Int($0.character.unicodeScalars.first?.value ?? 0) }

        var tables: [FontTable] = []
        let emptyMetrics = Array(repeating: EncodedGlyphMetrics.encode(contours: []), count: glyphCount)
        tables.append(FontTable(tag: "head", data: OpenTypeTables.makeHeadTable(
            useLongLoca: false,
            metrics: emptyMetrics,
            fontRevision: metadata.fontRevision
        )))
        tables.append(FontTable(tag: "hhea", data: OpenTypeTables.makeHheaTable(glyphCount: glyphCount)))
        tables.append(FontTable(tag: "maxp", data: OpenTypeTables.makeMaxpTable(
            glyphCount: glyphCount,
            metrics: emptyMetrics
        )))
        tables.append(FontTable(tag: "OS/2", data: OpenTypeTables.makeOS2Table(codepoints: codepoints)))
        tables.append(FontTable(tag: "hmtx", data: OpenTypeTables.makeHmtxTable(glyphCount: glyphCount)))
        tables.append(FontTable(tag: "cmap", data: OpenTypeTables.makeCmapTable(codepoints: codepoints)))
        tables.append(FontTable(tag: "loca", data: makeLocaTable(glyphCount: glyphCount)))
        tables.append(FontTable(tag: "glyf", data: makeGlyfTable(glyphCount: glyphCount)))
        tables.append(FontTable(tag: "name", data: OpenTypeTables.makeNameTable(
            fontName: fontName,
            disambiguator: disambiguator,
            versionString: metadata.versionString
        )))
        tables.append(FontTable(tag: "post", data: makePostTable()))
        tables.append(FontTable(tag: "sbix", data: makeSbixTable(glyphs: sortedGlyphs)))

        return TrueTypeFontAssembler.assemble(tables: tables)
    }

    static func normalizedPNGData(from image: UIImage) -> Data? {
        let size = CGSize(width: bitmapSize, height: bitmapSize)
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = true
        format.scale = 1

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let normalized = renderer.image { _ in
            UIColor.white.setFill()
            UIBezierPath(rect: CGRect(origin: .zero, size: size)).fill()
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return normalized.pngData()
    }

    // MARK: - Table builders

    private static func makeLocaTable(glyphCount: Int) -> Data {
        var writer = BinaryWriter()
        for index in 0 ... glyphCount {
            writer.uint16(UInt16(index))
        }
        return writer.data
    }

    private static func makeGlyfTable(glyphCount: Int) -> Data {
        var writer = BinaryWriter()
        for _ in 0 ..< glyphCount {
            writer.int16(0) // empty glyph (numberOfContours = 0)
        }
        return writer.data
    }

    private static func makeNameTable(fontName: String) -> Data {
        let strings: [(UInt16, String)] = [
            (1, fontName),
            (2, "Regular"),
            (4, fontName),
            (6, fontName)
        ]

        var stringStorage = Data()
        var nameRecords = BinaryWriter()
        var offset: UInt16 = 0

        for (nameID, value) in strings {
            var utf16BE = Data()
            for scalar in value.utf16 {
                var bigEndian = scalar.bigEndian
                withUnsafeBytes(of: &bigEndian) { utf16BE.append(contentsOf: $0) }
            }
            nameRecords.uint16(3) // platform Unicode
            nameRecords.uint16(1) // encoding
            nameRecords.uint16(0x0409) // language en-US
            nameRecords.uint16(nameID)
            nameRecords.uint16(UInt16(utf16BE.count))
            nameRecords.uint16(offset)
            stringStorage.append(utf16BE)
            offset += UInt16(utf16BE.count)
        }

        var writer = BinaryWriter()
        writer.uint16(0)
        writer.uint16(UInt16(strings.count))
        writer.uint16(6 + UInt16(strings.count) * 12)
        writer.bytes(nameRecords.data)
        writer.bytes(stringStorage)
        return writer.data
    }

    private static func makePostTable() -> Data {
        var writer = BinaryWriter()
        writer.fixed32(3.0)
        writer.int32(0)
        writer.int16(0)
        writer.int16(0)
        writer.uint32(0)
        writer.uint32(0)
        writer.uint32(0)
        writer.uint32(0)
        writer.uint32(0)
        return writer.data
    }

    private static func makeSbixTable(glyphs: [FontGlyphSource]) -> Data {
        let glyphCount = glyphs.count + 1
        var glyphPayloads: [Data] = Array(repeating: Data(), count: glyphCount)

        for (index, glyph) in glyphs.enumerated() {
            var writer = BinaryWriter()
            writer.int16(32) // originOffsetX
            writer.int16(-24) // originOffsetY (baseline 調整)
            writer.ascii("png ", length: 4)
            writer.bytes(glyph.pngData)
            glyphPayloads[index + 1] = writer.data
        }

        var strikeData = BinaryWriter()
        strikeData.uint16(ppem)
        strikeData.uint16(72) // resolution

        var glyphOffsets = BinaryWriter()
        var currentOffset = UInt32(4 + (glyphCount + 1) * 4)
        for payload in glyphPayloads {
            glyphOffsets.uint32(currentOffset)
            currentOffset += UInt32(payload.count)
        }
        glyphOffsets.uint32(currentOffset)

        strikeData.bytes(glyphOffsets.data)
        for payload in glyphPayloads {
            strikeData.bytes(payload)
        }

        let strikeOffset = UInt32(12) // version + flags + numStrikes + strikeOffsets[0]

        var writer = BinaryWriter()
        writer.uint16(1) // version
        writer.uint16(1) // flags (bit 0 must be set per Apple spec)
        writer.uint32(1) // numStrikes
        writer.uint32(strikeOffset)
        writer.bytes(strikeData.data)
        return writer.data
    }
}
