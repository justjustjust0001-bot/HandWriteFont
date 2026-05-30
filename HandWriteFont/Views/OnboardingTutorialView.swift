import SwiftUI

struct OnboardingTutorialView: View {
    let onComplete: () -> Void
    var allowEarlyDismiss = false

    @State private var pageIndex = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "hand.draw.fill",
            title: "FontMaker へようこそ",
            body: """
            手書きであなただけのオリジナルなフォントを作成できるアプリです。

            一つ一つ文字を書いて、保存していきましょう。
            """
        ),
        OnboardingPage(
            icon: "square.grid.3x3.fill",
            title: "基本的な使い方",
            body: """
            1. 文字一覧から書きたい文字を選び、キャンバスで手書きします
            2. 保存すると、その文字がフォント用データとして記録されます
            3. メニュー（⋯）から「試し打ち」で保存済みの文字をプレビューできます
            4. 「フォント出力」で .ttf ファイルを生成し、共有・保存します
            """
        ),
        OnboardingPage(
            icon: "doc.fill",
            title: "出力ファイルについて",
            body: """
            フォント出力では「ベクター（輪郭）」をお選びください。Windows / Mac など幅広い環境で使える標準形式です。

            「ビットマップ（sbix）」は、書いた見た目を画像のまま埋め込む方式です。iPhone / iPad など Apple 端末だけで使う場合に向いています。Windows では使えない場合があります。

            出力した .ttf ファイルを端末にインストールすると、対応アプリ（Pages、Wordなど）で手書きフォントをご利用いただけます。

            ※ 再出力する際には、古いフォントを削除した後に新しいファイルをインストールしてください。
            """
        ),
        OnboardingPage(
            icon: "checkmark.seal.fill",
            title: "漢字パックをご検討の方へ",
            body: """
            漢字パックをご購入の前に無料版でフォントを作成・出力し、お使いの端末で意図どおり表示されるかご確認ください。
            """
        )
    ]

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $pageIndex) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        pageView(page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                bottomBar
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
            }
            .overlay(alignment: .topTrailing) {
                if allowEarlyDismiss {
                    Button("閉じる") {
                        onComplete()
                    }
                    .foregroundStyle(AppTheme.secondaryText)
                    .padding(.top, 12)
                    .padding(.trailing, 20)
                }
            }
        }
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    if pageIndex == 0 {
                        AppBrandTitle(size: .large)
                    }

                    Image(systemName: page.icon)
                        .font(.system(size: 44))
                        .foregroundStyle(AppTheme.accent)
                        .symbolRenderingMode(.hierarchical)

                    Text(page.title)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.warmText)
                        .multilineTextAlignment(.center)

                    Text(page.body)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineSpacing(5)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: geometry.size.height, alignment: .center)
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
            }
        }
    }

    private var bottomBar: some View {
        HStack {
            if pageIndex > 0 {
                Button("戻る") {
                    withAnimation { pageIndex -= 1 }
                }
                .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()

            Button(pageIndex == pages.count - 1 ? "はじめる" : "次へ") {
                if pageIndex == pages.count - 1 {
                    OnboardingStorage.markCompleted()
                    onComplete()
                } else {
                    withAnimation { pageIndex += 1 }
                }
            }
            .font(.system(.body, design: .rounded, weight: .semibold))
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
        }
    }
}

private struct OnboardingPage {
    let icon: String
    let title: String
    let body: String
}

#Preview {
    OnboardingTutorialView(onComplete: {})
}
