import SwiftUI

struct LegalInfoView: View {
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }

    var body: some View {
        List {
            Section("アプリ情報") {
                LabeledContent("バージョン", value: appVersion)
            }

            Section("法的情報") {
                ForEach(LegalDocumentKind.allCases) { document in
                    NavigationLink {
                        LegalDocumentView(document: document)
                    } label: {
                        Text(document.title)
                    }
                }
            }

            Section("事業者情報") {
                LabeledContent("事業者名", value: LegalContactInfo.businessName)
                Link(LegalContactInfo.contactEmail, destination: URL(string: "mailto:\(LegalContactInfo.contactEmail)")!)
                Link("公式サイト", destination: LegalContactInfo.supportURL)
                Link("特定商取引法に基づく表記", destination: LegalContactInfo.tokushohoURL)
            }

            Section {
                Text("作成したフォントの著作権はユーザーに帰属します。フォントの販売・配布も可能です（第三者の権利を侵害しない範囲）。")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .navigationTitle("法的情報")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        LegalInfoView()
    }
}
