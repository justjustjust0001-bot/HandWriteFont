import Foundation
import UIKit

@MainActor
final class GlyphStorageService: ObservableObject {
    @Published private(set) var records: [GlyphRecord] = []

    private var directoryURL: URL
    private var indexURL: URL

    init(directoryURL: URL) {
        self.directoryURL = directoryURL
        self.indexURL = directoryURL.appendingPathComponent("index.json")
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        loadExistingRecords()
    }

    func reload(at directoryURL: URL) {
        self.directoryURL = directoryURL
        self.indexURL = directoryURL.appendingPathComponent("index.json")
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        loadExistingRecords()
    }

    func isSaved(_ character: Character) -> Bool {
        records.contains { $0.character == character }
    }

    func savedCount(in characters: [Character]) -> Int {
        let saved = Set(records.map(\.character))
        return characters.filter { saved.contains($0) }.count
    }

    func savedCount(in section: CharacterSection) -> Int {
        savedCount(in: CharacterCatalog.characters(in: section))
    }

    @discardableResult
    func save(
        image: UIImage,
        strokes: [DrawingStroke],
        canvasSize: CGSize,
        strokeWidth: CGFloat,
        for character: Character
    ) throws -> GlyphRecord {
        let baseName = sanitizedBaseName(for: character)
        let imageURL = directoryURL.appendingPathComponent("\(baseName).png")
        let strokesURL = directoryURL.appendingPathComponent("\(baseName).json")

        guard let pngData = image.pngData() else {
            throw GlyphStorageError.imageEncodingFailed
        }

        let strokeData = try StrokeSerializer.encode(
            character: character,
            strokes: strokes,
            canvasSize: canvasSize,
            strokeWidth: strokeWidth
        )

        // JSON を先に書き、PNG 失敗時は JSON を削除して不整合を防ぐ
        try strokeData.write(to: strokesURL, options: .atomic)
        do {
            try pngData.write(to: imageURL, options: .atomic)
        } catch {
            try? FileManager.default.removeItem(at: strokesURL)
            throw GlyphStorageError.imageEncodingFailed
        }

        let record = GlyphRecord(
            character: character,
            imageURL: imageURL,
            strokesURL: strokesURL,
            canvasSize: canvasSize
        )
        records.removeAll { $0.character == character }
        records.append(record)
        records.sort { String($0.character) < String($1.character) }
        do {
            try persistIndex()
        } catch {
            throw GlyphStorageError.indexWriteFailed
        }
        return record
    }

    func delete(for character: Character) throws {
        guard let record = record(for: character) else { return }

        if FileManager.default.fileExists(atPath: record.imageURL.path) {
            try FileManager.default.removeItem(at: record.imageURL)
        }
        if FileManager.default.fileExists(atPath: record.strokesURL.path) {
            try FileManager.default.removeItem(at: record.strokesURL)
        }

        records.removeAll { $0.character == character }
        try persistIndex()
    }

    func record(for character: Character) -> GlyphRecord? {
        records.first { $0.character == character }
    }

    func image(for character: Character) -> UIImage? {
        guard let record = record(for: character) else { return nil }
        return UIImage(contentsOfFile: record.imageURL.path)
    }

    func strokes(for character: Character) -> ([DrawingStroke], CGSize, CGFloat)? {
        guard let payload = drawingData(for: character) else { return nil }
        return (payload.strokes, payload.canvasSize.cgSize, CGFloat(payload.strokeWidth))
    }

    func drawingData(for character: Character) -> SavedDrawingData? {
        guard let record = record(for: character) else { return nil }
        guard FileManager.default.fileExists(atPath: record.strokesURL.path) else { return nil }
        guard let data = try? Data(contentsOf: record.strokesURL) else { return nil }
        return try? StrokeSerializer.decode(from: data)
    }

    func exportableRecords(from characters: [Character]) -> [GlyphRecord] {
        let saved = Set(records.map(\.character))
        return records.filter { saved.contains($0.character) && characters.contains($0.character) }
    }

    func exportableRecords(in section: CharacterSection) -> [GlyphRecord] {
        exportableRecords(from: CharacterCatalog.characters(in: section))
    }

    var allExportableRecords: [GlyphRecord] {
        records.filter { record in
            FileManager.default.fileExists(atPath: record.imageURL.path)
                && FileManager.default.fileExists(atPath: record.strokesURL.path)
        }
    }

