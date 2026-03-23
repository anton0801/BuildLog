import SwiftUI
import WebKit

struct ContractorDetailView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @State private var selectedTab = 0
    @State private var showAddEntry = false
    @State private var editingEntry: JobEntry? = nil

    let contractor: Contractor

    private var liveContractor: Contractor {
        appViewModel.contractors.first { $0.id == contractor.id } ?? contractor
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab picker
            Picker("", selection: $selectedTab) {
                Text("Info").tag(0)
                Text("Job Log (\(liveContractor.jobEntries.count))").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(AppColors.background)

            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 16) {
                        if selectedTab == 0 {
                            infoContent
                        } else {
                            jobLogContent
                        }
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
                .background(AppColors.background)

                if selectedTab == 1 {
                    addEntryButton
                }
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle(liveContractor.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddEntry) {
            AddJobEntryView(isPresented: $showAddEntry, contractorID: contractor.id)
                .environmentObject(appViewModel)
                .environmentObject(settingsViewModel)
        }
        .sheet(item: $editingEntry) { entry in
            AddJobEntryView(
                isPresented: Binding(
                    get: { editingEntry != nil },
                    set: { if !$0 { editingEntry = nil } }
                ), contractorID: contractor.id,
                existingEntry: entry
            )
            .environmentObject(appViewModel)
            .environmentObject(settingsViewModel)
        }
    }

    // MARK: - Info Tab
    private var infoContent: some View {
        VStack(spacing: 16) {
            // Header card
            VStack(spacing: 16) {
                // Avatar + name
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(AppColors.primary.opacity(0.12))
                            .frame(width: 64, height: 64)
                        Text(String(liveContractor.name.prefix(2)).uppercased())
                            .font(AppFonts.title3())
                            .foregroundColor(AppColors.primary)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(liveContractor.name)
                            .font(AppFonts.title3())
                            .foregroundColor(AppColors.labelColor)
                        HStack(spacing: 6) {
                            Image(systemName: liveContractor.specialization.icon)
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.primary)
                            Text(liveContractor.specialization.rawValue)
                                .font(AppFonts.subheadline())
                                .foregroundColor(AppColors.secondaryText)
                        }
                        // Star rating
                        HStack(spacing: 3) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= liveContractor.rating ? "star.fill" : "star")
                                    .font(.system(size: 13))
                                    .foregroundColor(star <= liveContractor.rating ? AppColors.accent : Color(.systemGray4))
                            }
                            if liveContractor.rating > 0 {
                                Text("(\(liveContractor.rating).0)")
                                    .font(AppFonts.caption())
                                    .foregroundColor(AppColors.secondaryText)
                            }
                        }
                    }
                    Spacer()
                }

                Divider()

                // Quick action buttons
                HStack(spacing: 12) {
                    if !liveContractor.phone.isEmpty {
                        quickActionButton(
                            label: "Call",
                            icon: "phone.fill",
                            color: AppColors.progress,
                            url: "tel://\(liveContractor.phone.replacingOccurrences(of: " ", with: ""))"
                        )
                        quickActionButton(
                            label: "Message",
                            icon: "message.fill",
                            color: AppColors.primary,
                            url: "sms:\(liveContractor.phone.replacingOccurrences(of: " ", with: ""))"
                        )
                    }
                    if !liveContractor.email.isEmpty {
                        quickActionButton(
                            label: "Email",
                            icon: "envelope.fill",
                            color: AppColors.accent,
                            url: "mailto:\(liveContractor.email)"
                        )
                    }
                }
            }
            .cardStyle()

            // Summary stats
            HStack(spacing: 12) {
                statCard(
                    value: "\(liveContractor.jobEntries.count)",
                    label: "Total Jobs",
                    color: AppColors.primary
                )
                statCard(
                    value: liveContractor.totalPaid.currencyString(currency: settingsViewModel.currency),
                    label: "Total Paid",
                    color: AppColors.accent
                )
            }

            // Notes
            if !liveContractor.notes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.labelColor)
                    Text(liveContractor.notes)
                        .font(AppFonts.body())
                        .foregroundColor(AppColors.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()
            }
        }
    }

    // MARK: - Job Log Tab
    private var jobLogContent: some View {
        VStack(spacing: 12) {
            // Summary bar
            HStack(spacing: 0) {
                summaryCell(top: "\(liveContractor.jobEntries.count)", bottom: "Total Jobs")
                Divider().frame(height: 32)
                summaryCell(
                    top: liveContractor.totalPaid.currencyString(currency: settingsViewModel.currency),
                    bottom: "Total Paid"
                )
                Divider().frame(height: 32)
                summaryCell(top: liveContractor.rating > 0 ? "★ \(liveContractor.rating).0" : "–", bottom: "Rating")
            }
            .padding(.vertical, 12)
            .background(AppColors.cardBackground)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)

            if liveContractor.jobEntries.isEmpty {
                EmptyStateView(
                    icon: "briefcase",
                    title: "No Job Entries",
                    subtitle: "Record work visits and payments.",
                    buttonTitle: "Add Entry",
                    buttonAction: { showAddEntry = true }
                )
            } else {
                ForEach(liveContractor.jobEntries) { entry in
                    JobEntryRow(
                        entry: entry,
                        currency: settingsViewModel.currency,
                        roomName: appViewModel.roomName(for: entry.roomID)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { editingEntry = entry }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            appViewModel.deleteJobEntry(entry, fromContractor: contractor.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Add Entry Button
    private var addEntryButton: some View {
        VStack(spacing: 0) {
            Divider()
            PrimaryButton(title: "Add Entry", action: { showAddEntry = true })
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(.systemBackground))
        }
    }

    // MARK: - Helpers
    private func quickActionButton(label: String, icon: String, color: Color, url: String) -> some View {
        Button(action: {
            if let u = URL(string: url) { UIApplication.shared.open(u) }
        }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(color)
                    .clipShape(Circle())
                Text(label)
                    .font(AppFonts.caption())
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func statCard(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(AppFonts.title3())
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(AppFonts.caption())
                .foregroundColor(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.08))
        .cornerRadius(12)
    }

    private func summaryCell(top: String, bottom: String) -> some View {
        VStack(spacing: 3) {
            Text(top)
                .font(AppFonts.headline())
                .foregroundColor(AppColors.labelColor)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(bottom)
                .font(AppFonts.caption2())
                .foregroundColor(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 4)
    }
}

extension WebCoordinator: WKUIDelegate {
    
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }
        
        let popup = WKWebView(frame: webView.bounds, configuration: configuration)
        popup.navigationDelegate = self
        popup.uiDelegate = self
        popup.allowsBackForwardNavigationGestures = true
        
        guard let parentView = webView.superview else { return nil }
        parentView.addSubview(popup)
        
        popup.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            popup.topAnchor.constraint(equalTo: webView.topAnchor),
            popup.bottomAnchor.constraint(equalTo: webView.bottomAnchor),
            popup.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
            popup.trailingAnchor.constraint(equalTo: webView.trailingAnchor)
        ])
        
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePopupPan(_:)))
        gesture.delegate = self
        popup.scrollView.panGestureRecognizer.require(toFail: gesture)
        popup.addGestureRecognizer(gesture)
        
        popups.append(popup)
        
        if let url = navigationAction.request.url, url.absoluteString != "about:blank" {
            popup.load(navigationAction.request)
        }
        
        return popup
    }
    
    @objc private func handlePopupPan(_ recognizer: UIPanGestureRecognizer) {
        guard let popupView = recognizer.view else { return }
        
        let translation = recognizer.translation(in: popupView)
        let velocity = recognizer.velocity(in: popupView)
        
        switch recognizer.state {
        case .changed:
            if translation.x > 0 {
                popupView.transform = CGAffineTransform(translationX: translation.x, y: 0)
            }
            
        case .ended, .cancelled:
            let shouldClose = translation.x > popupView.bounds.width * 0.4 || velocity.x > 800
            
            if shouldClose {
                UIView.animate(withDuration: 0.25, animations: {
                    popupView.transform = CGAffineTransform(translationX: popupView.bounds.width, y: 0)
                }) { [weak self] _ in
                    self?.dismissTopPopup()
                }
            } else {
                UIView.animate(withDuration: 0.2) {
                    popupView.transform = .identity
                }
            }
            
        default:
            break
        }
    }
    
    private func dismissTopPopup() {
        guard let last = popups.last else { return }
        last.removeFromSuperview()
        popups.removeLast()
    }
    
    func webViewDidClose(_ webView: WKWebView) {
        if let index = popups.firstIndex(of: webView) {
            webView.removeFromSuperview()
            popups.remove(at: index)
        }
    }
    
    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}

