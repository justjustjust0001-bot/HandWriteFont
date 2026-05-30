import CoreGraphics
import CoreText
import Foundation

enum FontPreviewError: LocalizedError {
    case noGlyphs
    case buildFailed
    case registrationFailed

    var errorDescription: String? {
        switch self {
        case .noGlyphs:
            return "プレビューする文字がありません。先に文字を保存してください。"
        case .buildFailed:
            return "プレビュー用フォントの生成に失敗しました。"
        case .registrationFailed:
            return "フォントの読み込みに失敗しました。保存した文字を確認して再度お試しください。"
        }
    }
}

struct PreviewGlyphSnapshot: Sendable {
    let character: Character
    let strokes: [DrawingStroke]
    let canvasSize: CGSize
    let strokeWidth: CGFloat
}

@MainActor
enum FontPreviewService {
    private static var registeredFont: CGFont?
    private static var cacheKey: String?
    private static var cachedPostScriptName: String?

    static func prepareFont(
        name: String,
        disambiguator: String,
        records: [GlyphRecord],
        glyphStorage: GlyphStorageService
    ) async throws -> String {
        let key = cacheKey(
            name: name,
            disambiguator: disambiguator,
            records: records
        )

        if cacheKey == key, let cachedPostScriptName {
            return cachedPostScriptName
        }

        unregisterCurrent()

        var snapshots: [PreviewGlyphSnapshot] = []
        for record in records {
            guard let drawing = glyphStorage.drawingData(for: record.character) else { continue }
            let contours = StrokeOutlineConverter.fontContours(
                from: drawing.strokes,
                canvasSize: drawing.canvasSize.cgSize,
                strokeWidth: CGFloat(drawing.strokeWidth)
            )
            guard !contours.isEmpty else { continue }
            snapshots.append(
                PreviewGlyphSnapshot(
                    character: record.character,
                    strokes: drawing.strokes,
                    canvasSize: drawing.canvasSize.cgSize,
                    strokeWidth: CGFloat(drawing.strokeWidth)
                )
            )
        }

        guard !snapshots.isEmpty else {
            throw FontPreviewError.noGlyphs
        }

        let fontData: Data
        do {
            fontData = try await Task.detached(priority: .userInitiated) {
                let sources = snapshots.map {
                    VectorGlyphSource(
                        character: $0.character,
                        strokes: $0.strokes,
                        canvasSize: $0.canvasSize,
                        strokeWidth: $0.strokeWidth
                    )
                }
                return try VectorFontBuilder.build(
                    fontName: name,
                    disambiguator: disambiguator,
                    glyphs: sources
                )
            }.value
        } catch {
            throw FontPreviewError.buildFailed
        }

        let postScriptName = OpenTypeTables.postScriptName(from: name, disambiguator: disambiguator)

        guard
            let provider = CGDataProvider(data: fontData as CFData),
            let cgFont = CGFont(provider)
        else {
            throw FontPreviewError.buildFailed
        }

        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterGraphicsFont(cgFont, &error) {
            CTFontManagerUnregisterGraphicsFont(cgFont, nil)
            error = nil
            if !CTFontManagerRegisterGraphicsFont(cgFont, &error) {
                throw FontPreviewError.registrationFailed
            }
        }

        registeredFont = cgFont
        cacheKey = key
        cachedPostScriptName = cgFont.postScriptName as String? ?? postScriptName
        return cachedPostScriptName ?? postScriptName
    }

    static func unregisterCurrent() {
        if let font = registeredFont {
            CTFontManagerUnregisterGraphicsFont(font, nil)
            registeredFont = nil
        }
        cacheKey = nil
        cachedPostScriptName = nil
    }

    private static func cacheKey(name: String, disambiguator: String, records: [GlyphRecord]) -> String {
        let revision = records
            .map { "\($0.character)-\($0.savedAt.timeIntervalSince1970)" }
            .joined(separator: "|")
        return "\(name)-\(disambiguator)-\(revision)"
    }
}