    var recordsRevision: String {
        let stamp = records.map { "\($0.character)-\($0.savedAt.timeIntervalSince1970)" }.joined(separator: ",")
        return "\(records.count)-\(stamp.hashValue)"
    }

    private func loadExistingRecords() {
        guard
            let data = try? Data(contentsOf: indexURL),
            let index = try? JSONDecoder().decode([GlyphIndexEntry].self, from: data)
        else {
            rebuildIndexFromDisk()
            return
        }

        records = index.compactMap { entry -> GlyphRecord? in
            let imageURL = directoryURL.appendingPathComponent(entry.imageFileName)
            let strokesURL = directoryURL.appendingPathComponent(entry.strokesFileName)
            guard FileManager.default.fileExists(atPath: imageURL.path) else { return nil }
            guard FileManager.default.fileExists(atPath: strokesURL.path) else { return nil }
            guard let character = entry.character.first else { return nil }
            return GlyphRecord(
                id: entry.id,
                character: character,
                imageURL: imageURL,
                strokesURL: strokesURL,
                canvasSize: CGSize(width: entry.canvasWidth, height: entry.canvasHeight),
                savedAt: entry.savedAt
            )
        }

        if records.count != index.count {
            try? persistIndex()
        }
    }

    private func rebuildIndexFromDisk() {
        guard let files = try? FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil) else {
            records = []
            return
        }

        let pngFiles = files.filter { $0.pathExtension == "png" }
        records = pngFiles.compactMap { url in
            let base = url.deletingPathExtension().lastPathComponent
            guard base.hasPrefix("glyph_"), let scalar = UInt32(base.replacingOccurrences(of: "glyph_", with: "")) else {
                return nil
            }
            guard let unicode = UnicodeScalar(scalar) else { return nil }
            let character = Character(unicode)
            let strokesURL = url.deletingPathExtension().appendingPathExtension("json")
            guard FileManager.default.fileExists(atPath: strokesURL.path) else { return nil }
            let canvasSize: CGSize
            if let data = try? Data(contentsOf: strokesURL),
               let payload = try? StrokeSerializer.decode(from: data) {
                canvasSize = payload.canvasSize.cgSize
            } else {
                canvasSize = CGSize(width: 512, height: 512)
            }
            return GlyphRecord(
                character: character,
                imageURL: url,
                strokesURL: strokesURL,
                canvasSize: canvasSize
            )
        }.sorted { String($0.character) < String($1.character) }

        try? persistIndex()
    }

    private func persistIndex() throws {
        let index = records.map { record in
            GlyphIndexEntry(
                id: record.id,
                character: record.character,
                imageFileName: record.imageURL.lastPathComponent,
                strokesFileName: record.strokesURL.lastPathComponent,
                canvasWidth: record.canvasSize.width,
                canvasHeight: record.canvasSize.height,
                savedAt: record.savedAt
            )
        }
        let data = try JSONEncoder().encode(index)
        try data.write(to: indexURL, options: .atomic)
    }

    private func sanitizedBaseName(for character: Character) -> String {
        let scalar = character.unicodeScalars.first?.value ?? 0
        return "glyph_\(scalar)"
    }
}

private struct GlyphIndexEntry: Codable {
    let id: UUID
    let character: String
    let imageFileName: String
    let strokesFileName: String
    let canvasWidth: Double
    let canvasHeight: Double
    let savedAt: Date

    init(
        id: UUID,
        character: Character,
        imageFileName: String,
        strokesFileName: String,
        canvasWidth: Double,
        canvasHeight: Double,
        savedAt: Date
    ) {
        self.id = id
        self.character = String(character)
        self.imageFileName = imageFileName
        self.strokesFileName = strokesFileName
        self.canvasWidth = canvasWidth
        self.canvasHeight = canvasHeight
        self.savedAt = savedAt
    }
}

enum GlyphStorageError: LocalizedError {
    case imageEncodingFailed
    case nothingToSave
    case noGlyphsToExport
    case indexWriteFailed
    case loadFailed

    var errorDescription: String? {
        switch self {
        case .imageEncodingFailed:
            return "画像の保存に失敗しました。"
        case .nothingToSave:
            return "保存する描画がありません。"
        case .noGlyphsToExport:
            return "エクスポート可能な文字がありません。先に文字を保存してください。"
        case .indexWriteFailed:
            return "索引ファイルの保存に失敗しました。"
        case .loadFailed:
            return "保存データの読み込みに失敗しました。書き直してください。"
        }
    }
}
