import StoreKit
import SwiftUI

struct TopicsScreen: View {
    let model: OnboardingModel

    var body: some View {
        ScrollingScreen {
            VStack(spacing: 0) {
                Text("Which topics do you\nwant to follow?")
                    .titleStyle()
                    .padding(.top, 15)
                    .padding(.bottom, 31)

                FlowLayout(spacing: 14) {
                    ForEach(OnboardingContent.topics, id: \.self) { topic in
                        let selected = model.selected(topic, in: .topics)
                        Button {
                            model.toggle(topic, in: .topics)
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: selected ? "checkmark" : "plus")
                                    .font(.system(size: 16, weight: .medium))
                                Text(topic)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                        .buttonStyle(ChoiceButtonStyle(selected: selected))
                        .accessibilityAddTraits(selected ? .isSelected : [])
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } footer: {
            VStack(spacing: 14) {
                Text("Try it for free")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.motivaMuted)
                Button("Continue") { model.advance(from: .topics) }.buttonStyle(.primary)
            }
        }
    }
}

struct PlanScreen: View {
    let model: OnboardingModel

    private static func listText(_ items: [String], fallback: String) -> String {
        switch items.count {
        case 0: fallback
        case 1, 2: items.joined(separator: ", ")
        default: "\(items.prefix(2).joined(separator: ", ")), and \(items.count - 2) more"
        }
    }

    private var remindersText: String {
        let start = model.reminderStart.formatted(date: .omitted, time: .shortened)
        let end = model.reminderEnd.formatted(date: .omitted, time: .shortened)
        return "\(model.dailyQuoteCount) daily, from \(start) to \(end)"
    }

    var body: some View {
        ScrollingScreen {
            VStack(spacing: 0) {
                Text("Your personalized\nplan is ready")
                    .titleStyle()
                    .padding(.top, 60)

                Text("Enjoy it for free with a 3-day trial")
                    .font(.system(size: 17))
                    .foregroundStyle(Color.motivaMuted)
                    .padding(.top, 6)
                    .padding(.bottom, 30)

                VStack(alignment: .leading, spacing: 32) {
                    row("target", title: "What you want to achieve", value: Self.listText(model.selections[.goals] ?? [], fallback: "Find happiness"))
                    row("square.grid.2x2", title: "Topics of interest", value: Self.listText(model.selections[.topics] ?? [], fallback: "Motivation"))
                    row("bell", title: "Your reminders", value: remindersText)
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 46)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.motivaCard, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
        } footer: {
            Button("Continue") { model.advance(from: .plan) }.buttonStyle(.primary)
        }
    }

    private func row(_ symbol: String, title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 20) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .light))
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.motivaMuted)
                Text(value)
                    .font(.motivaBody)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct TrialOfferScreen: View {
    @Binding var trialReminder: Bool
    let onClose: () -> Void

    @Environment(SubscriptionStore.self) private var store
    @AppStorage("hasSeenSpecialOffer") private var hasSeenSpecialOffer = false

    private enum PaywallAlert: Identifiable {
        case restored(Bool), failed(String), legal(String)

        var id: String {
            switch self {
            case .restored: "restored"
            case .failed(let message): message
            case .legal(let title): title
            }
        }
    }

    @State private var alert: PaywallAlert?
    @State private var plan: SubscriptionPlan = .yearly
    @State private var purchasing = false
    @State private var showsSpecialOffer = false

    @State private var appeared = false
    @State private var shine = false

    /// Entrance timing in seconds, sequenced top to bottom with the purchase button last.
    private enum Reveal {
        static let start = 0.3
        static let close = start
        static let title = start + 0.1
        static func milestone(_ index: Int) -> Double { start + 0.35 + Double(index) * 0.22 }
        static let plans = milestone(4)
        static let toggle = plans + 0.1
        static let price = toggle + 0.12
        static let links = price + 0.1
        static let button = links + 0.18
    }

    private struct Milestone {
        let symbol: String
        let title: String
        let description: String
        var completed = false
        var member = false
    }

    private static func dateLabel(daysFromNow days: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: days, to: .now) ?? .now
        return date.formatted(.dateTime.day(.twoDigits).month(.abbreviated))
    }

    private var product: Product? { store.product(plan) }
    private var trialDays: Int? { store.freeTrial(for: plan)?.days }

