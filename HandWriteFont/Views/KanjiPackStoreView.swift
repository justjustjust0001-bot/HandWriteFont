import SwiftUI
import StoreKit

struct KanjiPackStoreView: View {
    @EnvironmentObject private var subscription: SubscriptionService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("漢字パック")
                            .font(.title2.bold())
                            .foregroundStyle(AppTheme.warmText)
                        Text("常用漢字 2,136 字すべてを手書き登録できます。小学1年〜中学以降の7セクションに分かれています。")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .padding(.vertical, 4)
                }

                if subscription.isKanjiUnlocked {
                    Section {
                        Label("漢字パックは解放済みです", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(AppTheme.saved)
                    }
                } else if subscription.productsLoadFailed {
                    Section {
                        Text("商品情報を取得できませんでした。")
                            .foregroundStyle(AppTheme.secondaryText)
                        Button("再読み込み") {
                            Task { await subscription.loadProducts() }
                        }
                        #if DEBUG
                        Toggle("開発用：漢字を解放", isOn: subscription.debugUnlockKanjiBinding)
                        #endif
                    }
                } else if subscription.products.isEmpty {
                    Section {
                        Text("App Store 商品を読み込み中…")
                            .foregroundStyle(AppTheme.secondaryText)
                        #if DEBUG
                        Toggle("開発用：漢字を解放", isOn: subscription.debugUnlockKanjiBinding)
                        #endif
                    }
                } else {
                    Section("プラン") {
                        ForEach(subscription.products, id: \.id) { product in
                            Button {
                                Task { await subscription.purchase(product) }
                            } label: {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(product.kanjiPackTitle)
                                            .font(.headline)
                                            .foregroundStyle(AppTheme.warmText)
                                        Text(product.kanjiPackSubtitle)
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.secondaryText)
                                    }
                                    Spacer()
                                    Text(product.kanjiPackDisplayPrice)
                                        .font(.headline)
                                        .foregroundStyle(AppTheme.accentDeep)
                                }
                                .padding(.vertical, 4)
                            }
                            .disabled(subscription.purchaseInProgress)
                        }
                    }
                }

                Section {
                    Button("購入を復元") {
                        Task { await subscription.restorePurchases() }
                    }
                }

                #if DEBUG
                if !subscription.products.isEmpty {
                    Section("開発") {
                        Toggle("開発用：漢字を解放", isOn: subscription.debugUnlockKanjiBinding)
                    }
                }
                #endif
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .navigationTitle("漢字パック")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
            .alert("エラー", isPresented: errorBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(subscription.lastErrorMessage ?? "")
            }
            .alert("購入", isPresented: statusBinding) {
                Button("OK", role: .cancel) {
                    subscription.statusMessage = nil
                }
            } message: {
                Text(subscription.statusMessage ?? "")
            }
            .onAppear {
                if subscription.products.isEmpty {
                    Task { await subscription.loadProducts() }
                }
            }
        }
    }

    private var statusBinding: Binding<Bool> {
        Binding(
            get: { subscription.statusMessage != nil },
            set: { isPresented in
                if !isPresented { subscription.statusMessage = nil }
            }
        )
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { subscription.lastErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    subscription.lastErrorMessage = nil
                }
            }
        )
    }
}

#Preview {
    KanjiPackStoreView()
        .environmentObject(SubscriptionService())
}
