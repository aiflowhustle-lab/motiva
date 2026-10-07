import SwiftUI

struct IntroScreen: View {
    let step: OnboardingStep
    let onContinue: () -> Void
    let onLegal: (String) -> Void

    private var title: String {
        switch step {
        case .welcome: "Get motivation throughout\nthe day"
        case .customize: "Customize the app to\nimprove your experience"
        case .achieve: "Customize the app to what you want to achieve"
        default: "Answer a few questions to\nget personalized quotes"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            art
                .frame(maxWidth: .infinity, minHeight: 190, maxHeight: .infinity)
                .padding(.top, 34)

            VStack(spacing: 18) {
                Text(title).titleStyle()
                if step == .welcome {
                    Text("Inspiration to think positively, stay\nconsistent, and focus on your growth")
                        .font(.motivaBody)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
            }
            .padding(.top, 35)
            .padding(.bottom, 20)

            VStack(spacing: 18) {
                Spacer(minLength: 40)
                Button("Continue", action: onContinue).buttonStyle(.primary)
                if step == .welcome {
                    legalCopy
                }
            }
            .frame(maxHeight: .infinity)
            .padding(.bottom, 8)
        }
    }

    @ViewBuilder
    private var art: some View {
        switch step {
        case .welcome: QuoteMarkArt()
        case .achieve: TargetArt()
        case .quotes: OrbitArt()
        default: CompassArt()
        }
    }

    private var legalCopy: some View {
        var text = AttributedString("By continuing you agree to our ")
        var terms = AttributedString("Terms")
        terms.link = URL(string: "motiva-legal://terms")
        var privacy = AttributedString("Privacy Policy")
        privacy.link = URL(string: "motiva-legal://privacy")
        terms.font = .system(size: 12, weight: .semibold)
        terms.underlineStyle = .single
        privacy.font = .system(size: 12, weight: .semibold)
        privacy.underlineStyle = .single
        text += terms
        text += AttributedString(" and ")
        text += privacy

        return Text(text)
            .font(.system(size: 12))
            .foregroundStyle(Color.motivaMuted)
            .tint(Color.motivaMuted)
            .multilineTextAlignment(.center)
            .environment(\.openURL, OpenURLAction { url in
                onLegal(url.host == "terms" ? "Terms" : "Privacy Policy")
                return .handled
            })
    }
}

struct NameScreen: View {
    @Bindable var model: OnboardingModel
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Text("What do you want to\nbe called?")
                .titleStyle()
                .padding(.top, 15)
                .padding(.bottom, 36)

            TextField("Your name", text: $model.name)
                .font(.motivaBody)
                .textContentType(.givenName)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.continue)
                .focused($focused)
                .onSubmit { model.advance(from: .name) }
                .onChange(of: model.name) { _, value in
                    if value.count > 40 { model.name = String(value.prefix(40)) }
                }
                .padding(.horizontal, 20)
                .frame(height: 60)
                .background(Color.motivaInput, in: RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous)
                        .strokeBorder(focused ? Color.motivaMuted : Color.motivaBorder, lineWidth: 1)
                )

            Spacer()

            Button("Continue") { model.advance(from: .name) }
                .buttonStyle(.primary)
                .padding(.bottom, 8)
        }
        .task {
            try? await Task.sleep(for: .milliseconds(450))
            focused = true
        }
    }
}

struct RoutineScreen: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            FlameArt()
                .frame(maxWidth: .infinity, minHeight: 270, maxHeight: .infinity)

            Text("Stay motivated with a consistent daily routine")
                .titleStyle()
                .padding(.horizontal, 8)
                .padding(.top, 30)
                .padding(.bottom, 28)

            StreakPreview()

            Button("Continue", action: onContinue)
                .buttonStyle(.primary)
                .padding(.top, 50)
                .padding(.bottom, 8)
        }
    }
}

struct RemindersScreen: View {
    @Bindable var model: OnboardingModel
    @State private var requesting = false