    private var milestones: [Milestone] {
        let installed = Milestone(symbol: "checkmark.circle", title: "Install the app", description: "Set it up to match your goals", completed: true)
        if let days = trialDays {
            return [
                installed,
                Milestone(symbol: "lock.open", title: "Today - Free trial starts", description: "Enjoy full access, totally free for your first \(days) days"),
                Milestone(symbol: "bell", title: "\(Self.dateLabel(daysFromNow: days - 1)) - Trial reminder", description: "To let you know it’s ending soon"),
                Milestone(symbol: "crown", title: "\(Self.dateLabel(daysFromNow: days)) - Become member", description: "Your trial ends unless canceled", member: true),
            ]
        }
        return [
            installed,
            Milestone(symbol: "lock.open", title: "Today - Premium unlocked", description: "Every quote, topic and theme"),
            Milestone(symbol: "arrow.clockwise", title: plan == .monthly ? "Renews monthly" : "Renews yearly", description: "Cancel anytime in Settings"),
            Milestone(symbol: "crown", title: "Become member", description: "Grow a little every day", member: true),
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.system(size: 22, weight: .light))
                    .frame(width: 44, height: 44, alignment: .leading)
            }
            .buttonStyle(.quiet(.motivaForeground))
            .accessibilityLabel("Close upgrade")
            .frame(maxWidth: .infinity, alignment: .leading)
            .reveal(appeared, delay: Reveal.close)

