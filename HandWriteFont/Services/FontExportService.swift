import Foundation

struct FontExportResult {
    let url: URL
    let glyphCount: Int
    let requestedCount: Int
    let fileName: String

    var isPartial: Bool { glyphCount < requestedCount }
}

enum FontExportScope: String, CaseIterable, Identifiable {
    case allSaved
    case freeCharactersOnly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .allSaved: return "保存済みすべて"
        case .freeCharactersOnly: return "無料文字のみ"
        }
    }
}

@MainActor
final class FontExportService {
    func makeSnapshots(
        records: [GlyphRecord],
        glyphStorage: GlyphStorageService
    ) -> [ExportGlyphSnapshot] {
        records.compactMap { record in
            guard let drawing = glyphStorage.drawingData(for: record.character) else { return nil }
            return ExportGlyphSnapshot(
                character: record.character,
                strokes: drawing.strokes,
                canvasSize: drawing.canvasSize.cgSize,
                strokeWidth: CGFloat(drawing.strokeWidth),
                imagePath: record.imageURL.path
            )
        }
    }

    func exportFont(
        name: String,
        disambiguator: String? = nil,
        engine: FontExportEngine,
        records: [GlyphRecord],
        glyphStorage: GlyphStorageService
    ) async throws -> FontExportResult {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw FontExportError.invalidName
        }
        guard !records.isEmpty else {
            throw FontExportError.noGlyphs
        }

        let metadata = FontBuildMetadata.make(records: records)
        let snapshots = makeSnapshots(records: records, glyphStorage: glyphStorage)

        let buildResult = try await Task.detached(priority: .userInitiated) {
            try FontExportWorker.export(
                name: trimmedName,
                disambiguator: disambiguator,
                engine: engine,
                snapshots: snapshots,
                metadata: metadata
            )
        }.value

        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(buildResult.fileName)
        do {
            try buildResult.data.write(to: outputURL, options: .atomic)
        } catch {
            throw FontExportError.writeFailed
        }

        return FontExportResult(
            url: outputURL,
            glyphCount: buildResult.glyphCount,
            requestedCount: records.count,
            fileName: buildResult.fileName
        )
    }
}
