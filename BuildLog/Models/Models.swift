import Foundation
import SwiftUI

// MARK: - User
struct User: Codable, Identifiable {
    var id: UUID
    var name: String
    var email: String
    var avatarPath: String?
    var createdAt: Date

    init(id: UUID = UUID(), name: String, email: String, avatarPath: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.email = email
        self.avatarPath = avatarPath
        self.createdAt = createdAt
    }

    static let sample = User(name: "Alex Johnson", email: "alex@example.com")
}

// MARK: - Project Type
enum ProjectType: String, Codable, CaseIterable {
    case apartment = "Apartment"
    case house = "House"
    case room = "Room"
    case office = "Office"

    var icon: String {
        switch self {
        case .apartment: return "building.2"
        case .house: return "house"
        case .room: return "door.left.hand.open"
        case .office: return "briefcase"
        }
    }
}

// MARK: - Project Status
enum ProjectStatus: String, Codable, CaseIterable {
    case planning = "Planning"
    case inProgress = "In Progress"
    case onHold = "On Hold"
    case completed = "Completed"

    var color: String {
        switch self {
        case .planning: return "#2F80ED"
        case .inProgress: return "#FF8A00"
        case .onHold: return "#EB5757"
        case .completed: return "#27AE60"
        }
    }
}

// MARK: - Project
struct Project: Codable, Identifiable {
    var id: UUID
    var name: String
    var type: ProjectType
    var status: ProjectStatus
    var startDate: Date
    var endDate: Date?
    var budget: Double
    var notes: String
    var rooms: [Room]
    var createdAt: Date

    init(id: UUID = UUID(),
         name: String,
         type: ProjectType = .apartment,
         status: ProjectStatus = .planning,
         startDate: Date = Date(),
         endDate: Date? = nil,
         budget: Double = 0,
         notes: String = "",
         rooms: [Room] = [],
         createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.type = type
        self.status = status
        self.startDate = startDate
        self.endDate = endDate
        self.budget = budget
        self.notes = notes
        self.rooms = rooms
        self.createdAt = createdAt
    }

    var progress: Double {
        let allTasks = rooms.flatMap { $0.tasks }
        guard !allTasks.isEmpty else { return 0 }
        let completed = allTasks.filter { $0.status == .done }.count
        return Double(completed) / Double(allTasks.count)
    }

    var totalTaskCount: Int {
        rooms.flatMap { $0.tasks }.count
    }

    static let samples: [Project] = {
        var project1 = Project(
            name: "Living Room Renovation",
            type: .room,
            status: .inProgress,
            startDate: Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date(),
            budget: 8500,
            notes: "Full renovation including flooring, painting and furniture"
        )
        var room1 = Room(name: "Living Room", icon: "sofa", projectID: project1.id)
        var task1 = TaskItem(title: "Paint walls", roomID: room1.id, projectID: project1.id, deadline: Calendar.current.date(byAdding: .day, value: 2, to: Date()), priority: .high, status: .inProgress, estimatedCost: 300)
        var task2 = TaskItem(title: "Install flooring", roomID: room1.id, projectID: project1.id, deadline: Calendar.current.date(byAdding: .day, value: 5, to: Date()), priority: .medium, status: .todo, estimatedCost: 1200)
        var task3 = TaskItem(title: "Move furniture", roomID: room1.id, projectID: project1.id, deadline: Calendar.current.date(byAdding: .day, value: -2, to: Date()), priority: .low, status: .done, estimatedCost: 150)
        room1.tasks = [task1, task2, task3]
        project1.rooms = [room1]

        var project2 = Project(
            name: "Kitchen Remodel",
            type: .room,
            status: .planning,
            startDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
            budget: 15000,
            notes: "New cabinets, countertops and appliances"
        )
        var room2 = Room(name: "Kitchen", icon: "fork.knife", projectID: project2.id)
        var kTask1 = TaskItem(title: "Remove old cabinets", roomID: room2.id, projectID: project2.id, deadline: Calendar.current.date(byAdding: .day, value: 10, to: Date()), priority: .high, status: .todo, estimatedCost: 500)
        var kTask2 = TaskItem(title: "Install new cabinets", roomID: room2.id, projectID: project2.id, deadline: Calendar.current.date(byAdding: .day, value: 20, to: Date()), priority: .high, status: .todo, estimatedCost: 3000)
        room2.tasks = [kTask1, kTask2]
        project2.rooms = [room2]

        return [project1, project2]
    }()
}

