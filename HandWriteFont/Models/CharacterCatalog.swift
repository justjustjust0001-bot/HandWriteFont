import Foundation

enum CharacterCatalog {
    static let uppercaseLatin = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    static let lowercaseLatin = Array("abcdefghijklmnopqrstuvwxyz")
    static let digits = Array("0123456789")

    static let hiragana: [Character] = Array(
        "あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわゐゑをん" +
        "がぎぐげござじずぜぞだぢづでどばびぶべぼぱぴぷぺぽ" +
        "ぁぃぅぇぉゃゅょっゎー"
    )

    static let katakana: [Character] = Array(
        "アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヰヱヲン" +
        "ガギグゲゴザジズゼゾダヂヅデドバビブベボパピプペポ" +
        "ァィゥェォャュョッヮー"
    )

    static let symbols: [Character] = Array(
        "!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~" +
        "、。・「」『』（）ー〜…！？‥‘’“”％＃＆＊＋－＝＜＞＠￥"
    )

    static var freeSections: [CharacterSection] {
        [
            .uppercaseLatin,
            .lowercaseLatin,
            .digits,
            .hiragana,
            .katakana,
            .symbols
        ]
    }

    static var kanjiSections: [CharacterSection] {
        KanjiPack.allCases.map { .kanji($0) }
    }

    static var allSections: [CharacterSection] {
        freeSections + kanjiSections
    }

    static func characters(in section: CharacterSection) -> [Character] {
        switch section {
        case .uppercaseLatin: return uppercaseLatin
        case .lowercaseLatin: return lowercaseLatin
        case .digits: return digits
        case .hiragana: return hiragana
        case .katakana: return katakana
        case .symbols: return symbols
        case .kanji(let pack):
            return KanjiDataLoader.characters(for: pack)
        }
    }

    static var allFreeCharacters: [Character] {
        freeSections.flatMap { characters(in: $0) }
    }

    static var allKanjiCharacters: [Character] {
        kanjiSections.flatMap { characters(in: $0) }
    }

    static var allCharacters: [Character] {
        allSections.flatMap { characters(in: $0) }
    }

    static func contains(_ character: Character) -> Bool {
        allCharacterSet.contains(character)
    }

    static func isKanji(_ character: Character) -> Bool {
        allKanjiSet.contains(character)
    }

    static func section(containing character: Character) -> CharacterSection? {
        for section in allSections where characters(in: section).contains(character) {
            return section
        }
        return nil
    }

    private static let allCharacterSet = Set(allCharacters)
    private static let allKanjiSet = Set(allKanjiCharacters)
}

enum KanjiDataLoader {
    private static let cached: [String: String] = loadManifest()

    static func characters(for pack: KanjiPack) -> [Character] {
        Array(cached[pack.jsonKey] ?? "")
    }

    static var totalKanjiCount: Int {
        allKanji.count
    }

    static var allKanji: [Character] {
        Array(cached["all"] ?? "")
    }

    private static func loadManifest() -> [String: String] {
        guard
            let url = Bundle.main.url(forResource: "kanji_packs", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let manifest = try? JSONDecoder().decode([String: String].self, from: data)
        else {
            return fallbackManifest()
        }
        return manifest
    }

    /// Bundle 未登録時の最小フォールバック
    private static func fallbackManifest() -> [String: String] {
        let grade1 = "一右雨円王音下火花貝学気九休玉金空月犬見五口校左三山子四糸字耳七手十出女小上森人水正生青夕石赤千川先早草足村大男竹中虫町天田土二日入年白八百文木本名目立力林六"
        return [
            "grade1": grade1,
            "grade2": "",
            "grade3": "",
            "grade4": "",
            "grade5": "",
            "grade6": "",
            "juniorHigh": "",
            "all": grade1
        ]
    }
}
