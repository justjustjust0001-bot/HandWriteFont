import SwiftUI

struct FontPreviewView: View {
    @EnvironmentObject private var projectService: FontProjectService
    @EnvironmentObject private var subscription: SubscriptionService

    @State private var sampleText = "あいうえお\nABCabc\n0123\n手書きフォント"
    @State private var fontSize: CGFloat = 32
    @State private var postScriptName: String?
    @State private var useRasterPreview = false
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var reloadGeneration = 0

    private static let maxSampleLength = 500

    private var glyphStorage: GlyphStorageService { projectService.glyphStorage }

    private var previewRecords: [GlyphRecord] {
        let records = glyphStorage.allExportableRecords
        if subscription.isKanjiUnlocked {
            return records
        }
        let free = Set(CharacterCatalog.allFreeCharacters)
        return records.filter { free.contains($0.character) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("試し打ち")
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.warmText)
                    Text("「\(projectService.activeProject.name)」の保存済み \(previewRecords.count) 文字でプレビューします。")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                }

                if useRasterPreview {
                    Text("ベクターフォントの読み込みに失敗したため、保存済みの文字画像で表示しています。")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                Group {
                    if useRasterPreview {
                        GlyphRasterPreviewView(
                            text: sampleText,
                            glyphStorage: glyphStorage,
                            fontSize: fontSize
                        )
                    } else {
                        TextEditor(text: $sampleText)
                            .font(previewFont)
                            .foregroundStyle(AppTheme.warmText)
                            .id(postScriptName ?? "loading")
                    }
                }
                .frame(minHeight: 180)
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                        .stroke(AppTheme.accentSoft, lineWidth: 1)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("文字サイズ")
                        Spacer()
                        Text("\(Int(fontSize)) pt")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    Slider(value: $fontSize, in: 16 ... 72, step: 1)
                        .tint(AppTheme.accent)
                }
                .warmCard()

                if isLoading {
                    ProgressView("フォントを読み込み中…")
                } else if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            .padding()
        }
        .background(AppTheme.background)
        .navigationTitle("試し打ち")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            reloadPreviewFont()
        }
        .onDisappear {
            FontPreviewService.unregisterCurrent()
        }
        .onChange(of: projectService.activeProjectID) { _, _ in
            reloadPreviewFont()
        }
        .onChange(of: glyphStorage.recordsRevision) { _, _ in
            reloadPreviewFont()
        }
        .onChange(of: subscription.isKanjiUnlocked) { _, _ in
            reloadPreviewFont()
        }
        .onChange(of: sampleText) { _, newValue in
            if newValue.count > Self.maxSampleLength {
                sampleText = String(newValue.prefix(Self.maxSampleLength))
            }
        }
    }

    private var previewFont: Font {
        if let postScriptName {
            return .custom(postScriptName, size: fontSize)
        }
        return .system(size: fontSize)
    }

    private func reloadPreviewFont() {
        reloadGeneration += 1
        let generation = reloadGeneration
        isLoading = true
        errorMessage = nil
        postScriptName = nil
        useRasterPreview = false

        Task {
            defer {
                if generation == reloadGeneration {
                    isLoading = false
                }
            }
            guard generation == reloadGeneration else { return }

            do {
                let name = try await FontPreviewService.prepareFont(
                    name: projectService.activeProject.name,
                    disambiguator: projectService.activeProjectTag,
                    records: previewRecords,
                    glyphStorage: glyphStorage
                )
                guard generation == reloadGeneration else { return }
                postScriptName = name
                useRasterPreview = false
            } catch {
                guard generation == reloadGeneration else { return }
                useRasterPreview = !previewRecords.isEmpty
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    NavigationStack {
        FontPreviewView()
            .environmentObject(FontProjectService())
            .environmentObject(SubscriptionService())
    }
}
