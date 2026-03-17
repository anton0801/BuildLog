import SwiftUI

struct TimelineView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var selectedType: TimelineEventType? = nil
    @State private var searchText = ""

    var filteredEvents: [TimelineEvent] {
        var events = appViewModel.timelineEvents
        if let type = selectedType {
            events = events.filter { $0.type == type }
        }
        if !searchText.isEmpty {
            events = events.filter {
                $0.title.lowercased().contains(searchText.lowercased()) ||
                $0.description.lowercased().contains(searchText.lowercased())
            }
        }
        return events.sorted { $0.date > $1.date }
    }

    var groupedEvents: [(key: String, events: [TimelineEvent])] {
        let grouped = Dictionary(grouping: filteredEvents) { event -> String in
            if Calendar.current.isDateInToday(event.date) {
                return "Today"
            } else if Calendar.current.isDateInYesterday(event.date) {
                return "Yesterday"
            } else {
                return event.date.formatted("MMMM d, yyyy")
            }
        }
        return grouped
            .map { (key: $0.key, events: $0.value.sorted { $0.date > $1.date }) }
            .sorted { lhs, rhs in
                let lhsDate = lhs.events.first?.date ?? Date.distantPast
                let rhsDate = rhs.events.first?.date ?? Date.distantPast
                return lhsDate > rhsDate
            }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    FilterChip(title: "All", isSelected: selectedType == nil) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedType = nil
                        }
                    }
                    ForEach(TimelineEventType.allCases, id: \.self) { type in
                        FilterChip(title: type.rawValue, isSelected: selectedType == type) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedType = selectedType == type ? nil : type
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .background(Color(.systemBackground))

            if filteredEvents.isEmpty {
                Spacer()
                EmptyStateView(
                    icon: "clock",
                    title: "No Timeline Events",
                    subtitle: "Your activity will appear here as you add projects, tasks, and expenses."
                )
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(groupedEvents, id: \.key) { group in
                            VStack(alignment: .leading, spacing: 0) {
                                // Date Header
                                Text(group.key)
                                    .font(AppFonts.headline())
                                    .foregroundColor(AppColors.secondaryText)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)

                                // Events for this day
                                ForEach(Array(group.events.enumerated()), id: \.element.id) { index, event in
                                    TimelineEventRow(
                                        event: event,
                                        isLast: index == group.events.count - 1
                                    )
                                }
                            }
                        }
                        Spacer(minLength: 100)
                    }
                    .padding(.top, 8)
                }
                .background(AppColors.background)
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("Timeline")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search events")
    }
}

// MARK: - Timeline Event Row
struct TimelineEventRow: View {
    let event: TimelineEvent
    let isLast: Bool

    @State private var appeared = false

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Timeline Line and Dot
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(event.type.color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: event.type.icon)
                        .font(.system(size: 14))
                        .foregroundColor(event.type.color)
                }

                if !isLast {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 56)
            .padding(.leading, 20)

            // Event Content
            VStack(alignment: .leading, spacing: 6) {
                Text(event.title)
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.labelColor)
                    .lineLimit(2)

                if !event.description.isEmpty {
                    Text(event.description)
                        .font(AppFonts.subheadline())
                        .foregroundColor(AppColors.secondaryText)
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    BadgeView(text: event.type.rawValue, color: event.type.color)
                    Text(event.date.shortTime)
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.tertiaryText)
                }
            }
            .padding(.leading, 12)
            .padding(.trailing, 20)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : 20)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: appeared)
        .onAppear {
            withAnimation {
                appeared = true
            }
        }
    }
}
