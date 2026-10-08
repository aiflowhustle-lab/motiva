import StoreKit
import SwiftUI

struct MembershipStatusCard: View {
    @Environment(SubscriptionStore.self) private var store
    @State private var showsManageSubscriptions = false
    @State private var showsPaywall = false

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: store.isPremium ? "crown.fill" : "crown")
                .font(.system(size: 28, weight: .light))
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(store.isPremium ? "Motiva Premium" : "Free plan")
                    .font(.system(size: 20, weight: .bold))
                Text(store.isPremium ? "Active — all topics & themes unlocked" : "Upgrade for full access")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.sheetMuted)
            }

            Spacer(minLength: 8)

            if store.isPremium {
                Button("Manage") { showsManageSubscriptions = true }
                    .font(.system(size: 15, weight: .semibold))
                    .buttonStyle(.quiet(.motivaForeground))
            } else {
                Button("Upgrade") { showsPaywall = true }
                    .font(.system(size: 15, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.motivaPrimary, in: Capsule())
                    .foregroundStyle(.white)
            }
        }
        .padding(20)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .task { await store.refreshEntitlements() }
        .manageSubscriptionsSheet(isPresented: $showsManageSubscriptions)
        .fullScreenCover(isPresented: $showsPaywall) {
            PaywallView { showsPaywall = false }
        }
    }
}
