import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @State private var showLogoutAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var showImagePicker = false
    @State private var profileImage: UIImage? = nil
    @State private var editingName = ""
    @State private var editingEmail = ""
    @State private var isEditingProfile = false
    @State private var showExportSheet = false
    @State private var exportURL: URL? = nil
    @State private var showNotificationDeniedAlert = false

    var body: some View {
        List {
            // MARK: - Profile Section
            Section {
                HStack(spacing: 14) {
                    // Avatar
                    Button(action: { showImagePicker = true }) {
                        ZStack {
                            if let image = profileImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 64, height: 64)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(AppColors.primary.opacity(0.15))
                                    .frame(width: 64, height: 64)
                                    .overlay(
                                        Text(String(appViewModel.currentUser?.name.prefix(2) ?? "U").uppercased())
                                            .font(AppFonts.title3())
                                            .foregroundColor(AppColors.primary)
                                    )
                            }
                            Circle()
                                .strokeBorder(AppColors.primary.opacity(0.3), lineWidth: 1)
                                .frame(width: 64, height: 64)
                            Image(systemName: "camera.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.white)
                                .padding(5)
                                .background(AppColors.primary)
                                .clipShape(Circle())
                                .offset(x: 22, y: 22)
                        }
                    }

                    if isEditingProfile {
                        VStack(spacing: 8) {
                            TextField("Name", text: $editingName)
                                .font(AppFonts.headline())
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            TextField("Email", text: $editingEmail)
                                .font(AppFonts.subheadline())
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.emailAddress)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(appViewModel.currentUser?.name ?? "User")
                                .font(AppFonts.headline())
                                .foregroundColor(AppColors.labelColor)
                            Text(appViewModel.currentUser?.email ?? "")
                                .font(AppFonts.subheadline())
                                .foregroundColor(AppColors.secondaryText)
                        }
                    }

                    Spacer()

                    Button(action: {
                        if isEditingProfile {
                            saveProfile()
                        } else {
                            editingName = appViewModel.currentUser?.name ?? ""
                            editingEmail = appViewModel.currentUser?.email ?? ""
                            withAnimation { isEditingProfile = true }
                        }
                    }) {
                        Text(isEditingProfile ? "Save" : "Edit")
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.primary)
                    }
                }
                .padding(.vertical, 6)
            } header: {
                Text("Profile")
            }

            // MARK: - Appearance
            Section {
                // Theme
                HStack {
                    Label("Appearance", systemImage: "paintbrush")
                    Spacer()
                    Menu {
                        ForEach(settingsViewModel.themeOptions, id: \.value) { option in
                            Button(action: {
                                settingsViewModel.themeRaw = option.value
                            }) {
                                HStack {
                                    Text(option.label)
                                    if settingsViewModel.themeRaw == option.value {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(settingsViewModel.themeDisplayName)
                                .font(AppFonts.subheadline())
                                .foregroundColor(AppColors.secondaryText)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 10))
                                .foregroundColor(AppColors.secondaryText)
                        }
                    }
                }

                // Currency
                HStack {
                    Label("Currency", systemImage: "dollarsign.circle")
                    Spacer()
                    Menu {
                        ForEach(settingsViewModel.currencyOptions, id: \.self) { cur in
                            Button(action: { settingsViewModel.currency = cur }) {
                                HStack {
                                    Text(cur)
                                    if settingsViewModel.currency == cur {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(settingsViewModel.currency)
                                .font(AppFonts.subheadline())
                                .foregroundColor(AppColors.secondaryText)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 10))
                                .foregroundColor(AppColors.secondaryText)
                        }
                    }
                }

                // Distance Unit
                HStack {
                    Label("Distance Unit", systemImage: "ruler")
                    Spacer()
                    Menu {
                        ForEach(settingsViewModel.distanceUnitOptions, id: \.self) { unit in
                            Button(action: { settingsViewModel.distanceUnit = unit }) {
                                HStack {
                                    Text(unit.capitalized)
                                    if settingsViewModel.distanceUnit == unit {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(settingsViewModel.distanceUnit.capitalized)
                                .font(AppFonts.subheadline())
                                .foregroundColor(AppColors.secondaryText)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 10))
                                .foregroundColor(AppColors.secondaryText)
                        }
                    }
                }
            } header: {
                Text("Preferences")
            }

            // MARK: - Notifications
            Section {
                HStack {
                    Label("Notifications", systemImage: "bell")
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { settingsViewModel.notificationsEnabled },
                        set: { newValue in
                            if newValue {
                                settingsViewModel.checkNotificationStatus { authorized in
                                    if authorized {
                                        settingsViewModel.notificationsEnabled = true
                                    } else {
                                        settingsViewModel.requestNotificationPermission()
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                            settingsViewModel.checkNotificationStatus { auth in
                                                if !auth {
                                                    showNotificationDeniedAlert = true
                                                } else {
                                                    settingsViewModel.notificationsEnabled = true
                                                }
                                            }
                                        }
                                    }
                                }
                            } else {
                                settingsViewModel.notificationsEnabled = false
                            }
                        }
                    ))
                    .toggleStyle(SwitchToggleStyle(tint: AppColors.primary))
                    .labelsHidden()
                }
            } header: {
                Text("Notifications")
            } footer: {
                Text("Receive reminders for upcoming task deadlines")
            }

            // MARK: - Data
            Section {
                // Export
                Button(action: exportData) {
                    Label("Export Data", systemImage: "square.and.arrow.up")
                        .foregroundColor(AppColors.labelColor)
                }

                // Navigation links to other sections
                NavigationLink(destination:
                    MaterialsView()
                        .environmentObject(appViewModel)
                        .environmentObject(settingsViewModel)
                ) {
                    Label("Materials", systemImage: "shippingbox")
                }

                NavigationLink(destination:
                    ExpensesView()
                        .environmentObject(appViewModel)
                        .environmentObject(settingsViewModel)
                ) {
                    Label("Expenses", systemImage: "dollarsign.circle")
                }

                NavigationLink(destination:
                    ContractorsView()
                        .environmentObject(appViewModel)
                ) {
                    Label("Contractors", systemImage: "person.2")
                }

                NavigationLink(destination:
                    PhotosView()
                        .environmentObject(appViewModel)
                ) {
                    Label("All Photos", systemImage: "photo.stack")
                }

                NavigationLink(destination:
                    ReportsView()
                        .environmentObject(appViewModel)
                        .environmentObject(settingsViewModel)
                ) {
                    Label("Reports", systemImage: "chart.bar")
                }
            } header: {
                Text("Data & Reports")
            }

            // MARK: - About
            Section {
                HStack {
                    Label("App Version", systemImage: "info.circle")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(AppColors.secondaryText)
                }
                HStack {
                    Label("Projects", systemImage: "folder")
                    Spacer()
                    Text("\(appViewModel.projects.count)")
                        .foregroundColor(AppColors.secondaryText)
                }
                HStack {
                    Label("Total Expenses", systemImage: "banknote")
                    Spacer()
                    Text(appViewModel.totalSpent.currencyString(currency: settingsViewModel.currency))
                        .foregroundColor(AppColors.secondaryText)
                }
            } header: {
                Text("About")
            }

            // MARK: - Logout
            Section {
                Button(action: { showLogoutAlert = true }) {
                    HStack {
                        Image(systemName: "arrow.right.square")
                        Text("Sign Out")
                        Spacer()
                    }
                    .foregroundColor(AppColors.warning)
                }
                Button(action: { showDeleteAccountAlert = true }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete Account")
                        Spacer()
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .alert("Sign Out", isPresented: $showLogoutAlert) {
            Button("Sign Out", role: .destructive) {
                appViewModel.signOut()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
            Button("Delete", role: .destructive) {
                appViewModel.deleteAccount()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your account and all data. This action cannot be undone.")
        }
        .alert("Notifications Disabled", isPresented: $showNotificationDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable notifications in Settings to receive task reminders.")
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(image: $profileImage, sourceType: .photoLibrary)
        }
        .onChange(of: profileImage) { image in
            if let img = image {
                saveProfileAvatar(img)
            }
        }
        .sheet(isPresented: $showExportSheet) {
            if let url = exportURL {
                ShareSheet(url: url)
            }
        }
    }

    private func saveProfile() {
        guard var user = appViewModel.currentUser else { return }
        user.name = editingName.trimmed.isEmpty ? user.name : editingName.trimmed
        user.email = editingEmail.trimmed.isEmpty ? user.email : editingEmail.trimmed
        appViewModel.updateUser(user)
        withAnimation { isEditingProfile = false }
    }

    private func saveProfileAvatar(_ image: UIImage) {
        guard var user = appViewModel.currentUser else { return }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent("avatar.jpg")
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: url)
            user.avatarPath = url.path
            appViewModel.updateUser(user)
        }
    }

    private func exportData() {
        let json = settingsViewModel.exportData(from: appViewModel)
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent("renovatrack_export_\(Date().formatted("yyyyMMdd")).json")
        try? json.write(to: url, atomically: true, encoding: .utf8)
        exportURL = url
        showExportSheet = true
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
