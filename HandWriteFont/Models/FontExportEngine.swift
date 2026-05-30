import Foundation

enum FontExportEngine: String, CaseIterable, Identifiable {
    case bitmap
    case vector

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bitmap: return "ビットマップ（sbix）"
        case .vector: return "ベクター（輪郭）"
        }
    }

    var detail: String {
        switch self {
        case .bitmap:
            return "PNG 埋め込み（sbix）。主に Apple 端末向け。Windows では使えない場合があります。"
        case .vector:
            return "手書きを輪郭データに変換。Windows / macOS / Linux などで使える標準 .ttf 形式。"
        }
    }

    var installHint: String {
        switch self {
        case .bitmap:
            return "iPhone / iPad / Mac 向け。Windows への持ち込みは非推奨です。"
        case .vector:
            return "Windows: ファイルを右クリック →「インストール」。Mac: Font Book。Linux: フォントフォルダへ配置。"
        }
    }
}
