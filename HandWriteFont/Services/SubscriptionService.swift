import Foundation
import StoreKit
import SwiftUI

enum SubscriptionProductID {
    static let kanjiMonthly = "com.fontmaker.kanji.monthly"
    static let kanjiYearly = "com.fontmaker.kanji.yearly"
    static let all: Set<String> = [kanjiMonthly, kanjiYearly]
}

extension Product {
    var kanjiPackTitle: String {
        switch id {
        case SubscriptionProductID.kanjiMonthly:
            return "月額プラン"
        case SubscriptionProductID.kanjiYearly:
            return "年額プラン"
        default:
            return displayName
        }
    }

    var kanjiPackSubtitle: String {
        switch id {
        case SubscriptionProductID.kanjiMonthly:
            return "毎月自動更新"
        case SubscriptionProductID.kanjiYearly:
            return "年1回のお支払い（月額よりお得）"
        default:
            return ""
        }
    }

    /// 日本向けの表示価格（StoreKit の displayPrice を優先）
    var kanjiPackDisplayPrice: String {
        if !displayPrice.isEmpty {
            return displayPrice
        }
        switch id {
        case SubscriptionProductID.kanjiMonthly:
            return "¥550"
        case SubscriptionProductID.kanjiYearly:
            return "¥5,000"
        default:
            return displayPrice
        }
    }
}

@MainActor
final class SubscriptionService: ObservableObject {
    @Published private(set) var isKanjiUnlocked = false
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchaseInProgress = false
    @Published private(set) var restoreInProgress = false
    @Published private(set) var productsLoadFailed = false
    @Published var lastErrorMessage: String?
    @Published var statusMessage: String?

    #if DEBUG
    @Published var debugUnlockKanji = UserDefaults.standard.bool(forKey: SubscriptionService.debugUnlockKey)
    #endif

    private static let debugUnlockKey = "FontMaker.debugUnlockKanji"
    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                guard let transaction = try? self.checkVerified(result) else { continue }
                await transaction.finish()
                await self.refreshEntitlements()
            }
        }

        Task {
            await refreshEntitlements()
            await loadProducts()
        }
    }

    #if DEBUG
    func setDebugUnlockKanji(_ enabled: Bool) {
        debugUnlockKanji = enabled
        UserDefaults.standard.set(enabled, forKey: Self.debugUnlockKey)
        Task { await refreshEntitlements() }
    }

    var debugUnlockKanjiBinding: Binding<Bool> {
        Binding(
            get: { self.debugUnlockKanji },
            set: { self.setDebugUnlockKanji($0) }
        )
    }
    #endif

    func loadProducts() async {
        productsLoadFailed = false
        do {
            products = try await Product.products(for: Array(SubscriptionProductID.all))
                .sorted { $0.price < $1.price }
            if products.isEmpty {
                productsLoadFailed = true
                lastErrorMessage = "商品情報を取得できませんでした。"
            }
        } catch {
            productsLoadFailed = true
            lastErrorMessage = "商品情報の取得に失敗しました。"
        }
    }

    func purchase(_ product: Product) async {
        purchaseInProgress = true
        defer { purchaseInProgress = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshEntitlements()
                statusMessage = isKanjiUnlocked ? "漢字パックを購入しました。" : nil
            case .userCancelled:
                break
            case .pending:
                statusMessage = "購入の承認待ちです。承認されると漢字パックが解放されます。"
            @unknown default:
                break
            }
        } catch {
            lastErrorMessage = "購入処理に失敗しました。"
        }
    }

    func restorePurchases() async {
        restoreInProgress = true
        defer { restoreInProgress = false }

        do {
            try await AppStore.sync()
            await refreshEntitlements()
            statusMessage = isKanjiUnlocked
                ? "購入を復元しました。"
                : "復元できる購入が見つかりませんでした。"
        } catch {
            lastErrorMessage = "購入の復元に失敗しました。"
        }
    }

    func refreshEntitlements() async {
        var unlocked = false

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            if SubscriptionProductID.all.contains(transaction.productID) {
                unlocked = true
            }
        }

        #if DEBUG
        if debugUnlockKanji {
            unlocked = true
        }
        #endif

        isKanjiUnlocked = unlocked
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw StoreKitError.unknown
        }
    }
}
