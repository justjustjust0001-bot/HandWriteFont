import Foundation

enum KanjiPack: String, CaseIterable, Identifiable {
    case grade1
    case grade2
    case grade3
    case grade4
    case grade5
    case grade6
    case juniorHigh

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .grade1: return "小学1年（80字）"
        case .grade2: return "小学2年（160字）"
        case .grade3: return "小学3年（200字）"
        case .grade4: return "小学4年（202字）"
        case .grade5: return "小学5年（193字）"
        case .grade6: return "小学6年（191字）"
        case .juniorHigh: return "中学以降（1110字）"
        }
    }

    var jsonKey: String { rawValue }

    var requiresSubscription: Bool { true }
}
