import SwiftUI

// MARK: - Compare Picker View
/// Lets the user pick a Before photo and an After photo, then launches comparison.
struct ComparePickerView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.presentationMode) var presentationMode

    /// When opened from a room, this is pre-set.
    var preselectedRoomID: UUID? = nil
    var initialBeforePhoto: Photo? = nil
    var initialAfterPhoto: Photo? = nil

    @State private var selectedRoomID: UUID? = nil
    @State private var beforePhoto: Photo? = nil
    @State private var afterPhoto: Photo? = nil
    @State private var pickingSlot: CompareSlot? = nil
    @State private var showComparison = false

    enum CompareSlot { case before, after }

    private var allRoomPairs: [RoomProjectPair] { appViewModel.allRooms() }

    private var photosForRoom: [Photo] {
        guard let rid = selectedRoomID else { return [] }
        return appViewModel.photos.filter { $0.roomID == rid }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Room picker (only shown when not pre-selected)
                if preselectedRoomID == nil {
                    roomPickerSection
                }

                // Before / After slot cards
                HStack(spacing: 16) {
                    slotCard(slot: .before, photo: beforePhoto)
                    slotCard(slot: .after, photo: afterPhoto)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)

                if photosForRoom.isEmpty && selectedRoomID != nil {
                    Text("No photos in this room yet.")
                        .font(AppFonts.body())
                        .foregroundColor(AppColors.secondaryText)
                        .padding(.top, 20)
                }

                Spacer()

                // Compare button
                PrimaryButton(
                    title: "Compare",
                    action: { showComparison = true }
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .disabled(beforePhoto == nil || afterPhoto == nil)
                .opacity(beforePhoto != nil && afterPhoto != nil ? 1 : 0.4)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Compare Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(AppColors.primary)
                }
            }
            // Photo grid picker sheet
            .sheet(item: $pickingSlot) { slot in
                PhotoGridPickerSheet(
                    photos: photosForRoom,
                    onSelect: { photo in
                        if slot == .before { beforePhoto = photo }
                        else { afterPhoto = photo }
                        pickingSlot = nil
                    },
                    onDismiss: { pickingSlot = nil }
                )
                .environmentObject(appViewModel)
            }
            // Full-screen comparison
            .fullScreenCover(isPresented: $showComparison) {
                if let before = beforePhoto, let after = afterPhoto {
                    BeforeAfterComparisonView(
                        beforePhoto: before,
                        afterPhoto: after,
                        roomName: roomName(for: selectedRoomID)
                    )
                    .environmentObject(appViewModel)
                }
            }
        }
        .onAppear {
            selectedRoomID = preselectedRoomID
            if let b = initialBeforePhoto {
                beforePhoto = b
                // Auto-set room if not pre-selected
                if selectedRoomID == nil { selectedRoomID = b.roomID }
            }
            if let a = initialAfterPhoto {
                afterPhoto = a
                if selectedRoomID == nil { selectedRoomID = a.roomID }
            }
        }
    }

    // MARK: - Room picker
    private var roomPickerSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(allRoomPairs) { pair in
                    FilterChip(
                        title: pair.room.name,
                        isSelected: selectedRoomID == pair.room.id
                    ) {
                        selectedRoomID = pair.room.id
                        beforePhoto = nil
                        afterPhoto = nil
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Slot card
    private func slotCard(slot: CompareSlot, photo: Photo?) -> some View {
        Button(action: {
            guard selectedRoomID != nil else { return }
            pickingSlot = slot
        }) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.systemGray6))
                        .aspectRatio(0.85, contentMode: .fit)

                    if let p = photo, let img = UIImage(contentsOfFile: p.imagePath) {
                        Image(uiImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 32))
                                .foregroundColor(AppColors.secondaryText)
                            Text("Tap to pick")
                                .font(AppFonts.caption())
                                .foregroundColor(AppColors.secondaryText)
                        }
                    }
                }

                Text(slot == .before ? "BEFORE" : "AFTER")
                    .font(AppFonts.caption())
                    .fontWeight(.semibold)
                    .foregroundColor(slot == .before ? AppColors.accent : AppColors.progress)

                if let p = photo {
                    Text(p.takenAt.shortDate)
                        .font(AppFonts.caption2())
                        .foregroundColor(AppColors.secondaryText)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func roomName(for id: UUID?) -> String {
        guard let id = id else { return "" }
        return allRoomPairs.first { $0.id == id }?.room.name ?? ""
    }
}

// MARK: - CompareSlot Identifiable for sheet
extension ComparePickerView.CompareSlot: Identifiable {
    var id: Int { self == .before ? 0 : 1 }
}

// MARK: - Photo Grid Picker Sheet
struct PhotoGridPickerSheet: View {
    @EnvironmentObject var appViewModel: AppViewModel
    let photos: [Photo]
    let onSelect: (Photo) -> Void
    let onDismiss: () -> Void

    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationView {
            Group {
                if photos.isEmpty {
                    EmptyStateView(
                        icon: "photo.on.rectangle",
                        title: "No Photos",
                        subtitle: "Add photos to this room first."
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 3) {
                            ForEach(photos) { photo in
                                Button(action: { onSelect(photo) }) {
                                    ZStack(alignment: .bottomLeading) {
                                        if let img = UIImage(contentsOfFile: photo.imagePath) {
                                            Image(uiImage: img)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(minWidth: 0, maxWidth: .infinity)
                                                .aspectRatio(1, contentMode: .fit)
                                                .clipped()
                                        } else {
                                            Rectangle()
                                                .fill(Color(.systemGray5))
                                                .aspectRatio(1, contentMode: .fit)
                                                .overlay(Image(systemName: "photo").foregroundColor(AppColors.secondaryText))
                                        }
                                        Text(photo.takenAt.shortDate)
                                            .font(.system(size: 9))
                                            .foregroundColor(.white)
                                            .padding(4)
                                    }
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Select Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onDismiss)
                        .foregroundColor(AppColors.primary)
                }
            }
        }
    }
}
