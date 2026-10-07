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

    private enum PaywallAlert: Identifiable {
        case trial, restore, legal(String)

        var id: String {
            switch self {
            case .trial: "trial"
            case .restore: "restore"
            case .legal(let title): title
            }
        }
    }

    @State private var alert: PaywallAlert?

    @State private var appeared = false
    @State private var shine = false

    /// Entrance timing in seconds, sequenced top to bottom with the purchase button last.
    private enum Reveal {
        static let start = 0.3
        static let close = start
        static let title = start + 0.1
        static func milestone(_ index: Int) -> Double { start + 0.35 + Double(index) * 0.22 }
        static let toggle = milestone(4)
        static let price = toggle + 0.12
        static let links = price + 0.1
        static let button = links + 0.18
    }

    private struct Milestone: Identifiable {
        let symbol: String
        let title: String
        let description: String
        var completed = false
        var member = false
        var id: String { title }
    }

    private static func dateLabel(daysFromNow days: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: days, to: .now) ?? .now
        return date.formatted(.dateTime.day(.twoDigits).month(.abbreviated))
    }

    private var milestones: [Milestone] {
        [
            Milestone(symbol: "checkmark.circle", title: "Install the app", description: "Set it up to match your goals", completed: true),
            Milestone(symbol: "lock.open", title: "Today - Free trial starts", description: "Enjoy full access, totally free for your first 3 days"),
            Milestone(symbol: "bell", title: "\(Self.dateLabel(daysFromNow: 2)) - Trial reminder", description: "To let you know it’s ending soon"),
            Milestone(symbol: "crown", title: "\(Self.dateLabel(daysFromNow: 3)) - Become member", description: "Your trial ends unless canceled", member: true),
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onClose) {
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
                    Text("Upgrade Motiva for free")
                        .font(.system(size: 25, weight: .bold))
                        .multilineTextAlignment(.center)
                        .padding(.top, 10)
                        .reveal(appeared, delay: Reveal.title)

                    VStack(alignment: .leading, spacing: 21) {
                        ForEach(Array(milestones.enumerated()), id: \.element.id) { index, milestone in
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
        .onAppear { appeared = true }
        .alert(item: $alert) { alert in
            switch alert {
            case .trial:
                Alert(
                    title: Text("Free trial preview"),
                    message: Text("Subscriptions aren’t set up yet, so no trial will start and you won’t be charged."),
                    dismissButton: .default(Text("Continue"), action: onClose)
                )
            case .restore:
                Alert(title: Text("No purchases to restore"), message: Text("There are no previous purchases on this account."))
            case .legal(let title):
                Alert(title: Text(title), message: Text("Motiva’s legal documents haven’t been added yet."))
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(Reveal.button + 0.55))
            withAnimation(.easeInOut(duration: 0.9)) { shine = true }
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
            Toggle("Reminder before trial ends", isOn: $trialReminder)
                .font(.motivaBody)
                .tint(Color.motivaPrimary)
                .padding(16)
                .background(Color.motivaCard, in: Capsule())
                .reveal(appeared, delay: Reveal.toggle)
                .padding(.bottom, 17)

            Button("Try for $0.00") { alert = .trial }
                .buttonStyle(.primary)
                .overlay { ShineSweep(active: shine) }
                .shadow(color: .black.opacity(0.08), radius: 40, y: 24)
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.94)
                .animation(.spring(duration: 0.6, bounce: 0.25).delay(Reveal.button), value: appeared)

            (Text("$1.66/month, billed yearly as\n") + Text("$19.99/year").fontWeight(.semibold))
                .font(.system(size: 17))
                .multilineTextAlignment(.center)
                .padding(.top, 13)
                .padding(.bottom, 28)
                .reveal(appeared, delay: Reveal.price)

            HStack {
                Button("Restore") { alert = .restore }
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
