import Foundation
import UIKit

struct ExportGlyphSnapshot: Sendable {
    let character: Character
    let strokes: [DrawingStroke]
    let canvasSize: CGSize
    let strokeWidth: CGFloat
    let imagePath: String
}

enum FontExportWorker {
    static func export(
        name: String,
        disambiguator: String?,
        engine: FontExportEngine,
        snapshots: [ExportGlyphSnapshot],
        metadata: FontBuildMetadata
    ) throws -> (data: Data, glyphCount: Int, fileName: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw FontExportError.invalidName
        }
        guard !snapshots.isEmpty else {
            throw FontExportError.noGlyphs
        }

        let (fontData, glyphCount): (Data, Int)
        switch engine {
        case .bitmap:
            (fontData, glyphCount) = try buildBitmapFont(
                name: trimmedName,
                disambiguator: disambiguator,
                snapshots: snapshots,
                metadata: metadata
            )
        case .vector:
            (fontData, glyphCount) = try buildVectorFont(
                name: trimmedName,
                disambiguator: disambiguator,
                snapshots: snapshots,
                metadata: metadata
            )
        }

        let baseFileName = OpenTypeTables.safeFileName(from: trimmedName, ext: "ttf", disambiguator: disambiguator)
        let stampedFileName = baseFileName.replacingOccurrences(
            of: ".ttf",
            with: "-\(metadata.exportStamp).ttf"
        )
        return (fontData, glyphCount, stampedFileName)
    }

    private static func buildBitmapFont(
        name: String,
        disambiguator: String?,
        snapshots: [ExportGlyphSnapshot],
        metadata: FontBuildMetadata
    ) throws -> (Data, Int) {
        var sources: [FontGlyphSource] = []
        for snapshot in snapshots {
            guard
                let image = UIImage(contentsOfFile: snapshot.imagePath),
                let pngData = SbixFontBuilder.normalizedPNGData(from: image)
            else {
                continue
            }
            sources.append(FontGlyphSource(character: snapshot.character, pngData: pngData))
        }

        guard !sources.isEmpty else {
            throw FontExportError.noGlyphs
        }

        let data = try SbixFontBuilder.build(
            fontName: name,
            disambiguator: disambiguator,
            glyphs: sources,
            metadata: metadata
        )
        return (data, sources.count)
    }

    private static func buildVectorFont(
        name: String,
        disambiguator: String?,
        snapshots: [ExportGlyphSnapshot],
        metadata: FontBuildMetadata
    ) throws -> (Data, Int) {
        var sources: [VectorGlyphSource] = []

        for snapshot in snapshots {
            let contours = StrokeOutlineConverter.fontContours(
                from: snapshot.strokes,
                canvasSize: snapshot.canvasSize,
                strokeWidth: snapshot.strokeWidth
            )
            guard !contours.isEmpty else { continue }

            sources.append(
                VectorGlyphSource(
                    character: snapshot.character,
                    strokes: snapshot.strokes,
                    canvasSize: snapshot.canvasSize,
                    strokeWidth: snapshot.strokeWidth
                )
            )
        }

        guard !sources.isEmpty else {
            throw FontExportError.emptyOutlines
        }

        let data = try VectorFontBuilder.build(
            fontName: name,
            disambiguator: disambiguator,
            glyphs: sources,
            metadata: metadata
        )
        return (data, sources.count)
    }
}
