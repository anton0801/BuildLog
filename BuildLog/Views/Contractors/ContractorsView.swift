import SwiftUI

struct ContractorsView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @State private var showAddContractor = false
    @State private var searchText = ""

    var filteredContractors: [Contractor] {
        if searchText.isEmpty {
            return appViewModel.contractors
        }
        return appViewModel.contractors.filter {
            $0.name.lowercased().contains(searchText.lowercased()) ||
            $0.specialization.rawValue.lowercased().contains(searchText.lowercased())
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if appViewModel.contractors.isEmpty {
                    EmptyStateView(
                        icon: "person.2",
                        title: "No Contractors Yet",
                        subtitle: "Add contractors to keep track of your team.",
                        buttonTitle: "Add Contractor",
                        buttonAction: { showAddContractor = true }
                    )
                } else if filteredContractors.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "No Results",
                        subtitle: "No contractors match your search."
                    )
                } else {
                    List {
                        ForEach(filteredContractors) { contractor in
                            NavigationLink(destination:
                                ContractorDetailView(contractor: contractor)
                                    .environmentObject(appViewModel)
                                    .environmentObject(settingsViewModel)
                            ) {
                                ContractorCard(contractor: contractor)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                        .onDelete { offsets in
                            appViewModel.deleteContractors(at: offsets)
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

            FABButton(action: { showAddContractor = true })
                .padding(.trailing, 24)
                .padding(.bottom, 100)
        }
        .navigationTitle("Contractors")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search contractors")
        .sheet(isPresented: $showAddContractor) {
            AddContractorView(isPresented: $showAddContractor)
                .environmentObject(appViewModel)
        }
    }
}

// MARK: - Contractor Card
struct ContractorCard: View {
    let contractor: Contractor
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(AppColors.primary.opacity(0.1))
                        .frame(width: 48, height: 48)
                    Text(String(contractor.name.prefix(2)).uppercased())
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.primary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(contractor.name)
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.labelColor)
                    HStack(spacing: 6) {
                        Image(systemName: contractor.specialization.icon)
                            .font(.system(size: 11))
                            .foregroundColor(AppColors.primary)
                        Text(contractor.specialization.rawValue)
                            .font(AppFonts.caption())
                            .foregroundColor(AppColors.secondaryText)
                    }
                }

                Spacer()

                // Star Rating
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= contractor.rating ? "star.fill" : "star")
                            .font(.system(size: 11))
                            .foregroundColor(star <= contractor.rating ? Color(hex: "#FF8A00") : Color(.systemGray4))
                    }
                }
            }

            if !contractor.phone.isEmpty || !contractor.email.isEmpty {
                Divider()
                    .padding(.vertical, 10)

                HStack(spacing: 16) {
                    if !contractor.phone.isEmpty {
                        Button(action: {
                            let phone = contractor.phone.replacingOccurrences(of: " ", with: "")
                            if let url = URL(string: "tel://\(phone)") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 12))
                                Text(contractor.phone)
                                    .font(AppFonts.subheadline())
                                    .lineLimit(1)
                            }
                            .foregroundColor(AppColors.progress)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(AppColors.progress.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }

                    if !contractor.email.isEmpty {
                        Button(action: {
                            if let url = URL(string: "mailto:\(contractor.email)") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 12))
                                Text(contractor.email)
                                    .font(AppFonts.subheadline())
                                    .lineLimit(1)
                            }
                            .foregroundColor(AppColors.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(AppColors.primary.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
            }

            if !contractor.notes.isEmpty {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack {
                        Text(isExpanded ? "Hide Notes" : "Show Notes")
                            .font(AppFonts.caption())
                            .foregroundColor(AppColors.primary)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10))
                            .foregroundColor(AppColors.primary)
                    }
                }
                .padding(.top, 8)

                if isExpanded {
                    Text(contractor.notes)
                        .font(AppFonts.subheadline())
                        .foregroundColor(AppColors.secondaryText)
                        .padding(.top, 6)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .padding(14)
        .background(AppColors.cardBackground)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}
