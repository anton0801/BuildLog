import Foundation
import AppsFlyerLib

final class BuildLogApplication {
    
    // Dependencies
    private let trackingRepo: TrackingRepository
    private let navigationRepo: NavigationRepository
    private let configRepo: ConfigurationRepository
    private let permissionRepo: PermissionRepository
    private let validationService: ValidationService
    private let attributionService: AttributionService
    private let endpointService: EndpointService
    private let notificationService: NotificationService
    private let eventHandler: (DomainEvent) -> Void
    
    // State
    private var tracking = TrackingData.empty
    private var navigation = NavigationData.empty
    private var permission = NotificationPermission.initial
    private var appState = ApplicationState.initial
    
    // Control
    private var isLocked = false
    private var timeoutTask: Task<Void, Never>?
    
    init(
        trackingRepo: TrackingRepository,
        navigationRepo: NavigationRepository,
        configRepo: ConfigurationRepository,
        permissionRepo: PermissionRepository,
        validationService: ValidationService,
        attributionService: AttributionService,
        endpointService: EndpointService,
        notificationService: NotificationService,
        eventHandler: @escaping (DomainEvent) -> Void
    ) {
        self.trackingRepo = trackingRepo
        self.navigationRepo = navigationRepo
        self.configRepo = configRepo
        self.permissionRepo = permissionRepo
        self.validationService = validationService
        self.attributionService = attributionService
        self.endpointService = endpointService
        self.notificationService = notificationService
        self.eventHandler = eventHandler
    }
    
    // MARK: - Use Cases
    
    func initialize() {
        loadState()
        scheduleTimeout()
        eventHandler(.initialized)
    }
    
    func handleTrackingData(_ data: [String: Any]) {
        let converted = data.mapValues { "\($0)" }
        tracking = TrackingData(attributes: converted)
        trackingRepo.save(tracking)
        eventHandler(.trackingDataReceived(tracking))
        
        Task {
            await performValidation()
        }
    }
    
    func handleNavigationData(_ data: [String: Any]) {
        let converted = data.mapValues { "\($0)" }
        navigation = NavigationData(parameters: converted)
        navigationRepo.save(navigation)
        eventHandler(.navigationDataReceived(navigation))
    }
    
    func requestNotificationPermission() {
        notificationService.requestPermission { [weak self] granted in
            guard let self = self else { return }
            
            if granted {
                self.permission = NotificationPermission(
                    isGranted: true,
                    isDenied: false,
                    lastPromptDate: Date()
                )
                self.notificationService.registerForPushNotifications()
            } else {
                self.permission = NotificationPermission(
                    isGranted: false,
                    isDenied: true,
                    lastPromptDate: Date()
                )
            }
            
            self.permissionRepo.save(self.permission)
            self.eventHandler(.permissionStateUpdated(self.permission))
            self.eventHandler(.applicationReady)
        }
    }
    
    func deferNotificationPermission() {
        permission = NotificationPermission(
            isGranted: false,
            isDenied: false,
            lastPromptDate: Date()
        )
        permissionRepo.save(permission)
        eventHandler(.permissionStateUpdated(permission))
        eventHandler(.applicationReady)
    }
    
    func handleNetworkStatusChange(isConnected: Bool) {
        guard !isLocked else { return }
        if isConnected {
            eventHandler(.networkConnected)
        } else {
            eventHandler(.networkDisconnected)
        }
    }
    
    func handleTimeout() {
        guard !isLocked else { return }
        timeoutTask?.cancel()
        eventHandler(.timeoutOccurred)
        eventHandler(.applicationFailed)
    }
    
    // MARK: - Private Logic
    
    private func loadState() {
        tracking = trackingRepo.load()
        navigation = navigationRepo.load()
        permission = permissionRepo.load()
        
        appState = ApplicationState(
            operationMode: configRepo.loadOperationMode(),
            isFirstLaunch: configRepo.isFirstLaunch()
        )
    }
    
    private func scheduleTimeout() {
        timeoutTask = Task {
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            guard !isLocked else { return }
            await MainActor.run {
                self.handleTimeout()
            }
        }
    }
    
    private func performValidation() async {
        guard !isLocked, !tracking.isEmpty else { return }
        
        do {
            let isValid = try await validationService.validateTracking()
            
            await MainActor.run {
                eventHandler(.validationCompleted(success: isValid))
                
                if isValid {
                    Task { await executeBusinessLogic() }
                } else {
                    eventHandler(.applicationFailed)
                }
            }
        } catch {
            await MainActor.run {
                eventHandler(.validationCompleted(success: false))
                eventHandler(.applicationFailed)
            }
        }
    }
    
    private func executeBusinessLogic() async {
        guard !isLocked, !tracking.isEmpty else {
            await MainActor.run { eventHandler(.applicationFailed) }
            return
        }
        
        // Check temp_url shortcut
        if let temp = UserDefaults.standard.string(forKey: "temp_url"), !temp.isEmpty {
            await MainActor.run {
                finalizeWithEndpoint(temp)
            }
            return
        }
        
        // Organic first launch flow
        if tracking.isOrganic && appState.isFirstLaunch {
            await executeOrganicFlow()
            return
        }
        
        // Normal flow
        await fetchEndpoint()
    }
    
    private func executeOrganicFlow() async {
        // 5 second delay
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        
        guard !isLocked else { return }
        
        do {
            let deviceID = await MainActor.run {
                AppsFlyerLib.shared().getAppsFlyerUID()
            }
            
            var fetched = try await attributionService.fetchAttribution(deviceID: deviceID)
            
            // Merge navigation
            for (key, value) in navigation.parameters {
                if fetched[key] == nil {
                    fetched[key] = value
                }
            }
            
            await MainActor.run {
                let converted = fetched.mapValues { "\($0)" }
                tracking = TrackingData(attributes: converted)
                trackingRepo.save(tracking)
                eventHandler(.trackingDataReceived(tracking))
            }
            
            await fetchEndpoint()
        } catch {
            await MainActor.run {
                eventHandler(.applicationFailed)
            }
        }
    }
    
    private func fetchEndpoint() async {
        guard !isLocked else { return }
        
        do {
            let trackingDict = tracking.attributes.mapValues { $0 as Any }
            let endpointURL = try await endpointService.fetchEndpoint(tracking: trackingDict)
            
            await MainActor.run {
                finalizeWithEndpoint(endpointURL)
            }
        } catch {
            await MainActor.run {
                eventHandler(.applicationFailed)
            }
        }
    }
    
    private func finalizeWithEndpoint(_ url: String) {
        guard !isLocked else { return }
        
        timeoutTask?.cancel()
        isLocked = true
        
        let endpoint = EndpointConfiguration(url: url)
        
        configRepo.saveEndpoint(url)
        configRepo.saveOperationMode("Active")
        configRepo.markAsLaunched()
        
        appState.operationMode = "Active"
        appState.isFirstLaunch = false
        
        eventHandler(.endpointConfigured(endpoint))
        
        if permission.canPrompt {
            // Show permission prompt, then navigate
        } else {
            eventHandler(.applicationReady)
        }
    }
}
