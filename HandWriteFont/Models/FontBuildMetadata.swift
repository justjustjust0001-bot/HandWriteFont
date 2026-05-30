import Foundation

/// フォント生成時の版情報（再エクスポートで内容が変わったことを OS / ファイル名に反映する）
struct FontBuildMetadata {
    let fontRevision: Float
    let versionString: String
    let exportStamp: String

    static let `default` = FontBuildMetadata(
        fontRevision: 1.0,
        versionString: "Version 1.000",
        exportStamp: "00000000-000000"
    )

    static func make(records: [GlyphRecord], exportedAt: Date = .now) -> FontBuildMetadata {
        let latestSave = records.map(\.savedAt).max() ?? exportedAt
        let stamp = exportStampFormatter.string(from: exportedAt)
        let revision = fontRevision(from: latestSave)
        return FontBuildMetadata(
            fontRevision: revision,
            versionString: String(format: "Version %.3f", revision),
            exportStamp: stamp
        )
    }

    private static func fontRevision(from date: Date) -> Float {
        let minor = Int(date.timeIntervalSince1970) % 10_000
        return 1.0 + Float(minor) / 10_000.0
    }

    private static let exportStampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter
    }()
}
