import SwiftUI

struct MaterialsView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @State private var selectedCategory: MaterialCategory? = nil
    @State private var searchText = ""
    @State private var showAddMaterial = false

    var filteredMaterials: [Material] {
        var result = appViewModel.materials
        if let cat = selectedCategory {
            result = result.filter { $0.category == cat }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.lowercased().contains(searchText.lowercased()) ||
                $0.category.rawValue.lowercased().contains(searchText.lowercased())
            }
        }
        return result
    }

    var totalCost: Double {
        filteredMaterials.reduce(0) { $0 + $1.totalCost }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                // Category filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        FilterChip(title: "All", isSelected: selectedCategory == nil) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedCategory = nil
                            }
                        }
                        ForEach(MaterialCategory.allCases, id: \.self) { cat in
                            FilterChip(title: cat.rawValue, isSelected: selectedCategory == cat) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedCategory = selectedCategory == cat ? nil : cat
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                .background(Color(.systemBackground))

                if appViewModel.materials.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "shippingbox",
                        title: "No Materials Yet",
                        subtitle: "Track materials for your renovation project.",
                        buttonTitle: "Add Material",
                        buttonAction: { showAddMaterial = true }
                    )
                    Spacer()
                } else if filteredMaterials.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "No Results",
                        subtitle: "Try changing your search or filter."
                    )
                    Spacer()
                } else {
                    // Summary card
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Total Materials")
                                .font(AppFonts.caption())
                                .foregroundColor(AppColors.secondaryText)
                            Text("\(filteredMaterials.count) items")
                                .font(AppFonts.headline())
                                .foregroundColor(AppColors.labelColor)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Total Cost")
                                .font(AppFonts.caption())
                                .foregroundColor(AppColors.secondaryText)
                            Text(totalCost.currencyString(currency: settingsViewModel.currency))
                                .font(AppFonts.headline())
                                .foregroundColor(AppColors.primary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))

                    List {
                        ForEach(filteredMaterials) { material in
                            MaterialListRow(material: material, currency: settingsViewModel.currency)
                                .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                        .onDelete { offsets in
                            appViewModel.deleteMaterials(at: offsets, from: filteredMaterials)
                        }

                        Spacer().frame(height: 80)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    .listStyle(PlainListStyle())
                    .background(AppColors.background)
                }
            }
            .background(AppColors.background.ignoresSafeArea())

            FABButton(action: { showAddMaterial = true })
                .padding(.trailing, 24)
                .padding(.bottom, 100)
        }
        .navigationTitle("Materials")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search materials")
        .sheet(isPresented: $showAddMaterial) {
            AddMaterialView(isPresented: $showAddMaterial)
                .environmentObject(appViewModel)
                .environmentObject(settingsViewModel)
        }
    }
}

// MARK: - Material List Row
struct MaterialListRow: View {
    let material: Material
    let currency: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppColors.primary.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: material.category.icon)
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(material.name)
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.labelColor)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    BadgeView(text: material.category.rawValue, color: AppColors.primary)
                    if let roomID = material.roomID {
                        Text(material.roomID.map { _ in "•" } ?? "")
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(material.totalCost.currencyString(currency: currency))
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.labelColor)
                Text("\(String(format: "%.1f", material.quantity)) \(material.unit)")
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.secondaryText)
            }
        }
        .padding(14)
        .background(AppColors.cardBackground)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}
