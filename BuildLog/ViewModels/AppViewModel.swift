import Foundation
import SwiftUI
import Combine

class AppViewModel: ObservableObject {
    // MARK: - Auth State
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User? = nil

    // MARK: - Data
    @Published var projects: [Project] = []
    @Published var photos: [Photo] = []
    @Published var materials: [Material] = []
    @Published var expenses: [Expense] = []
    @Published var contractors: [Contractor] = []
    @Published var timelineEvents: [TimelineEvent] = []

    // MARK: - UI State
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    // MARK: - Persistence Keys
    private let projectsKey = "projects_data"
    private let photosKey = "photos_data"
    private let materialsKey = "materials_data"
    private let expensesKey = "expenses_data"
    private let contractorsKey = "contractors_data"
    private let timelineKey = "timeline_data"
    private let userKey = "current_user"

    init() {
        loadAllData()
    }

    // MARK: - Computed Properties
    var allTasks: [TaskItem] {
        projects.flatMap { $0.rooms.flatMap { $0.tasks } }
    }

    var todaysTasks: [TaskItem] {
        allTasks.filter { task in
            guard let deadline = task.deadline else { return false }
            return Calendar.current.isDateInToday(deadline) && task.status != .done
        }
    }

    var recentPhotos: [Photo] {
        Array(photos.sorted { $0.createdAt > $1.createdAt }.prefix(10))
    }

    var totalBudget: Double {
        projects.reduce(0) { $0 + $1.budget }
    }

    var totalSpent: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    var overallProgress: Double {
        let allTasksList = allTasks
        guard !allTasksList.isEmpty else { return 0 }
        let done = allTasksList.filter { $0.status == .done }.count
        return Double(done) / Double(allTasksList.count)
    }

    var activeProject: Project? {
        projects.first { $0.status == .inProgress }
    }

    var budgetRemaining: Double {
        totalBudget - totalSpent
    }

    var budgetProgress: Double {
        guard totalBudget > 0 else { return 0 }
        return min(totalSpent / totalBudget, 1.0)
    }

    // MARK: - Project CRUD
    func addProject(_ project: Project) {
        projects.append(project)
        addTimelineEvent(TimelineEvent(
            type: .milestone,
            title: "Project Created: \(project.name)",
            description: "New project started",
            date: Date(),
            referenceID: project.id,
            projectID: project.id
        ))
        saveProjects()
    }

