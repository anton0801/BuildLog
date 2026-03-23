import SwiftUI
import PhotosUI

struct CreateTaskView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Binding var isPresented: Bool

    var preselectedRoomID: UUID? = nil
    var preselectedProjectID: UUID? = nil

    @State private var title = ""
    @State private var description = ""
    @State private var selectedProjectID: UUID? = nil
    @State private var selectedRoomID: UUID? = nil
    @State private var deadline = Date().addingTimeInterval(86400 * 7)
    @State private var hasDeadline = true
    @State private var priority: TaskPriority = .medium
    @State private var estimatedCost = ""
    @State private var titleError: String? = nil
    @State private var isSaving = false
    @State private var showImagePicker = false
    @State private var selectedImages: [UIImage] = []

    private var availableRooms: [RoomProjectPair] {
        if let pid = selectedProjectID {
            let project = appViewModel.projects.first { $0.id == pid }
            return project?.rooms.map { RoomProjectPair(room: $0, project: project!) } ?? []
        }
        return appViewModel.allRooms()
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Task Title", systemImage: "pencil")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                        CustomTextField(
                            placeholder: "e.g., Paint bedroom walls",
                            text: $title,
                            errorMessage: titleError
                        )
                    }

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Description (Optional)", systemImage: "text.alignleft")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                        ZStack(alignment: .topLeading) {
                            if description.isEmpty {
                                Text("Add task details...")
                                    .font(AppFonts.body())
                                    .foregroundColor(Color(.placeholderText))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                            }
                            TextEditor(text: $description)
                                .font(AppFonts.body())
                                .frame(minHeight: 80)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .opacity(description.isEmpty ? 0.25 : 1)
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .frame(minHeight: 80)
                    }

                    // Project Picker
                    if preselectedProjectID == nil {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Project", systemImage: "folder")
                                .font(AppFonts.subheadline())
                                .foregroundColor(AppColors.secondaryText)
                            if appViewModel.projects.isEmpty {
                                Text("No projects available")
                                    .font(AppFonts.body())
                                    .foregroundColor(AppColors.secondaryText)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                            } else {
                                Menu {
                                    Button("No Project") {
                                        selectedProjectID = nil
                                        selectedRoomID = nil
                                    }
                                    ForEach(appViewModel.projects) { project in
                                        Button(project.name) {
                                            selectedProjectID = project.id
                                            selectedRoomID = nil
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedProjectID != nil ?
                                             (appViewModel.projects.first { $0.id == selectedProjectID }?.name ?? "Select Project") :
                                             "No Project")
                                            .font(AppFonts.body())
                                            .foregroundColor(AppColors.labelColor)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 12))
                                            .foregroundColor(AppColors.secondaryText)
                                    }
                                    .padding(.horizontal, 14)
                                    .frame(height: 50)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }

                    // Room Picker
                    if preselectedRoomID == nil {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Room", systemImage: "door.left.hand.open")
                                .font(AppFonts.subheadline())
                                .foregroundColor(AppColors.secondaryText)
                            if availableRooms.isEmpty {
                                Text("No rooms available")
                                    .font(AppFonts.body())
                                    .foregroundColor(AppColors.secondaryText)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                            } else {
                                Menu {
                                    Button("No Room") {
                                        selectedRoomID = nil
                                    }
                                    ForEach(availableRooms) { pair in
                                        Button("\(pair.room.name) (\(pair.project.name))") {
                                            selectedRoomID = pair.room.id
                                            selectedProjectID = pair.project.id
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedRoomID != nil ?
                                             (appViewModel.roomName(for: selectedRoomID)) :
                                             "No Room")
                                            .font(AppFonts.body())
                                            .foregroundColor(AppColors.labelColor)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 12))
                                            .foregroundColor(AppColors.secondaryText)
                                    }
                                    .padding(.horizontal, 14)
                                    .frame(height: 50)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }

                    // Deadline
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Deadline", systemImage: "calendar")
                                .font(AppFonts.subheadline())
                                .foregroundColor(AppColors.secondaryText)
                            Spacer()
                            Toggle("", isOn: $hasDeadline)
                                .labelsHidden()
                                .toggleStyle(SwitchToggleStyle(tint: AppColors.primary))
                        }
                        if hasDeadline {
                            DatePicker("", selection: $deadline, in: Date()..., displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                                .accentColor(AppColors.primary)
                                .padding(.horizontal, 14)
                                .frame(height: 50)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .labelsHidden()
                        }
                    }

                    // Priority
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Priority", systemImage: "flag")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                        HStack(spacing: 10) {
                            ForEach(TaskPriority.allCases, id: \.self) { p in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        priority = p
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: p.icon)
                                            .font(.system(size: 12))
                                        Text(p.rawValue)
                                            .font(AppFonts.caption())
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(priority == p ? .white : p.color)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(priority == p ? p.color : p.color.opacity(0.1))
                                    .cornerRadius(20)
                                }
                            }
                        }
                    }

                    // Estimated Cost
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Estimated Cost", systemImage: "dollarsign.circle")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                        CustomTextField(
                            placeholder: "0.00",
                            text: $estimatedCost,
                            keyboardType: .decimalPad,
                            systemImage: "dollarsign"
                        )
                    }

                    Spacer(minLength: 20)
                }
                .padding(20)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(AppColors.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: saveTask) {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.primary)
                        }
                    }
                    .disabled(isSaving)
                }
            }
        }
        .onAppear {
            selectedRoomID = preselectedRoomID
            selectedProjectID = preselectedProjectID
        }
    }

    private func saveTask() {
        titleError = nil
        guard !title.trimmed.isEmpty else {
            titleError = "Task title is required"
            return
        }
        isSaving = true

        let cost = Double(estimatedCost.replacingOccurrences(of: ",", with: ".")) ?? 0

        let task = TaskItem(
            title: title.trimmed,
            description: description.trimmed,
            roomID: preselectedRoomID ?? selectedRoomID,
            projectID: preselectedProjectID ?? selectedProjectID,
            deadline: hasDeadline ? deadline : nil,
            priority: priority,
            status: .todo,
            estimatedCost: cost
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let roomID = task.roomID
            let projID = task.projectID

            if let rid = roomID, let pid = projID {
                appViewModel.addTask(task, toRoom: rid, inProject: pid)
            } else {
                // Add as standalone task - add to first available room if no room specified
                if let pid = projID,
                   let project = appViewModel.projects.first(where: { $0.id == pid }),
                   let firstRoom = project.rooms.first {
                    var newTask = task
                    newTask.roomID = firstRoom.id
                    appViewModel.addTask(newTask, toRoom: firstRoom.id, inProject: pid)
                } else if let firstProject = appViewModel.projects.first,
                          let firstRoom = firstProject.rooms.first {
                    var newTask = task
                    newTask.roomID = firstRoom.id
                    newTask.projectID = firstProject.id
                    appViewModel.addTask(newTask, toRoom: firstRoom.id, inProject: firstProject.id)
                }
            }
            isSaving = false
            isPresented = false
        }
    }
}