// MARK: - Room
struct Room: Codable, Identifiable {
    var id: UUID
    var name: String
    var icon: String
    var projectID: UUID
    var tasks: [TaskItem]
    var notes: String
    var createdAt: Date

    init(id: UUID = UUID(),
         name: String,
         icon: String = "square",
         projectID: UUID,
         tasks: [TaskItem] = [],
         notes: String = "",
         createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.icon = icon
        self.projectID = projectID
        self.tasks = tasks
        self.notes = notes
        self.createdAt = createdAt
    }

    var progress: Double {
        guard !tasks.isEmpty else { return 0 }
        let done = tasks.filter { $0.status == .done }.count
        return Double(done) / Double(tasks.count)
    }

    var availableIcons: [String] {
        ["square", "sofa", "fork.knife", "bed.double", "shower", "house", "door.left.hand.open", "lamp.desk", "wrench.and.screwdriver", "trash"]
    }
}

// MARK: - Task Priority
enum TaskPriority: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"

    var color: Color {
        switch self {
        case .low: return Color(hex: "#27AE60")
        case .medium: return Color(hex: "#2F80ED")
        case .high: return Color(hex: "#FF8A00")
        case .critical: return Color(hex: "#EB5757")
        }
    }

    var icon: String {
        switch self {
        case .low: return "arrow.down"
        case .medium: return "minus"
        case .high: return "arrow.up"
        case .critical: return "exclamationmark.2"
        }
    }
}

// MARK: - Task Status
enum TaskStatus: String, Codable, CaseIterable {
    case todo = "To Do"
    case inProgress = "In Progress"
    case done = "Done"

    var color: Color {
        switch self {
        case .todo: return Color(hex: "#2F80ED")
        case .inProgress: return Color(hex: "#FF8A00")
        case .done: return Color(hex: "#27AE60")
        }
    }

    var icon: String {
        switch self {
        case .todo: return "circle"
        case .inProgress: return "circle.lefthalf.filled"
        case .done: return "checkmark.circle.fill"
        }
    }

    var next: TaskStatus {
        switch self {
        case .todo: return .inProgress
        case .inProgress: return .done
        case .done: return .todo
        }
    }
}

// MARK: - Task
struct TaskItem: Codable, Identifiable {
    var id: UUID
    var title: String
    var description: String
    var roomID: UUID?
    var projectID: UUID?
    var deadline: Date?
    var priority: TaskPriority
    var status: TaskStatus
    var estimatedCost: Double
    var photoIDs: [UUID]
    var createdAt: Date

    init(id: UUID = UUID(),
         title: String,
         description: String = "",
         roomID: UUID? = nil,
         projectID: UUID? = nil,
         deadline: Date? = nil,
         priority: TaskPriority = .medium,
         status: TaskStatus = .todo,
         estimatedCost: Double = 0,
         photoIDs: [UUID] = [],
         createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.description = description
        self.roomID = roomID
        self.projectID = projectID
        self.deadline = deadline
        self.priority = priority
        self.status = status
        self.estimatedCost = estimatedCost
        self.photoIDs = photoIDs
        self.createdAt = createdAt
    }

    var isOverdue: Bool {
        guard let dl = deadline else { return false }
        return dl < Date() && status != .done
    }
}

// MARK: - Photo
struct Photo: Codable, Identifiable {
    var id: UUID
    var imagePath: String
    var description: String
    var roomID: UUID?
    var projectID: UUID?
    var taskID: UUID?
    var takenAt: Date
    var createdAt: Date

    init(id: UUID = UUID(),
         imagePath: String,
         description: String = "",
         roomID: UUID? = nil,
         projectID: UUID? = nil,
         taskID: UUID? = nil,
         takenAt: Date = Date(),
         createdAt: Date = Date()) {
        self.id = id
        self.imagePath = imagePath
        self.description = description
        self.roomID = roomID
        self.projectID = projectID
        self.taskID = taskID
        self.takenAt = takenAt
        self.createdAt = createdAt
    }
}