            ScrollingScreen {
                VStack(spacing: 0) {
                    Text(trialDays == nil ? "Upgrade to Motiva Premium" : "Upgrade Motiva for free")
                        .font(.system(size: 25, weight: .bold))
                        .multilineTextAlignment(.center)
                        .padding(.top, 10)
                        .reveal(appeared, delay: Reveal.title)

                    VStack(alignment: .leading, spacing: 21) {
                        ForEach(Array(milestones.enumerated()), id: \.offset) { index, milestone in
                            timelineRow(milestone, index: index, isLast: index == milestones.count - 1)
                        }
                    }
                    .padding(.top, 50)
                    .padding(.bottom, 20)
                }
            } footer: {
                footer
            }
        }
        .animation(.easeInOut(duration: 0.25), value: plan)
        .onAppear { appeared = true }
        .task { if store.products.isEmpty { await store.load() } }
        .fullScreenCover(isPresented: $showsSpecialOffer, onDismiss: onClose) {
            SpecialOfferScreen(trialReminder: trialReminder)
        }
        .alert(item: $alert) { alert in
            switch alert {
            case .restored(let found):
                found
                    ? Alert(title: Text("Purchases restored"), message: Text("Motiva Premium is active again."), dismissButton: .default(Text("Continue"), action: onClose))
                    : Alert(title: Text("No purchases to restore"), message: Text("There are no previous purchases on this Apple Account."))
            case .failed(let message):
                Alert(title: Text("Something went wrong"), message: Text(message))
            case .legal(let title):
                Alert(title: Text(title), message: Text("Motiva’s legal documents haven’t been added yet."))
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(Reveal.button + 0.55))
            withAnimation(.easeInOut(duration: 0.9)) { shine = true }
        }
    }

    private func close() {
        if !store.isPremium, !hasSeenSpecialOffer, store.product(.yearlySpecial) != nil {
            hasSeenSpecialOffer = true
            showsSpecialOffer = true
        } else {
            onClose()
        }
    }

    private func subscribe() {
        let trialDays = trialDays
        Task {
            purchasing = true
            defer { purchasing = false }
            do {
                guard try await store.purchase(plan) == .purchased else { return }
                await store.refreshEntitlements()
                if trialReminder, let trialDays {
                    await ReminderScheduler.scheduleTrialReminder(trialDays: trialDays)
                }
                onClose()
            } catch {
                alert = .failed(error.localizedDescription)
            }
        }
    }

    private func restore() {
        Task {
            do {
                alert = .restored(try await store.restore())
            } catch {
                alert = .failed(error.localizedDescription)
            }
        }
    }

    private func timelineRow(_ milestone: Milestone, index: Int, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 17) {
            Image(systemName: milestone.symbol)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(milestone.member ? Color.white : Color.motivaForeground)
                .frame(width: 46, height: 46)
                .background(milestone.member ? Color.motivaPrimary : Color.motivaBackground, in: Circle())
                .overlay(Circle().strokeBorder(Color.motivaForeground, lineWidth: 2))

            VStack(alignment: .leading, spacing: 7) {
                Text(milestone.title)
                    .font(.system(size: 20, weight: .bold))
                    .strikethrough(milestone.completed)
                Text(milestone.description)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.motivaMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(alignment: .topLeading) {
            if !isLast {
                Rectangle()
                    .fill(Color.motivaForeground)
                    .frame(width: 3)
                    .frame(maxHeight: .infinity)
                    .scaleEffect(x: 1, y: appeared ? 1 : 0, anchor: .top)
                    .animation(.easeInOut(duration: 0.3).delay(Reveal.milestone(index) + 0.18), value: appeared)
                    .padding(.top, 45)
                    .padding(.bottom, -23)
                    .offset(x: 21.5)
            }
        }
        .reveal(appeared, delay: Reveal.milestone(index))
        .accessibilityElement(children: .combine)
    }

    private var footer: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                PlanCard(title: "Yearly", detail: store.product(.yearly).map { "\($0.monthlyEquivalent)/month" },
                         badge: savingsBadge, selected: plan == .yearly) { plan = .yearly }
                PlanCard(title: "Monthly", detail: store.product(.monthly).map { "\($0.displayPrice)/month" },
                         selected: plan == .monthly) { plan = .monthly }
            }
            .sensoryFeedback(.selection, trigger: plan)
            .reveal(appeared, delay: Reveal.plans)
            .padding(.bottom, 14)

            if trialDays != nil {
                Toggle("Reminder before trial ends", isOn: $trialReminder)
                    .font(.motivaBody)
                    .tint(Color.motivaPrimary)
                    .padding(16)
                    .background(Color.motivaCard, in: Capsule())
                    .reveal(appeared, delay: Reveal.toggle)
                    .padding(.bottom, 17)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Button(action: subscribe) {
                if purchasing {
                    ProgressView().tint(.white)
                } else {
                    Text(buttonTitle)
                }
            }
            .buttonStyle(.primary)
            .disabled(product == nil || purchasing)
            .overlay { ShineSweep(active: shine) }
            .shadow(color: .black.opacity(0.08), radius: 40, y: 24)
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.94)
            .animation(.spring(duration: 0.6, bounce: 0.25).delay(Reveal.button), value: appeared)

            priceLine
                .font(.system(size: 17))
                .multilineTextAlignment(.center)
                .frame(minHeight: 44)
                .padding(.top, 13)
                .padding(.bottom, 22)
                .reveal(appeared, delay: Reveal.price)

            HStack {
                Button("Restore", action: restore)
                Spacer()
                Button("Terms & Conditions") { alert = .legal("Terms & Conditions") }
                Spacer()
                Button("Privacy Policy") { alert = .legal("Privacy Policy") }
            }
            .font(.system(size: 12))
            .buttonStyle(.quiet(.motivaForeground))
            .reveal(appeared, delay: Reveal.links)
        }
    }

    private var buttonTitle: String {
        guard let product else { return "Loading…" }
        return trialDays == nil ? "Subscribe" : "Try for \(Decimal.zero.formatted(product.priceFormatStyle))"
    }

    private var savingsBadge: String? {
        guard let yearly = store.product(.yearly), let monthly = store.product(.monthly), monthly.price > 0 else { return nil }
        let saving = 1 - NSDecimalNumber(decimal: yearly.price).doubleValue / (NSDecimalNumber(decimal: monthly.price).doubleValue * 12)
        return saving > 0.05 ? "SAVE \(Int((saving * 100).rounded()))%" : nil
    }

    @ViewBuilder private var priceLine: some View {
        if let product {
            switch (plan, trialDays) {
            case (.monthly, _):
                Text("Billed monthly at ") + Text("\(product.displayPrice)/month").fontWeight(.semibold) + Text(".\nCancel anytime.")
            case (_, let days?):
                Text("\(days) days free, then \(product.monthlyEquivalent)/month,\nbilled yearly as ") + Text("\(product.displayPrice)/year").fontWeight(.semibold)
            default:
                Text("\(product.monthlyEquivalent)/month, billed yearly as\n") + Text("\(product.displayPrice)/year").fontWeight(.semibold)
            }
        } else if store.isLoading {
            ProgressView()
        } else {
            Button("Couldn’t load prices. Tap to retry.") { Task { await store.load() } }
                .buttonStyle(.quiet(.motivaMuted))
        }
    }
}

private struct PlanCard: View {
    let title: String
    let detail: String?
    var badge: String?
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 17, weight: .semibold))
                Text(detail ?? " ")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.motivaMuted)
                    .redacted(reason: detail == nil ? .placeholder : [])
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.motivaCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(selected ? Color.motivaForeground : Color.motivaBorder, lineWidth: selected ? 2 : 1)
            }
            .overlay(alignment: .topTrailing) {
                if let badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.motivaPrimary, in: Capsule())
                        .offset(x: -10, y: -9)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// Shown once, when someone closes the paywall without subscribing.
struct SpecialOfferScreen: View {
    let trialReminder: Bool

