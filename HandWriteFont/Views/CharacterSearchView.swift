import SwiftUI

struct CharacterSearchView: View {
    @EnvironmentObject private var subscription: SubscriptionService

    @Binding var query: String
    @State private var outcome: CharacterSearchOutcome = .idle
    @State private var showKanjiStore = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("漢字を検索")
                .font(.headline)
                .foregroundStyle(AppTheme.warmText)

            TextField("文字または読み（例：桜 / さくら）", text: $query)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.search)
                .onSubmit { performSearch() }
                .onChange(of: query) { _, newValue in
                    if newValue.isEmpty {
                        outcome = .idle
                    } else if case .direct = outcome {
                        outcome = .idle
                    } else if case .candidates = outcome {
                        outcome = .idle
                    } else if case .notFound = outcome {
                        outcome = .idle
                    }
                }

            Button {
                performSearch()
            } label: {
                Label("検索", systemImage: "magnifyingglass")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)

            searchResultContent
        }
        .padding()
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
        .shadow(color: AppTheme.accent.opacity(0.06), radius: 6, y: 2)
        .sheet(isPresented: $showKanjiStore) {
            KanjiPackStoreView()
        }
        .onChange(of: subscription.isKanjiUnlocked) { _, _ in
            if case .idle = outcome { return }
            performSearch()
        }
    }

    @ViewBuilder
    private var searchResultContent: some View {
        switch outcome {
        case .idle:
            Text("漢字を1文字入力するか、ひらがな・カタカナで読みを入力してください。")
                .font(.caption)
                .foregroundStyle(.secondary)

        case .direct(let character):
            VStack(alignment: .leading, spacing: 8) {
                Text("見つかりました")
                    .font(.subheadline.bold())
                characterLink(for: character)
            }

        case .candidates(let candidates):
            VStack(alignment: .leading, spacing: 8) {
                Text("候補 \(candidates.count) 件")
                    .font(.subheadline.bold())

                ForEach(candidates) { candidate in
                    HStack {
                        characterLink(for: candidate.character)
                        Spacer()
                        Text(candidate.readings.prefix(3).joined(separator: "、"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

        case .notFound:
            Label("該当する文字は見つかりませんでした。", systemImage: "exclamationmark.circle")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func characterLink(for character: Character) -> some View {
        let isLocked = CharacterCatalog.isKanji(character) && !subscription.isKanjiUnlocked

        if isLocked {
            Button {
                showKanjiStore = true
            } label: {
                HStack {
                    Text(String(character))
                        .font(.title2.monospaced())
                    Text("漢字パックが必要です")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "lock.fill")
                }
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink {
                CharacterCanvasView(character: character)
            } label: {
                HStack {
                    Text(String(character))
                        .font(.title2.monospaced())
                    if let section = CharacterCatalog.section(containing: character) {
                        Text(section.title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func performSearch() {
        outcome = CharacterSearchService.search(query)
    }
}

#Preview {
    NavigationStack {
        CharacterSearchView(query: .constant("さくら"))
            .environmentObject(SubscriptionService())
            .padding()
    }
}
