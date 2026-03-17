import SwiftUI

struct ProjectDetailView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    let project: Project

    @State private var showAddRoom = false
    @State private var roomName = ""
    @State private var selectedRoomIcon = "square"
    @State private var roomNameError: String? = nil

    // Get live project from viewModel
    private var liveProject: Project {
        appViewModel.projects.first { $0.id == project.id } ?? project
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Project Stats
                ProjectStatsHeader(project: liveProject, currency: settingsViewModel.currency)
                    .padding(.horizontal, 20)

                // Rooms Grid
                VStack(spacing: 12) {
                    SectionHeader(
                        title: "Rooms (\(liveProject.rooms.count))",
                        action: { showAddRoom = true },
                        actionTitle: "Add Room"
                    )
                    .padding(.horizontal, 20)

                    if liveProject.rooms.isEmpty {
                        EmptyStateView(
                            icon: "door.left.hand.open",
                            title: "No Rooms Yet",
                            subtitle: "Add rooms to organize your renovation tasks.",
                            buttonTitle: "Add Room",
                            buttonAction: { showAddRoom = true }
                        )
                    } else {
                        LazyVGrid(
                            columns: [GridItem(.flexible()), GridItem(.flexible())],
                            spacing: 12
                        ) {
                            ForEach(liveProject.rooms) { room in
                                NavigationLink(destination:
                                    RoomDetailView(room: room, project: liveProject)
                                        .environmentObject(appViewModel)
                                        .environmentObject(settingsViewModel)
                                ) {
                                    RoomCard(room: room, currency: settingsViewModel.currency)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }

                            // Add Room button card
                            Button(action: { showAddRoom = true }) {
                                VStack(spacing: 10) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(AppColors.primary.opacity(0.6))
                                    Text("Add Room")
                                        .font(AppFonts.subheadline())
                                        .foregroundColor(AppColors.primary.opacity(0.7))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 120)
                                .background(AppColors.primary.opacity(0.06))
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(AppColors.primary.opacity(0.2), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }

                Spacer(minLength: 100)
            }
            .padding(.top, 16)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle(liveProject.name)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showAddRoom) {
            addRoomSheet
        }
    }

    // MARK: - Add Room Sheet
    private var addRoomSheet: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Room Name", systemImage: "door.left.hand.open")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                        CustomTextField(
                            placeholder: "e.g., Living Room",
                            text: $roomName,
                            errorMessage: roomNameError
                        )
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Label("Room Icon", systemImage: "square.grid.3x3")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.secondaryText)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                            ForEach(RoomIcons.all, id: \.name) { iconData in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedRoomIcon = iconData.icon
                                    }
                                }) {
                                    VStack(spacing: 6) {
                                        Image(systemName: iconData.icon)
                                            .font(.system(size: 22))
                                            .foregroundColor(selectedRoomIcon == iconData.icon ? .white : AppColors.primary)
                                            .frame(width: 48, height: 48)
                                            .background(selectedRoomIcon == iconData.icon ? AppColors.primary : AppColors.primary.opacity(0.1))
                                            .clipShape(Circle())
                                        Text(iconData.name)
                                            .font(AppFonts.caption2())
                                            .foregroundColor(AppColors.secondaryText)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Add Room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showAddRoom = false
                        roomName = ""
                        roomNameError = nil
                    }
                    .foregroundColor(AppColors.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addRoom()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.primary)
                }
            }
        }
    }

    private func addRoom() {
        roomNameError = nil
        guard !roomName.trimmed.isEmpty else {
            roomNameError = "Room name is required"
            return
        }
        let room = Room(name: roomName.trimmed, icon: selectedRoomIcon, projectID: liveProject.id)
        appViewModel.addRoom(room, toProject: liveProject.id)
        roomName = ""
        selectedRoomIcon = "square"
        showAddRoom = false
    }
}

// MARK: - Project Stats Header
struct ProjectStatsHeader: View {
    let project: Project
    let currency: String

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Overall Progress")
                        .font(AppFonts.subheadline())
                        .foregroundColor(AppColors.secondaryText)
                    Text(project.progress.percentString())
                        .font(AppFonts.title())
                        .foregroundColor(AppColors.labelColor)
                }
                Spacer()
                ProgressRing(progress: project.progress, lineWidth: 8, size: 70)
            }

            HStack(spacing: 0) {
                StatCell(title: "Rooms", value: "\(project.rooms.count)", icon: "square.split.2x2")
                Divider().frame(height: 40)
                StatCell(title: "Tasks", value: "\(project.totalTaskCount)", icon: "checkmark.circle")
                Divider().frame(height: 40)
                StatCell(title: "Budget", value: project.budget.currencyString(currency: currency), icon: "banknote")
            }

            // Status and dates
            HStack {
                BadgeView(text: project.status.rawValue, color: Color(hex: project.status.color))
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.secondaryText)
                    Text("Started \(project.startDate.shortDate)")
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.secondaryText)
                }
            }
        }
        .cardStyle()
    }
}

struct StatCell: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(AppColors.primary)
            Text(value)
                .font(AppFonts.headline())
                .foregroundColor(AppColors.labelColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(title)
                .font(AppFonts.caption())
                .foregroundColor(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Room Card
struct RoomCard: View {
    let room: Room
    let currency: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(AppColors.primary.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: room.icon)
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.primary)
                }
                Spacer()
                ProgressRing(
                    progress: room.progress,
                    lineWidth: 4,
                    size: 32,
                    showLabel: false
                )
            }

            Text(room.name)
                .font(AppFonts.headline())
                .foregroundColor(AppColors.labelColor)
                .lineLimit(2)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(room.tasks.count) tasks")
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.secondaryText)
                Text("\(Int(room.progress * 100))% done")
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.progress)
            }

            // Mini progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray5))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(AppColors.progress)
                        .frame(width: geo.size.width * CGFloat(room.progress), height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(14)
        .background(AppColors.cardBackground)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        .frame(minHeight: 140)
    }
}
