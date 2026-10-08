import Foundation
import RevenueCat
import StoreKit

/// Products in the "Motiva Premium" subscription group. IDs must match App Store Connect.
enum SubscriptionPlan: String, CaseIterable, Identifiable {
    case yearly = "com.motiva.dailyquotes.yearly"
    case monthly = "com.motiva.dailyquotes.monthly"
    /// Discounted yearly plan, offered once to people who close the paywall without subscribing.
    case yearlySpecial = "com.motiva.dailyquotes.yearly.special"

    var id: String { rawValue }
}

enum PurchaseOutcome: Equatable {
    case purchased, cancelled, pending
}

enum StoreError: LocalizedError {
    case productUnavailable, unverified

    var errorDescription: String? {
        switch self {
        case .productUnavailable: "This plan isn’t available right now. Check your connection and try again."
        case .unverified: "The App Store couldn’t verify this purchase."
        }
    }
}

/// Loads plans via RevenueCat, handles purchases, and tracks the `premium` entitlement.
@Observable
@MainActor
final class SubscriptionStore: NSObject {
    private(set) var products: [SubscriptionPlan: Product] = [:]
    private(set) var trialEligible: Set<SubscriptionPlan> = []
    private(set) var isPremium = false
    private(set) var isLoading = false

    @ObservationIgnored private var packages: [SubscriptionPlan: Package] = [:]
    @ObservationIgnored private var configured = false

    override init() {
        super.init()
    }

    static func configureRevenueCat() {
        guard !Purchases.isConfigured else { return }
        #if DEBUG
        Purchases.logLevel = .debug
        #endif
        Purchases.configure(withAPIKey: RevenueCatConfiguration.publicAPIKey)
    }

    func product(_ plan: SubscriptionPlan) -> Product? { products[plan] }

    /// Length of the plan's free trial, if the user can still get one.
    func freeTrial(for plan: SubscriptionPlan) -> Product.SubscriptionPeriod? {
        guard trialEligible.contains(plan),
              let offer = products[plan]?.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial else { return nil }
        return offer.period
    }

    /// Trial length configured in App Store Connect (for display), even if this Apple ID already used it.
    func introTrialDays(for plan: SubscriptionPlan) -> Int? {
        guard let offer = products[plan]?.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial else { return nil }
        return offer.period.days
    }

    func load() async {
        if !configured {
            Purchases.shared.delegate = self
            configured = true
        }

        isLoading = true
        defer { isLoading = false }

        async let offeringsTask: Void = fetchOfferings()
        async let productsTask: Void = fetchStoreProducts()
        _ = await (offeringsTask, productsTask)
        await refreshEntitlements()
    }

    func purchase(_ plan: SubscriptionPlan) async throws -> PurchaseOutcome {
        if let package = packages[plan] {
            let result = try await Purchases.shared.purchase(package: package)
            if result.userCancelled { return .cancelled }
            trialEligible.removeAll()
            await syncAfterPurchase(customerInfo: result.customerInfo)
            return .purchased
        }

        guard let product = products[plan] else { throw StoreError.productUnavailable }
        switch try await product.purchase() {
        case .success(let verification):
            guard case .verified(let transaction) = verification else { throw StoreError.unverified }
            await transaction.finish()
            trialEligible.removeAll()
            _ = try? await Purchases.shared.syncPurchases()
            await refreshEntitlements()
            return .purchased
        case .pending:
            return .pending
        case .userCancelled:
            return .cancelled
        @unknown default:
            return .cancelled
        }
    }

    /// Syncs purchases from the App Store and returns whether Premium is now active.
    func restore() async throws -> Bool {
        let info = try await Purchases.shared.restorePurchases()
        await syncAfterPurchase(customerInfo: info)
        return isPremium
    }

    func refreshEntitlements() async {
        if !configured {
            Purchases.shared.delegate = self
            configured = true
        }
        if Purchases.isConfigured, let info = try? await Purchases.shared.customerInfo(fetchPolicy: .fetchCurrent) {
            apply(customerInfo: info)
        }
        if !isPremium {
            await applyStoreKitEntitlements()
        }
    }

    private func syncAfterPurchase(customerInfo: CustomerInfo) async {
        apply(customerInfo: customerInfo)
        if !isPremium {
            _ = try? await Purchases.shared.syncPurchases()
            if let info = try? await Purchases.shared.customerInfo() {
                apply(customerInfo: info)
            }
        }
        if !isPremium {
            await applyStoreKitEntitlements()
        }
    }

    /// Unlocks premium when Apple shows an active subscription, even if RevenueCat entitlements aren’t wired yet.
    private func applyStoreKitEntitlements() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  SubscriptionPlan(rawValue: transaction.productID) != nil,
                  transaction.revocationDate == nil else { continue }
            isPremium = true
            return
        }
    }

    private func fetchOfferings() async {
        guard let offerings = try? await Purchases.shared.offerings() else { return }
        var mapped: [SubscriptionPlan: Package] = [:]

        let defaultOffering = offerings.offering(identifier: RevenueCatConfiguration.defaultOffering) ?? offerings.current
        defaultOffering?.availablePackages.forEach { package in
            if let plan = SubscriptionPlan(rawValue: package.storeProduct.productIdentifier) {
                mapped[plan] = package
            }
        }

        offerings.offering(identifier: RevenueCatConfiguration.specialOffering)?.availablePackages.forEach { package in
            if let plan = SubscriptionPlan(rawValue: package.storeProduct.productIdentifier) {
                mapped[plan] = package
            }
        }

        packages = mapped
    }

    private func fetchStoreProducts() async {
        guard let loaded = try? await Product.products(for: SubscriptionPlan.allCases.map(\.rawValue)) else { return }
        var products: [SubscriptionPlan: Product] = [:]
        var eligible: Set<SubscriptionPlan> = []
        for product in loaded {
            guard let plan = SubscriptionPlan(rawValue: product.id) else { continue }
            products[plan] = product
            if await product.subscription?.isEligibleForIntroOffer == true { eligible.insert(plan) }
        }
        self.products = products
        trialEligible = eligible
    }

    private func apply(customerInfo: CustomerInfo) {
        let entitlement = customerInfo.entitlements[RevenueCatConfiguration.premiumEntitlement]?.isActive == true
        let subscribed = SubscriptionPlan.allCases.contains { plan in
            customerInfo.activeSubscriptions.contains(plan.rawValue)
        }
        let anyActiveEntitlement = customerInfo.entitlements.active.values.contains { $0.isActive }
        isPremium = entitlement || subscribed || anyActiveEntitlement
    }
}

extension SubscriptionStore: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            apply(customerInfo: customerInfo)
        }
    }
}

extension Product.SubscriptionPeriod {
    var days: Int {
        switch unit {
        case .day: value
        case .week: value * 7
        case .month: value * 30
        case .year: value * 365
        @unknown default: value
        }
    }
}

extension Product {
    /// The yearly price spread over 12 months, e.g. "$1.66".
    var monthlyEquivalent: String {
        let monthly = (price / 12 as NSDecimalNumber).rounding(accordingToBehavior: NSDecimalNumberHandler(
            roundingMode: .down, scale: 2, raiseOnExactness: false, raiseOnOverflow: false,
            raiseOnUnderflow: false, raiseOnDivideByZero: false
        ))
        return (monthly as Decimal).formatted(priceFormatStyle)
    }
}
