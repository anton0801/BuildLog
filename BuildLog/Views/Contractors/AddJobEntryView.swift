import SwiftUI

// MARK: - Add / Edit Job Entry View
struct AddJobEntryView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @Binding var isPresented: Bool

    let contractorID: UUID
    var existingEntry: JobEntry? = nil

    // Fields
    @State private var date = Date()
    @State private var selectedRoomID: UUID? = nil
    @State private var tasksDone = ""
    @State private var hoursWorked = ""
    @State private var amountPaid = ""
    @State private var notes = ""
    @State private var photoImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var showSourcePicker = false
    @State private var isSaving = false
    @State private var tasksError: String? = nil
    @State private var amountError: String? = nil

    private var isEditing: Bool { existingEntry != nil }

    private var allRooms: [RoomProjectPair] {
        appViewModel.allRooms()
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {

                    // Date
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Date", systemImage: "calendar")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                        DatePicker("", selection: $date, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 14)
                            .frame(height: 50)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }

                    // Room picker
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Room (Optional)", systemImage: "door.left.hand.open")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                        Menu {
                            Button("None") { selectedRoomID = nil }
                            ForEach(allRooms) { pair in
                                Button("\(pair.room.name) — \(pair.project.name)") {
                                    selectedRoomID = pair.room.id
                                }
                            }
                        } label: {
                            HStack {
                                Text(roomLabel)
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

                    // Tasks done
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Tasks Done", systemImage: "checkmark.circle")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                        ZStack(alignment: .topLeading) {
                            if tasksDone.isEmpty {
                                Text("Describe the work completed...")
                                    .font(AppFonts.body())
                                    .foregroundColor(Color(.placeholderText))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                            }
                            TextEditor(text: $tasksDone)
                                .font(AppFonts.body())
                                .frame(minHeight: 90)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .opacity(tasksDone.isEmpty ? 0.25 : 1)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(tasksError != nil ? AppColors.warning : Color.clear, lineWidth: 1)
                                )
                        )
                        .frame(minHeight: 90)
                        if let err = tasksError {
                            Text(err).font(AppFonts.caption()).foregroundColor(AppColors.warning)
                        }
                    }

                    // Hours worked + Amount
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Hours", systemImage: "clock")
                                .font(AppFonts.subheadline())
                                .foregroundColor(AppColors.secondaryText)
                            CustomTextField(
                                placeholder: "Optional",
                                text: $hoursWorked,
                                keyboardType: .decimalPad
                            )
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Amount (\(settingsViewModel.currencySymbol))", systemImage: "banknote")
                                .font(AppFonts.subheadline())
                                .foregroundColor(AppColors.secondaryText)
                            CustomTextField(
                                placeholder: "0.00",
                                text: $amountPaid,
                                keyboardType: .decimalPad,
                                errorMessage: amountError
                            )
                        }
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Notes (Optional)", systemImage: "note.text")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                        ZStack(alignment: .topLeading) {
                            if notes.isEmpty {
                                Text("Additional notes...")
                                    .font(AppFonts.body())
                                    .foregroundColor(Color(.placeholderText))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                            }
                            TextEditor(text: $notes)
                                .font(AppFonts.body())
                                .frame(minHeight: 70)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .opacity(notes.isEmpty ? 0.25 : 1)
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .frame(minHeight: 70)
                    }

                    // Photo
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Photo (Optional)", systemImage: "camera")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                        Button(action: { showSourcePicker = true }) {
                            ZStack {
                                if let img = photoImage {
                                    Image(uiImage: img)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 140)
                                        .clipped()
                                        .cornerRadius(12)
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                        .frame(height: 140)
                                        .overlay(
                                            VStack(spacing: 8) {
                                                Image(systemName: "camera.badge.plus")
                                                    .font(.system(size: 28))
                                                    .foregroundColor(AppColors.secondaryText)
                                                Text("Add receipt or work photo")
                                                    .font(AppFonts.caption())
                                                    .foregroundColor(AppColors.secondaryText)
                                            }
                                        )
                                }
                            }
                        }
                        if photoImage != nil {
                            Button(action: { photoImage = nil }) {
                                Text("Remove Photo")
                                    .font(AppFonts.caption())
                                    .foregroundColor(AppColors.warning)
                            }
                        }
                    }

                    Spacer(minLength: 20)
                }
                .padding(20)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle(isEditing ? "Edit Entry" : "Add Job Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                        .foregroundColor(AppColors.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: save) {
                        if isSaving {
                            ProgressView().scaleEffect(0.8)
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
        .confirmationDialog("Add Photo", isPresented: $showSourcePicker) {
            Button("Camera") {
                imagePickerSource = .camera
                showImagePicker = true
            }
            Button("Photo Library") {
                imagePickerSource = .photoLibrary
                showImagePicker = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(image: $photoImage, sourceType: imagePickerSource)
        }
        .onAppear { populateIfEditing() }
    }

    // MARK: - Helpers
    private var roomLabel: String {
        guard let rid = selectedRoomID else { return "None" }
        return allRooms.first { $0.id == rid }.map { "\($0.room.name) — \($0.project.name)" } ?? "None"
    }

    private func populateIfEditing() {
        guard let entry = existingEntry else { return }
        date = entry.date
        selectedRoomID = entry.roomID
        tasksDone = entry.tasksDone
        hoursWorked = entry.hoursWorked.map { String($0) } ?? ""
        amountPaid = entry.amountPaid > 0 ? String(entry.amountPaid) : ""
        notes = entry.notes
        if let path = entry.photoPath {
            photoImage = UIImage(contentsOfFile: path)
        }
    }

    private func save() {
        tasksError = nil
        amountError = nil

        guard !tasksDone.trimmed.isEmpty else {
            tasksError = "Please describe the tasks done"
            return
        }

        let amount = Double(amountPaid.replacingOccurrences(of: ",", with: ".")) ?? 0
        let hours = Double(hoursWorked.replacingOccurrences(of: ",", with: "."))

        isSaving = true

        // Save photo to documents if needed
        var photoPath: String? = existingEntry?.photoPath
        if let img = photoImage, existingEntry?.photoPath == nil {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = "job_\(UUID().uuidString).jpg"
            let url = docs.appendingPathComponent(fileName)
            if let data = img.jpegData(compressionQuality: 0.8) {
                try? data.write(to: url, options: .atomicWrite)
                photoPath = url.path
            }
        } else if photoImage == nil {
            // Removed photo
            if let path = existingEntry?.photoPath {
                try? FileManager.default.removeItem(at: URL(fileURLWithPath: path))
            }
            photoPath = nil
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if let existing = self.existingEntry {
                let updated = JobEntry(
                    id: existing.id,
                    date: self.date,
                    roomID: self.selectedRoomID,
                    tasksDone: self.tasksDone.trimmed,
                    hoursWorked: hours,
                    amountPaid: amount,
                    notes: self.notes.trimmed,
                    photoPath: photoPath,
                    createdAt: existing.createdAt
                )
                self.appViewModel.updateJobEntry(updated, inContractor: self.contractorID)
            } else {
                let entry = JobEntry(
                    date: self.date,
                    roomID: self.selectedRoomID,
                    tasksDone: self.tasksDone.trimmed,
                    hoursWorked: hours,
                    amountPaid: amount,
                    notes: self.notes.trimmed,
                    photoPath: photoPath
                )
                self.appViewModel.addJobEntry(entry, toContractor: self.contractorID)
            }
            self.isSaving = false
            self.isPresented = false
        }
    }
}

