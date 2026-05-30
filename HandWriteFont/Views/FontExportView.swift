import SwiftUI

struct FontExportView: View {
    @EnvironmentObject private var projectService: FontProjectService
    @EnvironmentObject private var subscription: SubscriptionService

    @State private var fontName = ""
    @State private var engine: FontExportEngine = .vector
    @State private var scope: FontExportScope = .allSaved
    @State private var alertMessage: String?
    @State private var exportedURL: URL?
    @State private var showShareSheet = false
    @State private var isExporting = false

    private let exportService = FontExportService()
    private var glyphStorage: GlyphStorageService { projectService.glyphStorage }

    var body: some View {
        Form {
            Section("フォント設定") {
                TextField("フォント名", text: $fontName)
                    .textInputAutocapitalization(.words)

                Picker("出力方式", selection: $engine) {
                    ForEach(FontExportEngine.allCases) { engine in
                        Text(engine.displayName).tag(engine)
                    }
                }

                Picker("対象", selection: $scope) {
                    ForEach(FontExportScope.allCases) { scope in
                        Text(scope.title).tag(scope)
                    }
                }
            }

            Section("エクスポート対象") {
                Text("プロジェクト: \(projectService.activeProject.name)")
                Text("保存済み \(exportableRecords.count) 文字")
                Text(scopeDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(engine.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(engine.installHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button {
                    exportFont()
                } label: {
                    if isExporting {
                        HStack {
                            ProgressView()
                            Text("生成中…")
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        Label("TTF を生成", systemImage: "arrow.down.doc")
                    }
                }
                .disabled(isExporting || exportableRecords.isEmpty || fontName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .navigationTitle("フォント出力")
        .onAppear {
            if fontName.isEmpty {
                fontName = projectService.activeProject.name
            }
        }
        .onChange(of: projectService.activeProjectID) { _, _ in
            fontName = projectService.activeProject.name
        }
        .alert("エクスポート", isPresented: alertBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
        .sheet(isPresented: $showShareSheet, onDismiss: { exportedURL = nil }) {
            if let exportedURL {
                ShareSheet(items: [exportedURL])
                    .id(exportedURL.absoluteString)
            }
        }
    }

    private var exportableRecords: [GlyphRecord] {
        switch scope {
        case .allSaved:
            if subscription.isKanjiUnlocked {
                return glyphStorage.allExportableRecords
            }
            let free = Set(CharacterCatalog.allFreeCharacters)
            return glyphStorage.allExportableRecords.filter { free.contains($0.character) }
        case .freeCharactersOnly:
            let free = Set(CharacterCatalog.allFreeCharacters)
            return glyphStorage.allExportableRecords.filter { free.contains($0.character) }
        }
    }

    private var scopeDescription: String {
        switch scope {
        case .allSaved:
            return subscription.isKanjiUnlocked
                ? "保存済みの全文字（漢字含む）を出力します。"
                : "漢字未解放のため、無料文字のみ出力します。"
        case .freeCharactersOnly:
            return "アルファベット・かな・記号など無料文字のみ。"
        }
    }

    private var alertBinding: Binding<Bool> {
        Binding(
            get: { alertMessage != nil },
            set: { isPresented in
                if !isPresented { alertMessage = nil }
            }
        )
    }

    private func exportFont() {
        let trimmedName = fontName.trimmingCharacters(in: .whitespacesAndNewlines)
        let records = exportableRecords

        isExporting = true
        Task {
            defer { isExporting = false }
            do {
                let result = try await exportService.exportFont(
                    name: trimmedName,
                    disambiguator: projectService.activeProjectTag,
                    engine: engine,
                    records: records,
                    glyphStorage: glyphStorage
                )
                exportedURL = result.url
                showShareSheet = true
                if result.isPartial {
                    alertMessage = FontExportError.partialGlyphs(
                        included: result.glyphCount,
                        total: result.requestedCount
                    ).errorDescription
                } else {
                    alertMessage = "\(result.glyphCount) 文字の\(engine.displayName)フォント（\(result.fileName)）を生成しました。再インストール時は、先に古いフォントを削除してください。"
                }
            } catch {
                alertMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    NavigationStack {
        FontExportView()
            .environmentObject(FontProjectService())
            .environmentObject(SubscriptionService())
    }
}