// MARK: - Material Category
enum MaterialCategory: String, Codable, CaseIterable {
    case paint = "Paint"
    case flooring = "Flooring"
    case tiles = "Tiles"
    case plumbing = "Plumbing"
    case electrical = "Electrical"
    case furniture = "Furniture"
    case fixtures = "Fixtures"
    case tools = "Tools"
    case other = "Other"

    var icon: String {
        switch self {
        case .paint: return "paintbrush"
        case .flooring: return "square.grid.3x3"
        case .tiles: return "square.grid.2x2"
        case .plumbing: return "drop"
        case .electrical: return "bolt"
        case .furniture: return "sofa"
        case .fixtures: return "lightbulb"
        case .tools: return "wrench"
        case .other: return "archivebox"
        }
    }
}

// MARK: - Material
struct Material: Codable, Identifiable {
    var id: UUID
    var name: String
    var category: MaterialCategory
    var quantity: Double
    var unit: String
    var price: Double
    var roomID: UUID?
    var projectID: UUID?
    var notes: String
    var createdAt: Date

    init(id: UUID = UUID(),
         name: String,
         category: MaterialCategory = .other,
         quantity: Double = 1,
         unit: String = "pcs",
         price: Double = 0,
         roomID: UUID? = nil,
         projectID: UUID? = nil,
         notes: String = "",
         createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.category = category
        self.quantity = quantity
        self.unit = unit
        self.price = price
        self.roomID = roomID
        self.projectID = projectID
        self.notes = notes
        self.createdAt = createdAt
    }

    var totalCost: Double { quantity * price }

    static let samples: [Material] = [
        Material(name: "Interior Paint - White", category: .paint, quantity: 10, unit: "L", price: 15.0),
        Material(name: "Hardwood Flooring", category: .flooring, quantity: 25, unit: "m²", price: 45.0),
        Material(name: "Ceramic Tiles", category: .tiles, quantity: 30, unit: "m²", price: 22.0),
        Material(name: "LED Light Fixtures", category: .fixtures, quantity: 8, unit: "pcs", price: 35.0)
    ]
}

// MARK: - Expense Category
enum ExpenseCategory: String, Codable, CaseIterable {
    case materials = "Materials"
    case labor = "Labor"
    case delivery = "Delivery"
    case tools = "Tools"
    case furniture = "Furniture"
    case other = "Other"

    var icon: String {
        switch self {
        case .materials: return "shippingbox"
        case .labor: return "person.2"
        case .delivery: return "truck.box"
        case .tools: return "wrench.and.screwdriver"
        case .furniture: return "sofa"
        case .other: return "banknote"
        }
    }

    var color: Color {
        switch self {
        case .materials: return Color(hex: "#2F80ED")
        case .labor: return Color(hex: "#FF8A00")
        case .delivery: return Color(hex: "#27AE60")
        case .tools: return Color(hex: "#EB5757")
        case .furniture: return Color(hex: "#9B51E0")
        case .other: return Color(hex: "#56CCF2")
        }
    }
}

// MARK: - Expense
struct Expense: Codable, Identifiable {
    var id: UUID
    var name: String
    var category: ExpenseCategory
    var amount: Double
    var date: Date
    var roomID: UUID?
    var projectID: UUID?
    var notes: String
    var createdAt: Date

    init(id: UUID = UUID(),
         name: String,
         category: ExpenseCategory = .other,
         amount: Double = 0,
         date: Date = Date(),
         roomID: UUID? = nil,
         projectID: UUID? = nil,
         notes: String = "",
         createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.category = category
        self.amount = amount
        self.date = date
        self.roomID = roomID
        self.projectID = projectID
        self.notes = notes
        self.createdAt = createdAt
    }

    static let samples: [Expense] = [
        Expense(name: "Paint purchase", category: .materials, amount: 150, date: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date()),
        Expense(name: "Electrician work", category: .labor, amount: 800, date: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()),
        Expense(name: "Floor delivery", category: .delivery, amount: 120, date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()),
        Expense(name: "Power drill rental", category: .tools, amount: 45, date: Date())
    ]
}