    var body: some View {
        ScrollingScreen {
            VStack(spacing: 0) {
                Text("Get quotes\nthroughout the day")
                    .titleStyle()
                    .padding(.top, 44)

                Text("Small doses of motivation can make a big difference in your life")
                    .font(.motivaBody)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)

                NotificationArt()

                HStack(spacing: 7) {
                    Text("How many")
                        .font(.motivaBody)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    StepperButton(systemName: "minus", label: "Fewer quotes", disabled: model.dailyQuoteCount <= 1) {
                        model.dailyQuoteCount -= 1
                    }
                    Text("\(model.dailyQuoteCount)x")
                        .font(.system(size: 16))
                        .monospacedDigit()
                        .frame(width: 65)
                        .contentTransition(.numericText())
                        .accessibilityLabel("\(model.dailyQuoteCount) quotes per day")
                    StepperButton(systemName: "plus", label: "More quotes", disabled: model.dailyQuoteCount >= 30) {
                        model.dailyQuoteCount += 1
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.motivaCard, in: RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous))
                .sensoryFeedback(.selection, trigger: model.dailyQuoteCount)

                VStack(spacing: 0) {
                    timeRow("Start at", selection: $model.reminderStart)
                    Rectangle().fill(Color.motivaBackground).frame(height: 1)
                    timeRow("End at", selection: $model.reminderEnd)
                }
                .background(Color.motivaCard, in: RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous))
                .padding(.top, 13)
            }
        } footer: {
            Button("Allow and Save") {
                requesting = true
                Task {
                    await model.requestNotificationsAndAdvance()
                    requesting = false
                }
            }
            .buttonStyle(.primary)
            .disabled(requesting)
        }
    }

    private func timeRow(_ title: String, selection: Binding<Date>) -> some View {
        HStack {
            Text(title).font(.system(size: 20))
            Spacer()
            DatePicker(title, selection: selection, displayedComponents: .hourAndMinute)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct StepperButton: View {
    let systemName: String
    let label: String
    let disabled: Bool
    let action: () -> Void

    var body: some View {
        Button {
            withAnimation(.snappy) { action() }
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Color.motivaPrimary, in: Circle())
        }
        .buttonStyle(.plain)
        .opacity(disabled ? 0.4 : 1)
        .disabled(disabled)
        .accessibilityLabel(label)
    }
}

struct StatementScreen: View {
    let step: OnboardingStep
    let name: String
    let onContinue: () -> Void

    private var text: String {
        switch step {
        case .meant:
            name.isEmpty ? "You are exactly where you are meant to be." : "You are exactly where you are meant to be, \(name)."
        case .phone:
            "You look at your phone hundreds of times a day. What you see there can change your whole mindset."
        case .freeTrial:
            "With your free trial, you get unlimited free access to everything for 3 days"
        default:
            "On \(Self.trialReminderDate),\nyou get a reminder that\nyour trial ends soon"
        }
    }

    private static var trialReminderDate: String {
        let date = Calendar.current.date(byAdding: .day, value: 2, to: .now) ?? .now
        let month = date.formatted(.dateTime.month(.wide))
        let ordinal = NumberFormatter()
        ordinal.numberStyle = .ordinal
        let day = ordinal.string(from: NSNumber(value: Calendar.current.component(.day, from: date))) ?? ""
        return "\(month) \(day)"
    }

    @State private var typed = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            TypewriterText(text: text, isComplete: $typed)
                .titleStyle()
                .frame(maxWidth: 302)
            Spacer()
            Button("Continue", action: onContinue)
                .buttonStyle(step.usesDarkBackground ? .primaryInverted : .primary)
                .padding(.bottom, 8)
                .opacity(typed ? 1 : 0)
                .offset(y: typed ? 0 : 12)
                .allowsHitTesting(typed)
                .animation(.easeOut(duration: 0.45), value: typed)
        }
        .contentShape(Rectangle())
        .onTapGesture { typed = true }
        .accessibilityAction(named: "Show full text") { typed = true }
    }
}
