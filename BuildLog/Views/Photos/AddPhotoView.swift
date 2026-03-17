import SwiftUI
import PhotosUI
import UIKit

struct AddPhotoView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Binding var isPresented: Bool

    var preselectedRoomID: UUID? = nil
    var preselectedProjectID: UUID? = nil

    @State private var selectedImage: UIImage? = nil
    @State private var photoDescription = ""
    @State private var selectedRoomID: UUID? = nil
    @State private var selectedProjectID: UUID? = nil
    @State private var photoDate = Date()
    @State private var showImageSourcePicker = false
    @State private var showCamera = false
    @State private var showGallery = false
    @State private var isSaving = false
    @State private var imageError: String? = nil

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Photo selector
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Photo", systemImage: "camera")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.secondaryText)

                        Button(action: { showImageSourcePicker = true }) {
                            ZStack {
                                if let image = selectedImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 220)
                                        .clipped()
                                        .cornerRadius(16)
                                } else {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.systemGray6))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 220)
                                        .overlay(
                                            VStack(spacing: 12) {
                                                Image(systemName: "camera.fill")
                                                    .font(.system(size: 36))
                                                    .foregroundColor(AppColors.secondaryText)
                                                Text("Tap to add photo")
                                                    .font(AppFonts.subheadline())
                                                    .foregroundColor(AppColors.secondaryText)
                                                HStack(spacing: 20) {
                                                    Label("Camera", systemImage: "camera")
                                                        .font(AppFonts.caption())
                                                        .foregroundColor(AppColors.primary)
                                                    Label("Gallery", systemImage: "photo")
                                                        .font(AppFonts.caption())
                                                        .foregroundColor(AppColors.primary)
                                                }
                                            }
                                        )
                                }
                            }
                        }

                        if let error = imageError {
                            Text(error)
                                .font(AppFonts.caption())
                                .foregroundColor(AppColors.warning)
                        }

                        if selectedImage != nil {
                            Button("Change Photo") {
                                showImageSourcePicker = true
                            }
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.primary)
                        }
                    }

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Description (Optional)", systemImage: "text.alignleft")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                        ZStack(alignment: .topLeading) {
                            if photoDescription.isEmpty {
                                Text("Describe what's in this photo...")
                                    .font(AppFonts.body())
                                    .foregroundColor(Color(.placeholderText))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                            }
                            TextEditor(text: $photoDescription)
                                .font(AppFonts.body())
                                .frame(minHeight: 80)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .opacity(photoDescription.isEmpty ? 0.25 : 1)
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .frame(minHeight: 80)
                    }

                    // Project Picker
                    if preselectedProjectID == nil {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Project (Optional)", systemImage: "folder")
                                .font(AppFonts.subheadline())
                                .foregroundColor(AppColors.secondaryText)
                            Menu {
                                Button("None") { selectedProjectID = nil; selectedRoomID = nil }
                                ForEach(appViewModel.projects) { project in
                                    Button(project.name) {
                                        selectedProjectID = project.id
                                        selectedRoomID = nil
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(selectedProjectID.flatMap { id in appViewModel.projects.first { $0.id == id }?.name } ?? "None")
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

                    // Room Picker
                    if preselectedRoomID == nil {
                        let rooms = (selectedProjectID.flatMap { pid in appViewModel.projects.first { $0.id == pid } }?.rooms ?? [])
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Room (Optional)", systemImage: "door.left.hand.open")
                                .font(AppFonts.subheadline())
                                .foregroundColor(AppColors.secondaryText)
                            Menu {
                                Button("None") { selectedRoomID = nil }
                                ForEach(rooms) { room in
                                    Button(room.name) { selectedRoomID = room.id }
                                }
                            } label: {
                                HStack {
                                    Text(selectedRoomID.flatMap { rid in rooms.first { $0.id == rid }?.name } ?? "None")
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
                        .disabled(rooms.isEmpty)
                        .opacity(rooms.isEmpty ? 0.5 : 1)
                    }

                    // Date
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Date Taken", systemImage: "calendar")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                        DatePicker("", selection: $photoDate, in: ...Date(), displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                            .accentColor(AppColors.primary)
                            .labelsHidden()
                            .padding(.horizontal, 14)
                            .frame(height: 50)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }

                    Spacer(minLength: 20)
                }
                .padding(20)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Add Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                        .foregroundColor(AppColors.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: savePhoto) {
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
            .confirmationDialog("Add Photo", isPresented: $showImageSourcePicker, titleVisibility: .visible) {
                Button("Take Photo") { showCamera = true }
                Button("Choose from Gallery") { showGallery = true }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showCamera) {
                ImagePickerView(image: $selectedImage, sourceType: .camera)
            }
            .sheet(isPresented: $showGallery) {
                ImagePickerView(image: $selectedImage, sourceType: .photoLibrary)
            }
        }
        .onAppear {
            selectedRoomID = preselectedRoomID
            selectedProjectID = preselectedProjectID
        }
    }

    private func savePhoto() {
        imageError = nil
        guard let image = selectedImage else {
            imageError = "Please select a photo"
            return
        }
        isSaving = true

        DispatchQueue.global(qos: .userInitiated).async {
            let savedPath = saveImageToDisk(image)
            DispatchQueue.main.async {
                let photo = Photo(
                    imagePath: savedPath ?? "",
                    description: photoDescription.trimmed,
                    roomID: preselectedRoomID ?? selectedRoomID,
                    projectID: preselectedProjectID ?? selectedProjectID,
                    takenAt: photoDate
                )
                appViewModel.addPhoto(photo)
                isSaving = false
                isPresented = false
            }
        }
    }

    private func saveImageToDisk(_ image: UIImage) -> String? {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filename = UUID().uuidString + ".jpg"
        let url = docs.appendingPathComponent(filename)
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        try? data.write(to: url)
        return url.path
    }
}

// MARK: - Image Picker
struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(sourceType) ? sourceType : .photoLibrary
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerView

        init(_ parent: ImagePickerView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
