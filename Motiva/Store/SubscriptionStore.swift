import Foundation
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

/// Loads plans, buys and restores them, and tracks whether Premium is active.
@Observable
final class SubscriptionStore {
    private(set) var products: [SubscriptionPlan: Product] = [:]
    private(set) var trialEligible: Set<SubscriptionPlan> = []
    private(set) var isPremium = false
    private(set) var isLoading = false

    @ObservationIgnored private var transactionUpdates: Task<Void, Never>?

    init() {
        transactionUpdates = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result { await transaction.finish() }
                await self?.refreshEntitlements()
            }
        }
    }

    func product(_ plan: SubscriptionPlan) -> Product? { products[plan] }

    /// Length of the plan's free trial, if the user can still get one.
    func freeTrial(for plan: SubscriptionPlan) -> Product.SubscriptionPeriod? {
        guard trialEligible.contains(plan),
              let offer = products[plan]?.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial else { return nil }
        return offer.period
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        if let loaded = try? await Product.products(for: SubscriptionPlan.allCases.map(\.rawValue)) {
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
        await refreshEntitlements()
    }

    func purchase(_ plan: SubscriptionPlan) async throws -> PurchaseOutcome {
        guard let product = products[plan] else { throw StoreError.productUnavailable }
        switch try await product.purchase() {
        case .success(let verification):
            guard case .verified(let transaction) = verification else { throw StoreError.unverified }
            await transaction.finish()
            trialEligible.removeAll()
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
        try await AppStore.sync()
        await refreshEntitlements()
        return isPremium
    }

    func refreshEntitlements() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               SubscriptionPlan(rawValue: transaction.productID) != nil,
               transaction.revocationDate == nil {
                active = true
            }
        }
        isPremium = active
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
