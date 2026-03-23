import SwiftUI

// MARK: - Before / After Comparison View
struct BeforeAfterComparisonView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.presentationMode) var presentationMode

    let beforePhoto: Photo
    let afterPhoto: Photo
    let roomName: String

    @State private var dividerPosition: CGFloat = 0.5  // 0...1
    @State private var dragOffset: CGFloat = 0
    @State private var showShareSheet = false
    @State private var shareImage: UIImage? = nil

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                // MARK: After image (full width, bottom layer)
                afterImageView
                    .frame(width: geo.size.width, height: geo.size.height)

                // MARK: Before image clipped to left side
                beforeImageView
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .mask(
                        HStack(spacing: 0) {
                            Rectangle()
                                .frame(width: geo.size.width * clampedPosition)
                            Spacer(minLength: 0)
                        }
                    )

                // MARK: Divider line
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
                    .offset(x: geo.size.width * clampedPosition - geo.size.width / 2)
                    .shadow(color: Color.black.opacity(0.5), radius: 4)

                // MARK: Handle
                Circle()
                    .fill(Color.white)
                    .frame(width: 44, height: 44)
                    .overlay(
                        HStack(spacing: 2) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 11, weight: .semibold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(.black)
                    )
                    .shadow(color: Color.black.opacity(0.35), radius: 6, x: 0, y: 2)
                    .offset(x: geo.size.width * clampedPosition - geo.size.width / 2)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newPos = (geo.size.width * clampedPosition + value.translation.width) / geo.size.width
                                dividerPosition = min(max(newPos, 0.02), 0.98)
                            }
                    )

                // MARK: Labels
                VStack {
                    HStack {
                        labelPill("Before", color: AppColors.accent)
                        Spacer()
                        labelPill("After", color: AppColors.progress)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, geo.safeAreaInsets.top + 56)

                    Spacer()

                    // Bottom info
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            if !roomName.isEmpty {
                                Text(roomName)
                                    .font(AppFonts.headline())
                                    .foregroundColor(.white)
                            }
                            Text("\(beforePhoto.takenAt.shortDate)  →  \(afterPhoto.takenAt.shortDate)")
                                .font(AppFonts.caption())
                                .foregroundColor(.white.opacity(0.75))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.black.opacity(0.7), .clear],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                }
                .ignoresSafeArea(edges: .bottom)

                // MARK: Toolbar
                VStack {
                    HStack {
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        Spacer()
                        Button(action: { renderAndShare(size: geo.size) }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, geo.safeAreaInsets.top + 8)
                    Spacer()
                }
                .ignoresSafeArea()
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let newPos = dividerPosition + value.translation.width / geo.size.width
                        dividerPosition = min(max(newPos, 0.02), 0.98)
                    },
                including: .all
            )
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showShareSheet) {
            if let img = shareImage {
                ActivityShareSheet(items: [img])
            }
        }
    }

    private var clampedPosition: CGFloat {
        min(max(dividerPosition, 0.02), 0.98)
    }

    private var beforeImageView: some View {
        Group {
            if let img = UIImage(contentsOfFile: beforePhoto.imagePath) {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle().fill(Color(.systemGray4))
            }
        }
    }

    private var afterImageView: some View {
        Group {
            if let img = UIImage(contentsOfFile: afterPhoto.imagePath) {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle().fill(Color(.systemGray5))
            }
        }
    }

    private func labelPill(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.black.opacity(0.55))
            .cornerRadius(20)
    }

    // MARK: - Render & Share
    private func renderAndShare(size: CGSize) {
        let beforeImg = UIImage(contentsOfFile: beforePhoto.imagePath) ?? UIImage()
        let afterImg  = UIImage(contentsOfFile: afterPhoto.imagePath)  ?? UIImage()

        let renderer = UIGraphicsImageRenderer(size: size)
        let result = renderer.image { _ in
            // Draw after image (full)
            afterImg.draw(in: CGRect(origin: .zero, size: size))
            // Draw before image clipped to left portion
            let clipRect = CGRect(x: 0, y: 0,
                                  width: size.width * clampedPosition,
                                  height: size.height)
            UIRectClip(clipRect)
            beforeImg.draw(in: CGRect(origin: .zero, size: size))
        }

        shareImage = result
        showShareSheet = true
    }
}

