import SwiftUI

enum ProfileDestination: Hashable {
    case topics, wallpapers, reminders, settings
}

struct ProfileView: View {
    @Environment(AppState.self) private var app
    var onDone: () -> Void

    @State private var comingSoon: String?

    private var streakShareText: String {
        app.streakCount == 1
            ? "I just started a daily streak with Motiva."
            : "I’m on a \(app.streakCount)-day streak with Motiva."
    }

    var body: some View {
        SheetPage(title: "Profile") {
            VStack(spacing: 0) {
                MembershipStatusCard()
                    .padding(.top, 8)

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Your streak").font(.system(size: 22, weight: .bold))
                        Spacer()
                        ShareLink(item: streakShareText) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 20, weight: .regular))
                        }
                        .accessibilityLabel("Share streak")
                    }
                    StreakWeek(count: app.streakCount)
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 20)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .padding(.top, 20)

                SectionTitle(text: "Customize the app")

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 18), GridItem(.flexible(), spacing: 18)], spacing: 18) {
                    ForEach(TileKind.allCases) { kind in
                        tile(kind)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { SheetCloseButton(action: onDone) }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: ProfileDestination.settings) {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Settings")
            }
        }
        .navigationDestination(for: ProfileDestination.self) { destination in
            switch destination {
            case .topics: TopicsView(showsClose: false, onDone: onDone)
            case .wallpapers: WallpapersView(showsClose: false, onDone: onDone)
            case .reminders: ReminderSettingsView()
            case .settings: SettingsView()
            }
        }
        .alert(comingSoon ?? "", isPresented: Binding(get: { comingSoon != nil }, set: { if !$0 { comingSoon = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("This is coming soon to Motiva.")
        }
    }

    @ViewBuilder
    private func tile(_ kind: TileKind) -> some View {
        let label = VStack(spacing: 16) {
            TileArt(kind: kind)
                .frame(maxHeight: .infinity)
            Text(kind.title)
                .font(.system(size: 19))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 23)
        .frame(maxWidth: .infinity)
        .frame(height: 210)

        switch kind {
        case .topics:
            NavigationLink(value: ProfileDestination.topics) { label }.buttonStyle(CardButtonStyle())
        case .wallpapers:
            NavigationLink(value: ProfileDestination.wallpapers) { label }.buttonStyle(CardButtonStyle())
        case .reminders:
            NavigationLink(value: ProfileDestination.reminders) { label }.buttonStyle(CardButtonStyle())
        default:
            Button { comingSoon = kind.title } label: { label }.buttonStyle(CardButtonStyle())
        }
    }
}

struct WallpapersView: View {
    @Environment(AppState.self) private var app
    var showsClose = true
    var onDone: () -> Void

    var body: some View {
        SheetPage(title: "Wallpapers") {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 18), GridItem(.flexible(), spacing: 18)], spacing: 18) {
                ForEach(FeedTheme.allCases) { theme in
                    let selected = app.theme == theme
                    Button {
                        app.theme = theme
                        onDone()
                    } label: {
                        VStack(spacing: 14) {
                            Text("Make room\nfor yourself.")
                                .font(.system(size: 25))
                                .multilineTextAlignment(.center)
                            HStack(spacing: 4) {
                                Text(theme.name)
                                if selected { Image(systemName: "checkmark").fontWeight(.bold) }
                            }
                            .font(.system(size: 17))
                            .opacity(0.7)
                        }
                        .foregroundStyle(theme.foreground)
                        .frame(maxWidth: .infinity)
                        .frame(height: 230)
                        .background(theme.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .strokeBorder(selected ? Color.motivaForeground : Color(hex: 0xC7C7C7), lineWidth: selected ? 2.5 : (theme == .paper ? 1 : 0))
                        }
                    }
                    .buttonStyle(PressableButtonStyle())
                    .accessibilityLabel("\(theme.name) theme")
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            .padding(.top, 8)
        }
        .toolbar {
            if showsClose {
                ToolbarItem(placement: .topBarLeading) { SheetCloseButton(action: onDone) }
            }
        }
    }
}

struct ReminderSettingsView: View {
    @Environment(AppState.self) private var app
    @Environment(\.openURL) private var openURL
    @State private var denied = false

    var body: some View {
        @Bindable var app = app
        Form {
            if denied {
                Section {
                    Button("Turn on notifications in Settings") {
                        if let url = URL(string: UIApplication.openNotificationSettingsURLString) { openURL(url) }
                    }
                } footer: {
                    Text("Notifications for Motiva are turned off, so reminders can’t be delivered.")
                }
            }

            Section {
                Toggle("Daily reminders", isOn: $app.reminders.enabled)
            }

            if app.reminders.enabled {
                Section {
                    Stepper(value: $app.reminders.count, in: 1...30) {
                        LabeledContent("How many", value: "\(app.reminders.count)x")
                    }
                    DatePicker("Start at", selection: $app.reminders.start, displayedComponents: .hourAndMinute)
                    DatePicker("End at", selection: $app.reminders.end, displayedComponents: .hourAndMinute)
                } footer: {
                    Text("Quotes are spread evenly between the start and end times.")
                }
            }
        }
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.default, value: app.reminders.enabled)
        .task { denied = await ReminderScheduler.isDenied() }
        .task(id: app.reminders) {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            await ReminderScheduler.schedule(app.reminders, quotes: QuoteLibrary.quotes(for: app.topic).shuffled())
        }
    }
}

struct SettingsView: View {
    @Environment(AppState.self) private var app
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @State private var notice: String?

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        Form {
            Section {
                NavigationLink("Reminders", value: ProfileDestination.reminders)
            }
            Section {
                Button("Restore purchases") { notice = "No purchases to restore" }
                Button("Terms & Conditions") { notice = "Terms & Conditions" }
                Button("Privacy Policy") { notice = "Privacy Policy" }
            }
            Section {
                LabeledContent("Version", value: version)
            }
            #if DEBUG
            Section("Developer") {
                Button("Restart onboarding", role: .destructive) {
                    app.reset()
                    UserDefaults.standard.removeObject(forKey: OnboardingProfile.storageKey)
                    hasCompletedOnboarding = false
                }
            }
            #endif
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert(notice ?? "", isPresented: Binding(get: { notice != nil }, set: { if !$0 { notice = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(notice == "No purchases to restore" ? "There are no previous purchases on this account." : "Motiva’s legal documents haven’t been added yet.")
        }
    }
}
