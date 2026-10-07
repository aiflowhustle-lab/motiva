import SwiftUI

enum SavedList: String, Hashable, CaseIterable {
    case favorites, collections, own, history

    var title: String {
        switch self {
        case .favorites: "Favorites"
        case .collections: "Collections"
        case .own: "My own quotes"
        case .history: "History"
        }
    }

    var symbol: String {
        switch self {
        case .favorites: "heart"
        case .collections: "bookmark"
        case .own: "pencil.line"
        case .history: "clock.arrow.circlepath"
        }
    }

    var emptyText: String {
        switch self {
        case .favorites: "Tap the heart on a quote to save it here."
        case .collections: "No collections yet."
        case .own: "Your words, your inspiration."
        case .history: "Your recently viewed quotes appear here."
        }
    }
}

struct TopicsView: View {
    @Environment(AppState.self) private var app
    var showsClose = true
    var onDone: () -> Void

    @State private var search = ""

    private var filteredTopics: [QuoteTopic] {
        let query = search.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return QuoteLibrary.topics }
        return QuoteLibrary.topics.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        SheetPage(title: "Explore topics") {
            VStack(spacing: 0) {
                UnlockBanner(
                    title: "Unlock all topics",
                    message: "Browse topics and follow them to customize your feed",
                    symbol: "iphone"
                )
                .padding(.top, 8)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(SavedList.allCases, id: \.self) { list in
                        NavigationLink(value: list) {
                            HStack(alignment: .top) {
                                Text(list.title)
                                    .font(.system(size: 19))
                                    .multilineTextAlignment(.leading)
                                Spacer(minLength: 8)
                                Image(systemName: list.symbol)
                                    .font(.system(size: 24, weight: .light))
                            }
                            .padding(.horizontal, 13)
                            .padding(.vertical, 15)
                            .frame(maxWidth: .infinity, minHeight: 102, alignment: .topLeading)
                        }
                        .buttonStyle(CardButtonStyle(cornerRadius: 18))
                    }
                }
                .padding(.top, 20)

                SectionTitle(text: search.isEmpty ? "Free today" : "Topics")

                VStack(spacing: 14) {
                    if search.isEmpty {
                        topicRow(name: "For you", symbol: "sparkle", selected: app.topic == nil) { app.topic = nil }
                    }
                    ForEach(filteredTopics) { topic in
                        topicRow(name: topic.name, symbol: topic.symbol, selected: app.topic == topic.name) {
                            app.topic = topic.name
                        }
                    }
                    if filteredTopics.isEmpty {
                        Text("No topics match “\(search)”")
                            .foregroundStyle(Color.sheetMuted)
                            .padding(.vertical, 30)
                    }
                }
            }
        }
        .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search topics")
        .toolbar {
            if showsClose {
                ToolbarItem(placement: .topBarLeading) { SheetCloseButton(action: onDone) }
            }
        }
        .navigationDestination(for: SavedList.self) { SavedQuotesView(list: $0) }
    }

    private func topicRow(name: String, symbol: String, selected: Bool, select: @escaping () -> Void) -> some View {
        Button {
            select()
            onDone()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 22, weight: .light))
                    .frame(width: 30)
                Text(name)
                    .font(.system(size: 21))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: selected ? "checkmark" : "chevron.right")
                    .font(.system(size: 16, weight: selected ? .bold : .regular))
                    .foregroundStyle(selected ? Color.motivaForeground : Color.sheetMuted)
            }
            .padding(.horizontal, 17)
            .frame(minHeight: 78)
        }
        .buttonStyle(CardButtonStyle(cornerRadius: 20))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

struct SavedQuotesView: View {
    @Environment(AppState.self) private var app
    let list: SavedList

    @State private var draft = ""
    @FocusState private var editing: Bool

    private var quotes: [String] {
        switch list {
        case .favorites: Array(app.favorites.reversed())
        case .collections: []
        case .own: Array(app.ownQuotes.reversed())
        case .history: app.history
        }
    }

    var body: some View {
        List {
            if list == .own {
                Section {
                    TextField("Write your quote", text: $draft, axis: .vertical)
                        .font(.system(size: 18))
                        .lineLimit(3...6)
                        .focused($editing)
                    Button {
                        app.ownQuotes.append(draft.trimmingCharacters(in: .whitespacesAndNewlines))
                        draft = ""
                        editing = false
                    } label: {
                        Label("Add quote", systemImage: "plus")
                    }
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            Section {
                ForEach(quotes, id: \.self) { quote in
                    Text(quote.replacingOccurrences(of: "\n", with: " "))
                        .font(.system(size: 20))
                        .lineSpacing(4)
                        .padding(.vertical, 8)
                }
                .onDelete(perform: deleteAction)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.sheetBackground)
        .overlay {
            if quotes.isEmpty && list != .own {
                ContentUnavailableView(list.title, systemImage: list.symbol, description: Text(list.emptyText))
            }
        }
        .navigationTitle(list.title)
        .navigationBarTitleDisplayMode(.large)
    }

    private var deleteAction: ((IndexSet) -> Void)? {
        list == .collections ? nil : { delete(at: $0) }
    }

    private func delete(at offsets: IndexSet) {
        let removed = offsets.map { quotes[$0] }
        switch list {
        case .favorites: app.favorites.removeAll { removed.contains($0) }
        case .own: app.ownQuotes.removeAll { removed.contains($0) }
        case .history: app.clearHistory(removed)
        case .collections: break
        }
    }
}
