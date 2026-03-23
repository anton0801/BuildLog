import SwiftUI
import Combine
import Network

@MainActor
final class BuildLogViewModel: ObservableObject {
    
    @Published var showPermissionPrompt = false
    @Published var showOfflineView = false
    @Published var navigateToMain = false
    @Published var navigateToWeb = false
    
    private let application: BuildLogApplication
    private let networkMonitor = NWPathMonitor()
    private var cancellables = Set<AnyCancellable>()
    
    init(application: BuildLogApplication) {
        self.application = application
        setupNetworkMonitoring()
        setupNotificationStreams()
    }
    
    func start() {
        application.initialize()
    }
    
    func requestPermission() {
        application.requestNotificationPermission()
    }
    
    func deferPermission() {
        application.deferNotificationPermission()
    }
    
    func handleEvent(_ event: DomainEvent) {
        switch event {
        case .endpointConfigured(let config):
            if let permission = try? getPermission(), permission.canPrompt {
                showPermissionPrompt = true
            } else {
                navigateToWeb = true
            }
            
        case .applicationReady:
            showPermissionPrompt = false
            navigateToWeb = true
            
        case .applicationFailed:
            navigateToMain = true
            
        case .networkConnected:
            showOfflineView = false
            
        case .networkDisconnected:
            showOfflineView = true
            
        case .permissionStateUpdated:
            break
            
        default:
            break
        }
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.application.handleNetworkStatusChange(isConnected: path.status == .satisfied)
            }
        }
        networkMonitor.start(queue: .global(qos: .background))
    }
    
    private func setupNotificationStreams() {
        NotificationCenter.default.publisher(for: Notification.Name("ConversionDataReceived"))
            .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
            .sink { [weak self] data in
                self?.application.handleTrackingData(data)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name("deeplink_values"))
            .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
            .sink { [weak self] data in
                self?.application.handleNavigationData(data)
            }
            .store(in: &cancellables)
    }
    
    private func getPermission() throws -> NotificationPermission {
        let repo = UserDefaultsPermissionRepository()
        return repo.load()
    }
}
