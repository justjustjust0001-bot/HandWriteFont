import CoreGraphics
import Foundation

struct DrawingStroke: Identifiable, Equatable, Codable, @unchecked Sendable {
    let id: UUID
    var points: [CGPoint]
    var strokeWidth: CGFloat

    enum CodingKeys: String, CodingKey {
        case id
        case points
        case strokeWidth
    }

    init(id: UUID = UUID(), points: [CGPoint] = [], strokeWidth: CGFloat = DrawingSettings.defaultWidth) {
        self.id = id
        self.points = points
        self.strokeWidth = strokeWidth
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        let codablePoints = try container.decode([CodablePoint].self, forKey: .points)
        points = codablePoints.map(\.cgPoint)
        if let width = try container.decodeIfPresent(Double.self, forKey: .strokeWidth) {
            strokeWidth = CGFloat(width)
        } else {
            strokeWidth = 0
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(points.map(CodablePoint.init), forKey: .points)
        try container.encode(Double(strokeWidth), forKey: .strokeWidth)
    }

    func resolvedWidth(fallback: CGFloat) -> CGFloat {
        strokeWidth > 0 ? strokeWidth : fallback
    }
}

struct SavedDrawingData: Codable {
    let character: String
    let canvasSize: CodableSize
    let strokes: [DrawingStroke]
    let strokeWidth: Double
    let savedAt: Date

    enum CodingKeys: String, CodingKey {
        case character
        case canvasSize
        case strokes
        case strokeWidth
        case savedAt
    }

    init(
        character: String,
        canvasSize: CodableSize,
        strokes: [DrawingStroke],
        strokeWidth: Double,
        savedAt: Date = .now
    ) {
        self.character = character
        self.canvasSize = canvasSize
        self.strokes = strokes
        self.strokeWidth = strokeWidth
        self.savedAt = savedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        character = try container.decode(String.self, forKey: .character)
        canvasSize = try container.decode(CodableSize.self, forKey: .canvasSize)
        strokes = try container.decode([DrawingStroke].self, forKey: .strokes)
        strokeWidth = try container.decodeIfPresent(Double.self, forKey: .strokeWidth)
            ?? Double(DrawingSettings.defaultWidth)
        savedAt = try container.decode(Date.self, forKey: .savedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(character, forKey: .character)
        try container.encode(canvasSize, forKey: .canvasSize)
        try container.encode(strokes, forKey: .strokes)
        try container.encode(strokeWidth, forKey: .strokeWidth)
        try container.encode(savedAt, forKey: .savedAt)
    }
}
