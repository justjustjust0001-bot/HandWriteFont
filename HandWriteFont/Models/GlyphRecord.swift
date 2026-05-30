import Foundation

struct GlyphRecord: Identifiable, Equatable {
    let id: UUID
    let character: Character
    let imageURL: URL
    let strokesURL: URL
    let canvasSize: CGSize
    let savedAt: Date

    init(
        id: UUID = UUID(),
        character: Character,
        imageURL: URL,
        strokesURL: URL,
        canvasSize: CGSize,
        savedAt: Date = .now
    ) {
        self.id = id
        self.character = character
        self.imageURL = imageURL
        self.strokesURL = strokesURL
        self.canvasSize = canvasSize
        self.savedAt = savedAt
    }
}
