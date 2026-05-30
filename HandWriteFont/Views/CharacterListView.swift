import SwiftUI

struct CharacterListView: View {
    @EnvironmentObject private var projectService: FontProjectService
    @EnvironmentObject private var subscription: SubscriptionService

    @State private var searchText = ""
    @State private var kanjiSearchText = ""
    @State private var showKanjiStore = false
    @State private var showProjectPicker = false

    private var glyphStorage: GlyphStorageService { projectService.glyphStorage }
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20, pinnedViews: [.sectionHeaders]) {
                projectCard
                overallProgressCard
                CharacterSearchView(query: $kanjiSearchText)

                ForEach(visibleSections) { section in
                    Section {
                        characterGrid(for: section)
                    } header: {
                        sectionHeader(for: section)
                    }
                }
            }
            .padding()
        }
        .background(AppTheme.background)
        .appBrandNavigationTitle()
        .searchable(text: $searchText, prompt: "文字を検索")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showProjectPicker = true
                    } label: {
                        Label("プロジェクト切替", systemImage: "folder")
                    }

                    NavigationLink {
                        FontPreviewView()
                    } label: {
                        Label("試し打ち", systemImage: "text.cursor")
                    }

                    NavigationLink {
                        FontExportView()
                    } label: {
                        Label("フォント出力", systemImage: "arrow.down.doc")
                    }

                    Button {
                        showKanjiStore = true
                    } label: {
                        Label(
                            subscription.isKanjiUnlocked ? "漢字パック（解放済）" : "漢字パックを購入",
                            systemImage: subscription.isKanjiUnlocked ? "checkmark.seal" : "lock"
                        )
                    }

                    Button {
                        NotificationCenter.default.post(name: .showOnboardingTutorial, object: nil)
                    } label: {
                        Label("使い方ガイド", systemImage: "book.pages")
                    }

                    NavigationLink {
                        LegalInfoView()
                    } label: {
                        Label("法的情報", systemImage: "doc.text")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(AppTheme.accentDeep)
                }
            }
        }
        .sheet(isPresented: $showKanjiStore) {
            KanjiPackStoreView()
        }
        .sheet(isPresented: $showProjectPicker) {
            ProjectPickerView()
        }
        .alert("保存エラー", isPresented: storeErrorBinding) {
            Button("OK", role: .cancel) {
                projectService.storeErrorMessage = nil
            }
        } message: {
            Text(projectService.storeErrorMessage ?? "")
        }
    }

    private var storeErrorBinding: Binding<Bool> {
        Binding(
            get: { projectService.storeErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    projectService.storeErrorMessage = nil
                }
            }
        )
    }

    private var projectCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("いま作っているフォント")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                    Text(projectService.activeProject.name)
                        .font(.title3.bold())
                        .foregroundStyle(AppTheme.warmText)
                }
                Spacer()
                Button {
                    showProjectPicker = true
                } label: {
                    Label("切替", systemImage: "arrow.left.arrow.right")
                        .font(.caption.bold())
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.accent)
            }

            Text("保存済み \(glyphStorage.allExportableRecords.count) 文字")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .warmCard()
    }

    private var overallProgressCard: some View {
        let freeSaved = glyphStorage.savedCount(in: CharacterCatalog.allFreeCharacters)
        let freeTotal = CharacterCatalog.allFreeCharacters.count
        let kanjiSaved = glyphStorage.savedCount(in: CharacterCatalog.allKanjiCharacters)
        let kanjiTotal = CharacterCatalog.allKanjiCharacters.count

        return VStack(alignment: .leading, spacing: 12) {
            Text("全体の進捗")
                .font(.headline)
                .foregroundStyle(AppTheme.warmText)

            HStack {
                progressBadge(title: "無料文字", saved: freeSaved, total: freeTotal, color: AppTheme.accent)
                progressBadge(
                    title: "漢字",
                    saved: kanjiSaved,
                    total: kanjiTotal,
                    color: subscription.isKanjiUnlocked ? AppTheme.saved : .orange
                )
            }
        }
        .warmCard()
    }

    private func progressBadge(title: String, saved: Int, total: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
            Text("\(saved)/\(total)")
                .font(.title3.bold())
                .foregroundStyle(AppTheme.warmText)
            ProgressView(value: Double(saved), total: Double(max(total, 1)))
                .tint(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var visibleSections: [CharacterSection] {
        CharacterCatalog.allSections.filter { section in
            guard !searchText.isEmpty else { return true }
            return CharacterCatalog.characters(in: section).contains {
                String($0).localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    @ViewBuilder
    private func sectionHeader(for section: CharacterSection) -> some View {
        let characters = filteredCharacters(in: section)
        let isLocked = section.requiresSubscription(isKanjiUnlocked: subscription.isKanjiUnlocked)

        if !characters.isEmpty {
            CharacterSectionHeader(
                section: section,
                savedCount: glyphStorage.savedCount(in: characters),
                totalCount: characters.count,
                isLocked: isLocked
            )
            .padding(.vertical, 6)
            .background(AppTheme.background)
        }
    }

    @ViewBuilder
    private func characterGrid(for section: CharacterSection) -> some View {
        let characters = filteredCharacters(in: section)
        let isLocked = section.requiresSubscription(isKanjiUnlocked: subscription.isKanjiUnlocked)

        if characters.isEmpty {
            EmptyView()
        } else {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(characters, id: \.self) { character in
                    if isLocked {
                        Button {
                            showKanjiStore = true
                        } label: {
                            CharacterGridCell(
                                character: character,
                                isSaved: glyphStorage.isSaved(character),
                                isLocked: true
                            )
                        }
                        .buttonStyle(.plain)
                    } else {
                        NavigationLink {
                            CharacterCanvasView(character: character)
                        } label: {
                            CharacterGridCell(
                                character: character,
                                isSaved: glyphStorage.isSaved(character),
                                isLocked: false
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func filteredCharacters(in section: CharacterSection) -> [Character] {
        let all = CharacterCatalog.characters(in: section)
        guard !searchText.isEmpty else { return all }
        return all.filter { String($0).localizedCaseInsensitiveContains(searchText) }
    }
}

#Preview {
    NavigationStack {
        CharacterListView()
            .environmentObject(FontProjectService())
            .environmentObject(SubscriptionService())
    }
}