    @Environment(SubscriptionStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var appeared = false
    @State private var purchasing = false
    @State private var errorMessage: String?

    private var special: Product? { store.product(.yearlySpecial) }
    private var regular: Product? { store.product(.yearly) }
    private var trialDays: Int? { store.freeTrial(for: .yearlySpecial)?.days }

    private var discount: Int? {
        guard let special, let regular, regular.price > 0 else { return nil }
        let ratio = NSDecimalNumber(decimal: special.price).doubleValue / NSDecimalNumber(decimal: regular.price).doubleValue
        return Int(((1 - ratio) * 100).rounded())
    }

    var body: some View {
        VStack(spacing: 0) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 22, weight: .light))
                    .frame(width: 44, height: 44, alignment: .leading)
            }
            .buttonStyle(.quiet(.motivaForeground))
            .accessibilityLabel("Close offer")
            .frame(maxWidth: .infinity, alignment: .leading)
            .reveal(appeared, delay: 0.2)

            Spacer()

            Text("ONE-TIME OFFER")
                .font(.system(size: 13, weight: .bold))
                .tracking(2)
                .foregroundStyle(Color.motivaMuted)
                .reveal(appeared, delay: 0.3)

            Text(discount.map { "\($0)% off\nMotiva Premium" } ?? "Motiva Premium")
                .font(.system(size: 40, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.top, 14)
                .reveal(appeared, delay: 0.42)

            if let special {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    if let regular {
                        Text(regular.displayPrice)
                            .font(.system(size: 22))
                            .strikethrough()
                            .foregroundStyle(Color.motivaMuted)
                    }
                    Text("\(special.displayPrice)/year")
                        .font(.system(size: 28, weight: .bold))
                }
                .padding(.top, 30)
                .reveal(appeared, delay: 0.56)

                Text("Just \(special.monthlyEquivalent)/month")
                    .font(.system(size: 17))
                    .foregroundStyle(Color.motivaMuted)
                    .padding(.top, 6)
                    .reveal(appeared, delay: 0.64)
            }

            Spacer()

            Button(action: claim) {
                if purchasing {
                    ProgressView().tint(.white)
                } else {
                    Text(trialDays.map { "Start \($0)-day free trial" } ?? "Claim offer")
                }
            }
            .buttonStyle(.primary)
            .disabled(special == nil || purchasing)
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.94)
            .animation(.spring(duration: 0.6, bounce: 0.25).delay(0.85), value: appeared)

            Group {
                if let special {
                    Text(trialDays.map { "\($0) days free, then \(special.displayPrice)/year. Cancel anytime." }
                         ?? "Billed yearly at \(special.displayPrice). Cancel anytime.")
                }
                Text("This offer won’t be shown again.")
                    .foregroundStyle(Color.motivaMuted)
            }
            .font(.system(size: 14))
            .multilineTextAlignment(.center)
            .padding(.top, 10)
            .reveal(appeared, delay: 0.75)
            .padding(.bottom, 8)
        }
        .padding(.horizontal, Metrics.screenPadding)
        .foregroundStyle(Color.motivaForeground)
        .background(Color.motivaBackground.ignoresSafeArea())
        .environment(\.colorScheme, .light)
        .onAppear { appeared = true }
        .alert("Something went wrong", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func claim() {
        let trialDays = trialDays
        Task {
            purchasing = true
            defer { purchasing = false }
            do {
                guard try await store.purchase(.yearlySpecial) == .purchased else { return }
                await store.refreshEntitlements()
                if trialReminder, let trialDays {
                    await ReminderScheduler.scheduleTrialReminder(trialDays: trialDays)
                }
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

/// A soft highlight that sweeps once across its container when `active` turns on.
private struct ShineSweep: View {
    let active: Bool

    var body: some View {
        GeometryReader { proxy in
            LinearGradient(
                colors: [.white.opacity(0), .white.opacity(0.35), .white.opacity(0)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: proxy.size.width * 0.35)
            .rotationEffect(.degrees(18))
            .offset(x: active ? proxy.size.width * 1.2 : -proxy.size.width * 0.5)
        }
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous))
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct WidgetScreen: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text("Add a free widget to your\nHome Screen")
                .titleStyle()
                .padding(.top, 60)

            Text("On your phone’s Home Screen, touch and hold an empty area, then tap Edit")
                .font(.motivaBody)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.top, 23)

            WidgetArt()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.horizontal, 20)
                .padding(.top, 40)
                .padding(.bottom, 28)

            VStack(spacing: 27) {
                Button("Install widget", action: onContinue).buttonStyle(.primary)
                Button("Remind me later", action: onContinue)
                    .font(.system(size: 18, weight: .bold))
                    .buttonStyle(.quiet(.motivaForeground))
            }
            .padding(.bottom, 16)
        }
    }
}
