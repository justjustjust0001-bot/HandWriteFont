import Foundation

enum FontExportError: LocalizedError {
    case noGlyphs
    case buildFailed
    case writeFailed
    case invalidName
    case emptyOutlines
    case bitmapNotInstallableOnMac
    case partialGlyphs(included: Int, total: Int)

    var errorDescription: String? {
        switch self {
        case .noGlyphs:
            return "エクスポートする文字がありません。"
        case .buildFailed:
            return "フォントファイルの生成に失敗しました。"
        case .writeFailed:
            return "フォントファイルの書き込みに失敗しました。"
        case .invalidName:
            return "フォント名を入力してください。"
        case .emptyOutlines:
            return "輪郭データが空のためフォントを生成できません。文字を保存し直してからお試しください。"
        case .bitmapNotInstallableOnMac:
            return "ビットマップ形式は macOS の Font Book でインストールできない場合があります。ベクター形式（.ttf）をお試しください。"
        case .partialGlyphs(let included, let total):
            return "\(total) 文字中 \(included) 文字だけ出力できました。保存データが壊れている文字がある可能性があります。"
        }
    }
}