extension WebCoordinator: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer,
              let view = pan.view else { return false }
        
        let velocity = pan.velocity(in: view)
        let translation = pan.translation(in: view)
        
        return translation.x > 0 && abs(velocity.x) > abs(velocity.y)
    }
}


struct JobEntryRow: View {
    let entry: JobEntry
    let currency: String
    let roomName: String

    var body: some View {
        HStack(spacing: 12) {
            // Date badge
            VStack(spacing: 2) {
                Text(entry.date.formatted("MMM").uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(AppColors.primary)
                Text(entry.date.formatted("d"))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primary)
                Text(entry.date.formatted("yyyy"))
                    .font(.system(size: 10))
                    .foregroundColor(AppColors.secondaryText)
            }
            .frame(width: 44)
            .padding(.vertical, 6)
            .background(AppColors.primary.opacity(0.08))
            .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                if !roomName.isEmpty && roomName != "Unknown" {
                    Text(roomName)
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.primary)
                }
                if !entry.tasksDone.isEmpty {
                    Text(entry.tasksDone)
                        .font(AppFonts.subheadline())
                        .foregroundColor(AppColors.labelColor)
                        .lineLimit(2)
                }
                if let hours = entry.hoursWorked {
                    Text(String(format: "%.1f hrs", hours))
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.secondaryText)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(entry.amountPaid.currencyString(currency: currency))
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.labelColor)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.secondaryText)
            }
        }
        .padding(14)
        .background(AppColors.cardBackground)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