// MARK: - Contractor Specialization
enum ContractorSpecialization: String, Codable, CaseIterable {
    case general = "General"
    case electrician = "Electrician"
    case plumber = "Plumber"
    case painter = "Painter"
    case tiler = "Tiler"
    case carpenter = "Carpenter"
    case designer = "Interior Designer"
    case demolition = "Demolition"
    case flooring = "Flooring"
    case other = "Other"

    var icon: String {
        switch self {
        case .general: return "hammer"
        case .electrician: return "bolt"
        case .plumber: return "drop"
        case .painter: return "paintbrush"
        case .tiler: return "square.grid.2x2"
        case .carpenter: return "hammer.fill"
        case .designer: return "pencil.and.ruler"
        case .demolition: return "xmark.bin"
        case .flooring: return "square.grid.3x3"
        case .other: return "person"
        }
    }
}

// MARK: - Contractor
struct Contractor: Codable, Identifiable {
    var id: UUID
    var name: String
    var specialization: ContractorSpecialization
    var phone: String
    var email: String
    var notes: String
    var rating: Int
    var createdAt: Date

    init(id: UUID = UUID(),
         name: String,
         specialization: ContractorSpecialization = .general,
         phone: String = "",
         email: String = "",
         notes: String = "",
         rating: Int = 0,
         createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.specialization = specialization
        self.phone = phone
        self.email = email
        self.notes = notes
        self.rating = rating
        self.createdAt = createdAt
    }

    static let samples: [Contractor] = [
        Contractor(name: "Mike Thompson", specialization: .electrician, phone: "+1 555-0101", email: "mike@example.com", notes: "Very reliable, good rates", rating: 5),
        Contractor(name: "Sarah Williams", specialization: .painter, phone: "+1 555-0102", email: "sarah@example.com", notes: "Excellent finish quality", rating: 4),
        Contractor(name: "Carlos Rodriguez", specialization: .plumber, phone: "+1 555-0103", email: "carlos@example.com", notes: "24/7 availability", rating: 4)
    ]
}

// MARK: - Timeline Event Type
enum TimelineEventType: String, Codable, CaseIterable {
    case task = "Task"
    case photo = "Photo"
    case expense = "Expense"
    case note = "Note"
    case milestone = "Milestone"

    var icon: String {
        switch self {
        case .task: return "checkmark.circle"
        case .photo: return "camera"
        case .expense: return "dollarsign.circle"
        case .note: return "note.text"
        case .milestone: return "flag"
        }
    }

    var color: Color {
        switch self {
        case .task: return Color(hex: "#2F80ED")
        case .photo: return Color(hex: "#27AE60")
        case .expense: return Color(hex: "#FF8A00")
        case .note: return Color(.systemGray)
        case .milestone: return Color(hex: "#EB5757")
        }
    }
}

// MARK: - Timeline Event
struct TimelineEvent: Codable, Identifiable {
    var id: UUID
    var type: TimelineEventType
    var title: String
    var description: String
    var date: Date
    var referenceID: UUID?
    var projectID: UUID?

    init(id: UUID = UUID(),
         type: TimelineEventType,
         title: String,
         description: String = "",
         date: Date = Date(),
         referenceID: UUID? = nil,
         projectID: UUID? = nil) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.date = date
        self.referenceID = referenceID
        self.projectID = projectID
    }
}

// MARK: - Room Icons
struct RoomIcons {
    static let all: [(name: String, icon: String)] = [
        ("Living Room", "sofa"),
        ("Kitchen", "fork.knife"),
        ("Bedroom", "bed.double"),
        ("Bathroom", "shower"),
        ("Hallway", "door.left.hand.open"),
        ("Office", "desktopcomputer"),
        ("Garage", "car"),
        ("Laundry", "washer"),
        ("Dining Room", "fork.knife.circle"),
        ("Basement", "archivebox"),
        ("Attic", "house.lodge"),
        ("Other", "square")
    ]
}
