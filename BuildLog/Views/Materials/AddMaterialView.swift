import SwiftUI

struct AddMaterialView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @Binding var isPresented: Bool

    var preselectedRoomID: UUID? = nil
    var preselectedProjectID: UUID? = nil
    var prefillName: String? = nil
    var prefillQuantity: Double? = nil
    var prefillUnit: String? = nil

    @State private var name = ""
    @State private var category: MaterialCategory = .other
    @State private var selectedRoomID: UUID? = nil
    @State private var selectedProjectID: UUID? = nil
    @State private var quantity = "1"
    @State private var unit = "pcs"
    @State private var price = ""
    @State private var notes = ""
    @State private var nameError: String? = nil
    @State private var priceError: String? = nil
    @State private var isSaving = false

    let unitOptions = ["pcs", "m", "m²", "m³", "L", "kg", "box", "pack", "roll", "sheet"]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Name
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Material Name", systemImage: "shippingbox")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                        CustomTextField(
                            placeholder: "e.g., Interior Paint White",
                            text: $name,
                            errorMessage: nameError
                        )
                    }

                    // Category
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Category", systemImage: "tag")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                            ForEach(MaterialCategory.allCases, id: \.self) { cat in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        category = cat
                                    }
                                }) {
                                    VStack(spacing: 6) {
                                        Image(systemName: cat.icon)
                                            .font(.system(size: 18))
                                            .foregroundColor(category == cat ? .white : AppColors.primary)
                                            .frame(width: 36, height: 36)
                                            .background(category == cat ? AppColors.primary : AppColors.primary.opacity(0.1))
                                            .clipShape(Circle())
                                        Text(cat.rawValue)
                                            .font(AppFonts.caption2())
                                            .foregroundColor(category == cat ? AppColors.primary : AppColors.secondaryText)
                                            .fontWeight(category == cat ? .semibold : .regular)
                                            .lineLimit(1)
                                    }
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(category == cat ? AppColors.primary.opacity(0.05) : Color.clear)
                                    .cornerRadius(10)
                                }
                            }
                        }
                    }

                    // Quantity and Unit
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Quantity", systemImage: "number")
                                .font(AppFonts.subheadline())
                                .foregroundColor(AppColors.secondaryText)
                            CustomTextField(
                                placeholder: "1",
                                text: $quantity,
                                keyboardType: .decimalPad
                            )
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Label("Unit", systemImage: "ruler")
                                .font(AppFonts.subheadline())
                                .foregroundColor(AppColors.secondaryText)
                            Menu {
                                ForEach(unitOptions, id: \.self) { u in
                                    Button(u) { unit = u }
                                }
                            } label: {
                                HStack {
                                    Text(unit)
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

                    // Price per unit
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Price per Unit (\(settingsViewModel.currencySymbol))", systemImage: "dollarsign.circle")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                        CustomTextField(
                            placeholder: "0.00",
                            text: $price,
                            keyboardType: .decimalPad,
                            systemImage: "dollarsign",
                            errorMessage: priceError
                        )

                        // Total preview
                        if let q = Double(quantity.replacingOccurrences(of: ",", with: ".")),
                           let p = Double(price.replacingOccurrences(of: ",", with: ".")) {
                            HStack {
                                Text("Total: ")
                                    .font(AppFonts.subheadline())
                                    .foregroundColor(AppColors.secondaryText)
                                Text((q * p).currencyString(currency: settingsViewModel.currency))
                                    .font(AppFonts.headline())
                                    .foregroundColor(AppColors.primary)
                            }
                        }
                    }

                    // Project
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

                    // Room
                    if preselectedRoomID == nil {
                        let rooms = selectedProjectID.flatMap { pid in
                            appViewModel.projects.first { $0.id == pid }
                        }?.rooms ?? []
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

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Notes (Optional)", systemImage: "note.text")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.secondaryText)
                        ZStack(alignment: .topLeading) {
                            if notes.isEmpty {
                                Text("Supplier, brand, specifications...")
                                    .font(AppFonts.body())
                                    .foregroundColor(Color(.placeholderText))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                            }
                            TextEditor(text: $notes)
                                .font(AppFonts.body())
                                .frame(minHeight: 80)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .opacity(notes.isEmpty ? 0.25 : 1)
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .frame(minHeight: 80)
                    }

                    Spacer(minLength: 20)
                }
                .padding(20)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Add Material")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                        .foregroundColor(AppColors.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: saveMaterial) {
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
        .onAppear {
            selectedRoomID = preselectedRoomID
            selectedProjectID = preselectedProjectID
            if let n = prefillName { name = n }
            if let q = prefillQuantity { quantity = String(format: "%.2f", q) }
            if let u = prefillUnit { unit = u }
        }
    }

    private func saveMaterial() {
        nameError = nil
        priceError = nil

        guard !name.trimmed.isEmpty else {
            nameError = "Material name is required"
            return
        }

        let p = Double(price.replacingOccurrences(of: ",", with: ".")) ?? 0
        let q = Double(quantity.replacingOccurrences(of: ",", with: ".")) ?? 1

        isSaving = true

        let material = Material(
            name: name.trimmed,
            category: category,
            quantity: q,
            unit: unit,
            price: p,
            roomID: preselectedRoomID ?? selectedRoomID,
            projectID: preselectedProjectID ?? selectedProjectID,
            notes: notes.trimmed
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            appViewModel.addMaterial(material)
            isSaving = false
            isPresented = false
        }
    }
}