    func updateProject(_ project: Project) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = project
            saveProjects()
        }
    }

    func deleteProject(_ project: Project) {
        projects.removeAll { $0.id == project.id }
        expenses.removeAll { $0.projectID == project.id }
        materials.removeAll { $0.projectID == project.id }
        photos.removeAll { $0.projectID == project.id }
        timelineEvents.removeAll { $0.projectID == project.id }
        saveProjects()
        saveExpenses()
        saveMaterials()
        savePhotos()
        saveTimeline()
    }

    func deleteProjects(at offsets: IndexSet) {
        let toDelete = offsets.map { projects[$0] }
        toDelete.forEach { deleteProject($0) }
    }

    // MARK: - Room CRUD
    func addRoom(_ room: Room, toProject projectID: UUID) {
        guard let pIndex = projects.firstIndex(where: { $0.id == projectID }) else { return }
        projects[pIndex].rooms.append(room)
        saveProjects()
    }

    func updateRoom(_ room: Room, inProject projectID: UUID) {
        guard let pIndex = projects.firstIndex(where: { $0.id == projectID }) else { return }
        if let rIndex = projects[pIndex].rooms.firstIndex(where: { $0.id == room.id }) {
            projects[pIndex].rooms[rIndex] = room
            saveProjects()
        }
    }

    func deleteRoom(_ room: Room, fromProject projectID: UUID) {
        guard let pIndex = projects.firstIndex(where: { $0.id == projectID }) else { return }
        projects[pIndex].rooms.removeAll { $0.id == room.id }
        saveProjects()
    }

    // MARK: - Task CRUD
    func addTask(_ task: TaskItem, toRoom roomID: UUID, inProject projectID: UUID) {
        guard let pIndex = projects.firstIndex(where: { $0.id == projectID }) else { return }
        guard let rIndex = projects[pIndex].rooms.firstIndex(where: { $0.id == roomID }) else { return }
        projects[pIndex].rooms[rIndex].tasks.append(task)
        addTimelineEvent(TimelineEvent(
            type: .task,
            title: "Task Added: \(task.title)",
            description: task.description,
            date: Date(),
            referenceID: task.id,
            projectID: projectID
        ))
        saveProjects()
    }

    func updateTask(_ task: TaskItem) {
        for pIndex in projects.indices {
            for rIndex in projects[pIndex].rooms.indices {
                if let tIndex = projects[pIndex].rooms[rIndex].tasks.firstIndex(where: { $0.id == task.id }) {
                    projects[pIndex].rooms[rIndex].tasks[tIndex] = task
                    saveProjects()
                    return
                }
            }
        }
    }

    func deleteTask(_ task: TaskItem) {
        for pIndex in projects.indices {
            for rIndex in projects[pIndex].rooms.indices {
                projects[pIndex].rooms[rIndex].tasks.removeAll { $0.id == task.id }
            }
        }
        saveProjects()
    }

    func advanceTaskStatus(_ task: TaskItem) {
        var updated = task
        updated.status = task.status.next
        updateTask(updated)
        if updated.status == .done {
            addTimelineEvent(TimelineEvent(
                type: .task,
                title: "Task Completed: \(task.title)",
                date: Date(),
                referenceID: task.id,
                projectID: task.projectID
            ))
            saveTimeline()
        }
    }

    // MARK: - Photo CRUD
    func addPhoto(_ photo: Photo) {
        photos.insert(photo, at: 0)
        addTimelineEvent(TimelineEvent(
            type: .photo,
            title: "Photo Added",
            description: photo.description,
            date: Date(),
            referenceID: photo.id,
            projectID: photo.projectID
        ))
        savePhotos()
        saveTimeline()
    }

    func deletePhoto(_ photo: Photo) {
        // Delete file from disk if exists
        if !photo.imagePath.isEmpty {
            let url = URL(fileURLWithPath: photo.imagePath)
            try? FileManager.default.removeItem(at: url)
        }
        photos.removeAll { $0.id == photo.id }
        savePhotos()
    }

    // MARK: - Material CRUD
    func addMaterial(_ material: Material) {
        materials.append(material)
        saveMaterials()
    }

    func updateMaterial(_ material: Material) {
        if let index = materials.firstIndex(where: { $0.id == material.id }) {
            materials[index] = material
            saveMaterials()
        }
    }

    func deleteMaterial(_ material: Material) {
        materials.removeAll { $0.id == material.id }
        saveMaterials()
    }

    func deleteMaterials(at offsets: IndexSet, from filteredList: [Material]) {
        let toDelete = offsets.map { filteredList[$0] }
        toDelete.forEach { deleteMaterial($0) }
    }

    // MARK: - Expense CRUD
    func addExpense(_ expense: Expense) {
        expenses.append(expense)
        addTimelineEvent(TimelineEvent(
            type: .expense,
            title: "Expense: \(expense.name)",
            description: String(format: "$%.2f - %@", expense.amount, expense.category.rawValue),
            date: Date(),
            referenceID: expense.id,
            projectID: expense.projectID
        ))
        saveExpenses()
        saveTimeline()
    }

    func updateExpense(_ expense: Expense) {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index] = expense
            saveExpenses()
        }
    }

    func deleteExpense(_ expense: Expense) {
        expenses.removeAll { $0.id == expense.id }
        saveExpenses()
    }

    func deleteExpenses(at offsets: IndexSet, from filteredList: [Expense]) {
        let toDelete = offsets.map { filteredList[$0] }
        toDelete.forEach { deleteExpense($0) }
    }

    func expensesByCategory() -> [ExpenseCategory: Double] {
        var result: [ExpenseCategory: Double] = [:]
        for exp in expenses {
            result[exp.category, default: 0] += exp.amount
        }
        return result
    }

    // MARK: - Contractor CRUD
    func addContractor(_ contractor: Contractor) {
        contractors.append(contractor)
        saveContractors()
    }

    func updateContractor(_ contractor: Contractor) {
        if let index = contractors.firstIndex(where: { $0.id == contractor.id }) {
            contractors[index] = contractor
            saveContractors()
        }
    }

    func deleteContractor(_ contractor: Contractor) {
        contractors.removeAll { $0.id == contractor.id }
        saveContractors()
    }

    func deleteContractors(at offsets: IndexSet) {
        let toDelete = offsets.map { contractors[$0] }
        toDelete.forEach { deleteContractor($0) }
    }

    // MARK: - Timeline
    func addTimelineEvent(_ event: TimelineEvent) {
        timelineEvents.insert(event, at: 0)
        saveTimeline()
    }

    // MARK: - Auth
    func signIn(user: User) {
        currentUser = user
        isAuthenticated = true
        saveUser()
        if projects.isEmpty {
            loadSampleData()
        }
    }

    func signOut() {
        isAuthenticated = false
        currentUser = nil
        clearUserSession()
    }

    func updateUser(_ user: User) {
        currentUser = user
        saveUser()
    }

    // MARK: - Sample Data
    func loadSampleData() {
        projects = Project.samples
        expenses = Expense.samples
        materials = Material.samples
        contractors = Contractor.samples

        // Generate timeline events from sample data
        for project in projects {
            timelineEvents.append(TimelineEvent(
                type: .milestone,
                title: "Project Started: \(project.name)",
                date: project.startDate,
                referenceID: project.id,
                projectID: project.id
            ))
            for room in project.rooms {
                for task in room.tasks {
                    if task.status == .done {
                        timelineEvents.append(TimelineEvent(
                            type: .task,
                            title: "Task Completed: \(task.title)",
                            date: task.createdAt,
                            referenceID: task.id,
                            projectID: project.id
                        ))
                    }
                }
            }
        }

        for expense in expenses {
            timelineEvents.append(TimelineEvent(
                type: .expense,
                title: "Expense: \(expense.name)",
                description: String(format: "$%.2f", expense.amount),
                date: expense.date,
                referenceID: expense.id
            ))
        }

        timelineEvents.sort { $0.date > $1.date }
        saveAllData()
    }

    // MARK: - Helpers
    func projectName(for id: UUID?) -> String {
        guard let id = id else { return "Unknown" }
        return projects.first { $0.id == id }?.name ?? "Unknown"
    }

    func roomName(for id: UUID?) -> String {
        guard let id = id else { return "Unknown" }
        for project in projects {
            if let room = project.rooms.first(where: { $0.id == id }) {
                return room.name
            }
        }
        return "Unknown"
    }

    func project(for id: UUID?) -> Project? {
        guard let id = id else { return nil }
        return projects.first { $0.id == id }
    }

    func room(for roomID: UUID?, inProject projectID: UUID?) -> Room? {
        guard let rid = roomID, let pid = projectID else { return nil }
        return projects.first { $0.id == pid }?.rooms.first { $0.id == rid }
    }

    func allRooms() -> [(room: Room, project: Project)] {
        projects.flatMap { project in
            project.rooms.map { (room: $0, project: project) }
        }
    }

    // MARK: - Export
    func exportJSON() -> String {
        let exportData: [String: Any] = [
            "exportDate": Date().shortDate,
            "projects": (try? JSONEncoder().encode(projects)).flatMap { String(data: $0, encoding: .utf8) } ?? "[]",
            "expenses": (try? JSONEncoder().encode(expenses)).flatMap { String(data: $0, encoding: .utf8) } ?? "[]",
            "materials": (try? JSONEncoder().encode(materials)).flatMap { String(data: $0, encoding: .utf8) } ?? "[]",
            "contractors": (try? JSONEncoder().encode(contractors)).flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        ]
        if let data = try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted),
           let string = String(data: data, encoding: .utf8) {
            return string
        }
        return "{}"
    }

    // MARK: - Persistence
    private func documentsURL(for key: String) -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("\(key).json")
    }

    private func save<T: Encodable>(_ object: T, key: String) {
        let url = documentsURL(for: key)
        do {
            let data = try JSONEncoder().encode(object)
            try data.write(to: url, options: .atomicWrite)
        } catch {
            print("Save error for \(key): \(error)")
        }
    }

    private func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        let url = documentsURL(for: key)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    func saveProjects() { save(projects, key: projectsKey) }
    func savePhotos() { save(photos, key: photosKey) }
    func saveMaterials() { save(materials, key: materialsKey) }
    func saveExpenses() { save(expenses, key: expensesKey) }
    func saveContractors() { save(contractors, key: contractorsKey) }
    func saveTimeline() { save(timelineEvents, key: timelineKey) }
    func saveUser() { if let user = currentUser { save(user, key: userKey) } }

    func saveAllData() {
        saveProjects()
        savePhotos()
        saveMaterials()
        saveExpenses()
        saveContractors()
        saveTimeline()
    }

    func loadAllData() {
        if let savedProjects = load([Project].self, key: projectsKey) {
            projects = savedProjects
        }
        if let savedPhotos = load([Photo].self, key: photosKey) {
            photos = savedPhotos
        }
        if let savedMaterials = load([Material].self, key: materialsKey) {
            materials = savedMaterials
        }
        if let savedExpenses = load([Expense].self, key: expensesKey) {
            expenses = savedExpenses
        }
        if let savedContractors = load([Contractor].self, key: contractorsKey) {
            contractors = savedContractors
        }
        if let savedTimeline = load([TimelineEvent].self, key: timelineKey) {
            timelineEvents = savedTimeline
        }
        if let savedUser = load(User.self, key: userKey) {
            currentUser = savedUser
            isAuthenticated = true
        }
    }

    func clearUserSession() {
        let url = documentsURL(for: userKey)
        try? FileManager.default.removeItem(at: url)
    }
}
