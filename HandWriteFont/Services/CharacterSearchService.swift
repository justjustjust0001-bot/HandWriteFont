import Foundation

enum KanjiReadingsLoader {
    private static let cached: [String: [String]] = loadReadings()

    static func readings(for character: Character) -> [String] {
        cached[String(character)] ?? []
    }

    private static func loadReadings() -> [String: [String]] {
        guard
            let url = Bundle.main.url(forResource: "kanji_readings", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let manifest = try? JSONDecoder().decode([String: [String]].self, from: data)
        else {
            return [:]
        }
        return manifest
    }
}

struct CharacterSearchCandidate: Identifiable, Hashable {
    let character: Character
    let readings: [String]

    var id: String { String(character) }
}

enum CharacterSearchOutcome: Equatable {
    case idle
    case direct(Character)
    case candidates([CharacterSearchCandidate])
    case notFound
}

enum CharacterSearchService {
    static func search(_ rawQuery: String) -> CharacterSearchOutcome {
        let query = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return .idle }

        if query.count == 1, let character = query.first {
            if CharacterCatalog.contains(character) {
                return .direct(character)
            }
            return .notFound
        }

        if isReadingInput(query) {
            let normalized = normalizeReading(query)
            let candidates = readingMatches(for: normalized)
            if candidates.isEmpty {
                return .notFound
            }
            return .candidates(candidates)
        }

        return .notFound
    }

    private static func isReadingInput(_ query: String) -> Bool {
        query.unicodeScalars.allSatisfy { scalar in
            switch scalar.value {
            case 0x3040 ... 0x309F, 0x30A0 ... 0x30FF, 0xFF66 ... 0xFF9D:
                return true
            default:
                return false
            }
        }
    }

    private static func normalizeReading(_ query: String) -> String {
        query.applyingTransform(.hiraganaToKatakana, reverse: true) ?? query
    }

    private static func readingMatches(for normalizedQuery: String) -> [CharacterSearchCandidate] {
        var results: [(CharacterSearchCandidate, Int)] = []

        for character in CharacterCatalog.allKanjiCharacters {
            let readings = KanjiReadingsLoader.readings(for: character)
            guard !readings.isEmpty else { continue }

            let normalizedReadings = readings.map { normalizeReading($0) }
            let bestScore = normalizedReadings.compactMap { scoreReading($0, for: normalizedQuery) }.min()
            guard let bestScore else { continue }

            results.append((
                CharacterSearchCandidate(character: character, readings: readings),
                bestScore
            ))
        }

        return results
            .sorted { lhs, rhs in
                if lhs.1 != rhs.1 { return lhs.1 < rhs.1 }
                return String(lhs.0.character) < String(rhs.0.character)
            }
            .prefix(30)
            .map(\.0)
    }

    /// スコアが小さいほど一致度が高い
    private static func scoreReading(_ reading: String, for query: String) -> Int? {
        if reading == query { return 0 }
        if reading.hasPrefix(query) { return 1 }
        if reading.contains(query) { return 2 }
        return nil
    }
}
