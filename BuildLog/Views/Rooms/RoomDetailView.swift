import SwiftUI

struct RoomDetailView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel

    let room: Room
    let project: Project

    @State private var selectedTab = 0
    @State private var showAddTask = false
    @State private var showAddMaterial = false
    @State private var showAddPhoto = false
    @State private var showCompare = false
    @State private var showCalculator = false

    private var liveRoom: Room {
        appViewModel.projects
            .first { $0.id == project.id }?
            .rooms.first { $0.id == room.id } ?? room
    }

    private var roomMaterials: [Material] {
        appViewModel.materials.filter { $0.roomID == room.id }
    }

    private var roomPhotos: [Photo] {
        appViewModel.photos.filter { $0.roomID == room.id }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress Ring Header
            VStack(spacing: 12) {
                ProgressRing(progress: liveRoom.progress, lineWidth: 10, size: 90)
                    .padding(.top, 16)

                Text("\(liveRoom.tasks.filter { $0.status == .done }.count) of \(liveRoom.tasks.count) tasks completed")
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .background(AppColors.cardBackground)
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)

            // Segmented Picker
            Picker("", selection: $selectedTab) {
                Text("Tasks (\(liveRoom.tasks.count))").tag(0)
                Text("Materials (\(roomMaterials.count))").tag(1)
                Text("Photos (\(roomPhotos.count))").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(AppColors.background)

            // Tab Content
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(spacing: 12) {
                        Group {
                            if selectedTab == 0 {
                                tasksContent
                            } else if selectedTab == 1 {
                                materialsContent
                            } else {
                                photosContent
                            }
                        }
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
                .background(AppColors.background)

                // FAB
                Button(action: {
                    if selectedTab == 0 { showAddTask = true }
                    else if selectedTab == 1 { showAddMaterial = true }
                    else { showAddPhoto = true }
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(AppColors.primary)
                        .clipShape(Circle())
                        .shadow(color: AppColors.primary.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle(liveRoom.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Group {
                    if selectedTab == 2 {
                        Button(action: { showCompare = true }) {
                            Image(systemName: "square.split.2x1")
                                .foregroundColor(AppColors.primary)
                        }
                    } else if selectedTab == 1 {
                        Button(action: { showCalculator = true }) {
                            Image(systemName: "function")
                                .foregroundColor(AppColors.primary)
                        }
                    } else {
                        EmptyView()
                    }
                }
            }
        }
        .sheet(isPresented: $showCompare) {
            ComparePickerView(preselectedRoomID: room.id)
                .environmentObject(appViewModel)
        }
        .sheet(isPresented: $showCalculator) {
            MaterialCalculatorView(preselectedRoom: liveRoom, project: project)
                .environmentObject(appViewModel)
                .environmentObject(settingsViewModel)
        }
        .sheet(isPresented: $showAddTask) {
            CreateTaskView(isPresented: $showAddTask, preselectedRoomID: room.id, preselectedProjectID: project.id)
                .environmentObject(appViewModel)
        }
        .sheet(isPresented: $showAddMaterial) {
            AddMaterialView(isPresented: $showAddMaterial, preselectedRoomID: room.id, preselectedProjectID: project.id)
                .environmentObject(appViewModel)
                .environmentObject(settingsViewModel)
        }
        .sheet(isPresented: $showAddPhoto) {
            AddPhotoView(isPresented: $showAddPhoto, preselectedRoomID: room.id, preselectedProjectID: project.id)
                .environmentObject(appViewModel)
        }
    }

    // MARK: - Tasks Content
    @ViewBuilder
    private var tasksContent: some View {
        if liveRoom.tasks.isEmpty {
            EmptyStateView(
                icon: "checkmark.circle",
                title: "No Tasks",
                subtitle: "Add tasks to track your renovation work.",
                buttonTitle: "Add Task",
                buttonAction: { showAddTask = true }
            )
        } else {
            ForEach(liveRoom.tasks) { task in
                RoomTaskRow(task: task, onStatusChange: {
                    appViewModel.advanceTaskStatus(task)
                }, onDelete: {
                    appViewModel.deleteTask(task)
                })
            }
        }
    }

    // MARK: - Materials Content
    @ViewBuilder
    private var materialsContent: some View {
        // Calculate quantity link
        Button(action: { showCalculator = true }) {
            HStack(spacing: 8) {
                Image(systemName: "function")
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.primary)
                Text("Calculate needed quantity")
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.secondaryText)
            }
            .padding()
            .background(AppColors.primary.opacity(0.06))
            .cornerRadius(12)
        }

        if roomMaterials.isEmpty {
            EmptyStateView(
                icon: "shippingbox",
                title: "No Materials",
                subtitle: "Track materials needed for this room.",
                buttonTitle: "Add Material",
                buttonAction: { showAddMaterial = true }
            )
        } else {
            ForEach(roomMaterials) { material in
                MaterialRow(material: material, currency: settingsViewModel.currency)
            }
        }
    }

    // MARK: - Photos Content
    @ViewBuilder
    private var photosContent: some View {
        if roomPhotos.isEmpty {
            EmptyStateView(
                icon: "camera",
                title: "No Photos",
                subtitle: "Document your renovation progress with photos.",
                buttonTitle: "Add Photo",
                buttonAction: { showAddPhoto = true }
            )
        } else {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                ForEach(roomPhotos) { photo in
                    PhotoGridCell(photo: photo)
                }
            }
        }
    }
}

// MARK: - Room Task Row
struct RoomTaskRow: View {
    let task: TaskItem
    let onStatusChange: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onStatusChange) {
                Image(systemName: task.status.icon)
                    .font(.system(size: 22))
                    .foregroundColor(task.status.color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(AppFonts.subheadline())
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.labelColor)
                    .strikethrough(task.status == .done)
                HStack(spacing: 8) {
                    BadgeView(text: task.priority.rawValue, color: task.priority.color)
                    if let deadline = task.deadline {
                        Text(deadline.shortDate)
                            .font(AppFonts.caption())
                            .foregroundColor(task.isOverdue ? AppColors.warning : AppColors.secondaryText)
                    }
                }
            }
            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.warning)
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 1)
    }
}

// MARK: - Material Row
struct MaterialRow: View {
    let material: Material
    let currency: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: material.category.icon)
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.primary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(material.name)
                    .font(AppFonts.subheadline())
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.labelColor)
                Text("\(String(format: "%.1f", material.quantity)) \(material.unit)")
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.secondaryText)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(material.totalCost.currencyString(currency: currency))
                    .font(AppFonts.subheadline())
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.labelColor)
                Text("\(material.price.currencyString(currency: currency))/\(material.unit)")
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.secondaryText)
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 1)
    }
}

// MARK: - Photo Grid Cell
struct PhotoGridCell: View {
    let photo: Photo
    @State private var showDetail = false

    var body: some View {
        Button(action: { showDetail = true }) {
            ZStack(alignment: .bottomLeading) {
                if let image = UIImage(contentsOfFile: photo.imagePath) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(AppColors.secondaryText)
                        )
                }
            }
            .cornerRadius(8)
        }
        .sheet(isPresented: $showDetail) {
            PhotoDetailView(photo: photo)
        }
    }
}
