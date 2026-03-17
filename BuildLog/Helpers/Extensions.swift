import SwiftUI
import Foundation

// MARK: - Color from Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    func toHex() -> String {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return "#000000"
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "#%02lX%02lX%02lX",
                      lroundf(r * 255),
                      lroundf(g * 255),
                      lroundf(b * 255))
    }
}

// MARK: - Date Extensions
extension Date {
    func formatted(_ format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }

    var shortDate: String {
        formatted("MMM d, yyyy")
    }

    var mediumDate: String {
        formatted("MMMM d, yyyy")
    }

    var shortTime: String {
        formatted("h:mm a")
    }

    var dayMonthYear: String {
        formatted("dd MMM yyyy")
    }

    var relativeDateString: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) {
            return "Today"
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday"
        } else if calendar.isDateInTomorrow(self) {
            return "Tomorrow"
        } else {
            return shortDate
        }
    }

    var isOverdue: Bool {
        self < Date() && !Calendar.current.isDateInToday(self)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    static func fromString(_ string: String, format: String = "yyyy-MM-dd") -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.date(from: string)
    }

    func daysFrom(_ date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: date, to: self).day ?? 0
    }
}

// MARK: - Number Formatter
extension Double {
    func currencyString(currency: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        switch currency {
        case "EUR":
            formatter.currencyCode = "EUR"
            formatter.currencySymbol = "€"
        case "GBP":
            formatter.currencyCode = "GBP"
            formatter.currencySymbol = "£"
        case "RUB":
            formatter.currencyCode = "RUB"
            formatter.currencySymbol = "₽"
        default:
            formatter.currencyCode = "USD"
            formatter.currencySymbol = "$"
        }
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }

    func percentString() -> String {
        String(format: "%.0f%%", self * 100)
    }

    var compactString: String {
        if self >= 1_000_000 {
            return String(format: "%.1fM", self / 1_000_000)
        } else if self >= 1_000 {
            return String(format: "%.1fK", self / 1_000)
        } else {
            return String(format: "%.0f", self)
        }
    }
}

// MARK: - View Animations
extension View {
    func springAnimation() -> some View {
        self.animation(.spring(response: 0.4, dampingFraction: 0.7))
    }

    func fadeIn(delay: Double = 0) -> some View {
        self.transition(.opacity.animation(.easeInOut(duration: 0.3).delay(delay)))
    }

    func slideIn(from edge: Edge = .bottom, delay: Double = 0) -> some View {
        self.transition(.move(edge: edge).combined(with: .opacity)
            .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(delay)))
    }

    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - String Extensions
extension String {
    var isValidEmail: Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with: self)
    }

    var isValidPhone: Bool {
        let regex = "^[+]?[0-9]{7,15}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with: self.replacingOccurrences(of: " ", with: ""))
    }

    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func truncated(to length: Int) -> String {
        if count <= length { return self }
        return String(prefix(length)) + "..."
    }
}

// MARK: - Array Extensions
extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}

// MARK: - Binding Extensions
extension Binding where Value == String {
    func max(_ limit: Int) -> Self {
        if wrappedValue.count > limit {
            DispatchQueue.main.async {
                self.wrappedValue = String(self.wrappedValue.prefix(limit))
            }
        }
        return self
    }
}
