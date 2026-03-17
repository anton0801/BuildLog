import SwiftUI

struct PhotosView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var showAddPhoto = false
    @State private var selectedPhoto: Photo? = nil
    @State private var searchText = ""

    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var filteredPhotos: [Photo] {
        if searchText.isEmpty {
            return appViewModel.photos
        }
        return appViewModel.photos.filter { photo in
            photo.description.lowercased().contains(searchText.lowercased()) ||
            appViewModel.roomName(for: photo.roomID).lowercased().contains(searchText.lowercased())
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if appViewModel.photos.isEmpty {
                    EmptyStateView(
                        icon: "camera",
                        title: "No Photos Yet",
                        subtitle: "Document your renovation progress by adding photos.",
                        buttonTitle: "Add Photo",
                        buttonAction: { showAddPhoto = true }
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            if filteredPhotos.isEmpty {
                                VStack(spacing: 16) {
                                    Spacer(minLength: 60)
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 40))
                                        .foregroundColor(AppColors.secondaryText)
                                    Text("No photos found")
                                        .font(AppFonts.headline())
                                        .foregroundColor(AppColors.secondaryText)
                                    Spacer()
                                }
                            } else {
                                LazyVGrid(columns: columns, spacing: 3) {
                                    ForEach(filteredPhotos) { photo in
                                        PhotoCell(photo: photo)
                                            .onTapGesture {
                                                selectedPhoto = photo
                                            }
                                    }
                                }
                            }
                            Spacer(minLength: 100)
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .background(AppColors.background.ignoresSafeArea())

            FABButton(action: { showAddPhoto = true })
                .padding(.trailing, 24)
                .padding(.bottom, 100)
        }
        .navigationTitle("Photos")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search photos")
        .sheet(isPresented: $showAddPhoto) {
            AddPhotoView(isPresented: $showAddPhoto)
                .environmentObject(appViewModel)
        }
        .sheet(item: $selectedPhoto) { photo in
            PhotoDetailView(photo: photo)
                .environmentObject(appViewModel)
        }
    }
}

// MARK: - Photo Cell
struct PhotoCell: View {
    let photo: Photo
    @State private var isPressed = false

    var body: some View {
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

            // Bottom overlay
            LinearGradient(
                gradient: Gradient(colors: [.clear, Color.black.opacity(0.5)]),
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 2) {
                if !photo.description.isEmpty {
                    Text(photo.description)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                Text(photo.takenAt.shortDate)
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 6)
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Photo Detail View
struct PhotoDetailView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    let photo: Photo
    @Environment(\.presentationMode) var presentationMode
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Image
                    if let image = UIImage(contentsOfFile: photo.imagePath) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(scale)
                            .offset(offset)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        scale = max(1.0, value)
                                    }
                                    .onEnded { _ in
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            if scale < 1.0 { scale = 1.0 }
                                        }
                                    }
                            )
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        if scale > 1.0 {
                                            offset = value.translation
                                        }
                                    }
                                    .onEnded { _ in
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            if scale <= 1.0 { offset = .zero }
                                        }
                                    }
                            )
                    } else {
                        VStack {
                            Image(systemName: "photo.slash")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.5))
                            Text("Image not available")
                                .font(AppFonts.body())
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                    // Info bar
                    VStack(alignment: .leading, spacing: 8) {
                        if !photo.description.isEmpty {
                            Text(photo.description)
                                .font(AppFonts.body())
                                .foregroundColor(.white)
                        }
                        HStack {
                            Label(photo.takenAt.mediumDate, systemImage: "calendar")
                                .font(AppFonts.caption())
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            if let roomID = photo.roomID {
                                Label(appViewModel.roomName(for: roomID), systemImage: "door.left.hand.open")
                                    .font(AppFonts.caption())
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.6))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button(action: { showDeleteAlert = true }) {
                        Image(systemName: "trash")
                            .foregroundColor(AppColors.warning)
                    }
                }
            }
            .alert(isPresented: $showDeleteAlert) {
                Alert(
                    title: Text("Delete Photo"),
                    message: Text("This photo will be permanently deleted."),
                    primaryButton: .destructive(Text("Delete")) {
                        appViewModel.deletePhoto(photo)
                        presentationMode.wrappedValue.dismiss()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}