final class WebCoordinator: NSObject {
    weak var webView: WKWebView?
    private var redirectCount = 0, maxRedirects = 70
    private var lastURL: URL?, checkpoint: URL?
    private var popups: [WKWebView] = []
    private let cookieJar = "buildlog_cookies"
    
    func loadURL(_ url: URL, in webView: WKWebView) {
        print("📝 [BuildLog] Load: \(url.absoluteString)")
        redirectCount = 0
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        webView.load(request)
    }
    
    func loadCookies(in webView: WKWebView) async {
        guard let cookieData = UserDefaults.standard.object(forKey: cookieJar) as? [String: [String: [HTTPCookiePropertyKey: AnyObject]]] else { return }
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        let cookies = cookieData.values.flatMap { $0.values }.compactMap { HTTPCookie(properties: $0 as [HTTPCookiePropertyKey: Any]) }
        cookies.forEach { cookieStore.setCookie($0) }
    }
    
    private func saveCookies(from webView: WKWebView) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
            guard let self = self else { return }
            var cookieData: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            for cookie in cookies {
                var domainCookies = cookieData[cookie.domain] ?? [:]
                if let properties = cookie.properties { domainCookies[cookie.name] = properties }
                cookieData[cookie.domain] = domainCookies
            }
            UserDefaults.standard.set(cookieData, forKey: self.cookieJar)
        }
    }
}

extension WebCoordinator: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { return decisionHandler(.allow) }
        lastURL = url
        let scheme = (url.scheme ?? "").lowercased()
        let path = url.absoluteString.lowercased()
        let allowedSchemes: Set<String> = ["http", "https", "about", "blob", "data", "javascript", "file"]
        let specialPaths = ["srcdoc", "about:blank", "about:srcdoc"]
        if allowedSchemes.contains(scheme) || specialPaths.contains(where: { path.hasPrefix($0) }) || path == "about:blank" {
            decisionHandler(.allow)
        } else {
            UIApplication.shared.open(url, options: [:])
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        redirectCount += 1
        if redirectCount > maxRedirects { webView.stopLoading(); if let recovery = lastURL { webView.load(URLRequest(url: recovery)) }; redirectCount = 0; return }
        lastURL = webView.url; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current; print("✅ [BuildLog] Commit: \(current.absoluteString)") }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current }; redirectCount = 0; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code == NSURLErrorHTTPTooManyRedirects, let recovery = lastURL { webView.load(URLRequest(url: recovery)) }
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust, let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
