import SwiftUI

struct LegalDocumentView: View {
    let document: LegalDocumentKind

    var body: some View {
        ScrollView {
            Text(document.body)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(AppTheme.warmText)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineSpacing(5)
                .padding()
        }
        .background(AppTheme.background)
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        LegalDocumentView(document: .termsOfUse)
    }
}
