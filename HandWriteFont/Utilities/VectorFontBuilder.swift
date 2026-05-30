import CoreGraphics
import Foundation

struct VectorGlyphSource {
    let character: Character
    let strokes: [DrawingStroke]
    let canvasSize: CGSize
    let strokeWidth: CGFloat
}

/// 手書きストロークを TrueType ベクター輪郭（glyf）に変換してフォントを生成する
enum VectorFontBuilder {
    static func build(
        fontName: String,
        disambiguator: String? = nil,
        glyphs: [VectorGlyphSource],
        metadata: FontBuildMetadata = .default
    ) throws -> Data {
        guard !glyphs.isEmpty else {
            throw FontExportError.noGlyphs
        }

        let sortedGlyphs = glyphs.sorted {
            ($0.character.unicodeScalars.first?.value ?? 0) < ($1.character.unicodeScalars.first?.value ?? 0)
        }

        var metricsList: [EncodedGlyphMetrics] = [EncodedGlyphMetrics.encode(contours: [])]

        for glyph in sortedGlyphs {
            let contours = StrokeOutlineConverter.fontContours(
                from: glyph.strokes,
                canvasSize: glyph.canvasSize,
                strokeWidth: glyph.strokeWidth
            )
            metricsList.append(EncodedGlyphMetrics.encode(contours: contours))
        }

        let drawableGlyphs = metricsList.dropFirst().filter { $0.contourCount > 0 && $0.pointCount > 0 }
        guard !drawableGlyphs.isEmpty else {
            throw FontExportError.emptyOutlines
        }

        let glyphDataList = metricsList.map(\.data)
        let glyphCount = glyphDataList.count
        let codepoints = sortedGlyphs.map { Int($0.character.unicodeScalars.first?.value ?? 0) }

        var tables: [FontTable] = []
        tables.append(FontTable(tag: "head", data: OpenTypeTables.makeHeadTable(
            useLongLoca: true,
            metrics: metricsList,
            fontRevision: metadata.fontRevision
        )))
        tables.append(FontTable(tag: "hhea", data: OpenTypeTables.makeHheaTable(glyphCount: glyphCount, metrics: metricsList)))
        tables.append(FontTable(tag: "maxp", data: OpenTypeTables.makeMaxpTable(glyphCount: glyphCount, metrics: metricsList)))
        tables.append(FontTable(tag: "OS/2", data: OpenTypeTables.makeOS2Table(codepoints: codepoints)))
        tables.append(FontTable(tag: "hmtx", data: OpenTypeTables.makeHmtxTable(glyphCount: glyphCount, metrics: metricsList)))
        tables.append(FontTable(tag: "cmap", data: OpenTypeTables.makeCmapTable(codepoints: codepoints)))
        tables.append(FontTable(tag: "loca", data: OpenTypeTables.makeLocaTable(glyphDataList: glyphDataList)))
        tables.append(FontTable(tag: "glyf", data: mergeGlyphData(glyphDataList)))
        tables.append(FontTable(tag: "name", data: OpenTypeTables.makeNameTable(
            fontName: fontName,
            disambiguator: disambiguator,
            versionString: metadata.versionString
        )))
        tables.append(FontTable(tag: "post", data: OpenTypeTables.makePostTable()))

        return TrueTypeFontAssembler.assemble(tables: tables)
    }

    private static func mergeGlyphData(_ glyphDataList: [Data]) -> Data {
        var merged = Data()
        for data in glyphDataList {
            merged.append(data)
        }
        return merged
    }
}
