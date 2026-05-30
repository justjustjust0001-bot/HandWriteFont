import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let providers = items.map { ExportFileActivityItem(url: $0) }
        return UIActivityViewController(activityItems: providers, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

/// 共有時に毎回ディスクから読み直す（同一ファイル名のキャッシュを避ける）
private final class ExportFileActivityItem: NSObject, UIActivityItemSource {
    private let url: URL

    init(url: Any) {
        if let fileURL = url as? URL {
            self.url = fileURL
        } else {
            self.url = URL(fileURLWithPath: "/dev/null")
        }
        super.init()
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        url
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        url
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?
    ) -> String {
        UTType.font.identifier
    }
}
