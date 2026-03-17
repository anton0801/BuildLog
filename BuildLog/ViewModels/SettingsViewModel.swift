import Foundation
import SwiftUI
import UserNotifications

class SettingsViewModel: ObservableObject {
    // MARK: - Appearance
    @AppStorage("app_theme") var themeRaw: String = "system" {
        didSet { objectWillChange.send() }
    }

    // MARK: - Locale
    @AppStorage("app_currency") var currency: String = "USD" {
        didSet { objectWillChange.send() }
    }
    @AppStorage("app_distance_unit") var distanceUnit: String = "meters" {
        didSet { objectWillChange.send() }
    }

    // MARK: - Notifications
    @AppStorage("notifications_enabled") var notificationsEnabled: Bool = false {
        didSet {
            objectWillChange.send()
            handleNotificationToggle()
        }
    }

    // MARK: - Onboarding
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false

    // MARK: - Theme
    var colorScheme: ColorScheme? {
        switch themeRaw {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var themeOptions: [(label: String, value: String)] {
        [
            ("System", "system"),
            ("Light", "light"),
            ("Dark", "dark")
        ]
    }

    var currencyOptions: [String] { ["USD", "EUR", "GBP", "RUB"] }
    var distanceUnitOptions: [String] { ["meters", "feet"] }

    var currencySymbol: String {
        switch currency {
        case "EUR": return "€"
        case "GBP": return "£"
        case "RUB": return "₽"
        default: return "$"
        }
    }

    var themeDisplayName: String {
        switch themeRaw {
        case "light": return "Light"
        case "dark": return "Dark"
        default: return "System"
        }
    }

    var distanceUnitShort: String {
        distanceUnit == "feet" ? "ft" : "m"
    }

    // MARK: - Notification Handling
    private func handleNotificationToggle() {
        if notificationsEnabled {
            requestNotificationPermission()
        } else {
            disableNotifications()
        }
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if !granted {
                    self.notificationsEnabled = false
                }
            }
        }
    }

    private func disableNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    func scheduleTaskReminder(title: String, body: String, date: Date, identifier: String) {
        guard notificationsEnabled else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func checkNotificationStatus(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }

    // MARK: - Export
    func exportData(from appViewModel: AppViewModel) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601

        var exportParts: [String] = []
        exportParts.append("// RenovaTrack Data Export")
        exportParts.append("// Date: \(Date().mediumDate)")
        exportParts.append("")

        if let projectsData = try? encoder.encode(appViewModel.projects),
           let projectsStr = String(data: projectsData, encoding: .utf8) {
            exportParts.append("\"projects\": \(projectsStr)")
        }
        if let expensesData = try? encoder.encode(appViewModel.expenses),
           let expensesStr = String(data: expensesData, encoding: .utf8) {
            exportParts.append("\"expenses\": \(expensesStr)")
        }
        if let materialsData = try? encoder.encode(appViewModel.materials),
           let materialsStr = String(data: materialsData, encoding: .utf8) {
            exportParts.append("\"materials\": \(materialsStr)")
        }
        if let contractorsData = try? encoder.encode(appViewModel.contractors),
           let contractorsStr = String(data: contractorsData, encoding: .utf8) {
            exportParts.append("\"contractors\": \(contractorsStr)")
        }

        return "{\n" + exportParts.joined(separator: ",\n") + "\n}"
    }

    func formatAmount(_ amount: Double) -> String {
        amount.currencyString(currency: currency)
    }
}
