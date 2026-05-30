import Foundation

enum StrokeSerializer {
    static func encode(
        character: Character,
        strokes: [DrawingStroke],
        canvasSize: CGSize,
        strokeWidth: CGFloat
    ) throws -> Data {
        let payload = SavedDrawingData(
            character: String(character),
            canvasSize: CodableSize(canvasSize),
            strokes: strokes,
            strokeWidth: Double(strokeWidth),
            savedAt: .now
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(payload)
    }

    static func decode(from data: Data) throws -> SavedDrawingData {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(SavedDrawingData.self, from: data)
    }
}
