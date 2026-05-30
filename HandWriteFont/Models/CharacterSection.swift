import Foundation

enum CharacterSection: Identifiable, Hashable {
    case uppercaseLatin
    case lowercaseLatin
    case digits
    case hiragana
    case katakana
    case symbols
    case kanji(KanjiPack)

    var id: String {
        switch self {
        case .uppercaseLatin: return "uppercaseLatin"
        case .lowercaseLatin: return "lowercaseLatin"
        case .digits: return "digits"
        case .hiragana: return "hiragana"
        case .katakana: return "katakana"
        case .symbols: return "symbols"
        case .kanji(let pack): return "kanji.\(pack.rawValue)"
        }
    }

    var title: String {
        switch self {
        case .uppercaseLatin: return "大文字（A–Z）"
        case .lowercaseLatin: return "小文字（a–z）"
        case .digits: return "数字（0–9）"
        case .hiragana: return "ひらがな"
        case .katakana: return "カタカナ"
        case .symbols: return "記号"
        case .kanji(let pack): return "漢字：\(pack.displayName)"
        }
    }

    var isKanji: Bool {
        if case .kanji = self { return true }
        return false
    }

    func requiresSubscription(isKanjiUnlocked: Bool) -> Bool {
        switch self {
        case .kanji:
            return !isKanjiUnlocked
        default:
            return false
        }
    }
}
