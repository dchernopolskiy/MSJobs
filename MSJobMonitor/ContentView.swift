// MicrosoftJobMonitor.swift

import SwiftUI
import UserNotifications
import AppKit

// MARK: - Main App
@main
struct MicrosoftJobMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var jobManager = JobManager.shared
    @AppStorage("isFirstLaunch") private var isFirstLaunch = true
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(jobManager)
                .onAppear {
                    if isFirstLaunch {
                        jobManager.showSettings = true
                        isFirstLaunch = false
                    }
                }
                .handlesExternalEvents(preferring: ["job"], allowing: ["job"])
                .onOpenURL { url in
                    // Handle notification clicks
                    if let jobId = url.absoluteString.components(separatedBy: "://").last {
                        jobManager.selectJob(withId: jobId)
                    }
                }
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Microsoft Job Monitor") {
                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            .applicationName: "Microsoft Job Monitor",
                            .applicationVersion: "1.0.0"
                        ]
                    )
                }
            }
        }
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    var statusItem: NSStatusItem?
    var popover = NSPopover()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBar()
        requestNotificationPermission()
        
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Start monitoring jobs
        Task {
            await JobManager.shared.startMonitoring()
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Keep app running when window is closed
    }
    
    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "briefcase.fill", accessibilityDescription: "Job Monitor")
            button.action = #selector(togglePopover)
        }
    }
    
    @objc func togglePopover() {
        if let window = NSApplication.shared.windows.first {
            window.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                print("Notification permission granted")
            }
        }
    }
    
    // Handle notification clicks
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if let jobId = userInfo["jobId"] as? String {
            // Open app and show job detail
            NSApplication.shared.activate(ignoringOtherApps: true)
            if let window = NSApplication.shared.windows.first {
                window.makeKeyAndOrderFront(nil)
            }
            
            DispatchQueue.main.async {
                JobManager.shared.selectJob(withId: jobId)
            }
        }
        completionHandler()
    }
}

// MARK: - Models
struct Job: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let location: String
    let postingDate: Date
    let url: String
    let description: String
    let workSiteFlexibility: String?
    
    var isToday: Bool {
        Calendar.current.isDateInToday(postingDate)
    }
    
    var cleanDescription: String {
        // Remove HTML tags and decode entities
        let withoutTags = description
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")
        
        // Clean up extra whitespace
        return withoutTags
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Job Manager
@MainActor
class JobManager: ObservableObject {
    static let shared = JobManager()
    
    @Published var jobs: [Job] = []
    @Published var isLoading = false
    @Published var showSettings = false
    @Published var lastError: String?
    @Published var selectedJob: Job?
    @Published var selectedTab = "jobs"
    
    @AppStorage("jobTitleFilter") var jobTitleFilter = ""
    @AppStorage("locationFilter") var locationFilter = ""
    @AppStorage("refreshInterval") var refreshInterval = 30.0 // minutes
    
    private var timer: Timer?
    private var storedJobIds: Set<String> = []
    
    private init() {
        loadStoredJobIds()
        loadJobs()
    }
    
    func selectJob(withId id: String) {
        if let job = jobs.first(where: { $0.id == id }) {
            selectedJob = job
            selectedTab = "jobs"
        }
    }
    
    func startMonitoring() async {
        await fetchJobs()
        
        // Setup timer for periodic fetching
        await MainActor.run {
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: refreshInterval * 60, repeats: true) { _ in
                Task {
                    await self.fetchJobs()
                }
            }
        }
    }
    
    func fetchJobs() async {
        isLoading = true
        lastError = nil
        
        do {
            let fetcher = MicrosoftJobFetcher()
            let fetchedJobs = try await fetcher.fetchJobs(
                titleKeywords: jobTitleFilter.isEmpty ? [] : [jobTitleFilter],
                location: locationFilter
            )
            
            // Filter for today's jobs only
            let todayJobs = fetchedJobs.filter { $0.isToday }
            
            // Check for new jobs
            var newJobs: [Job] = []
            for job in todayJobs {
                if !storedJobIds.contains(job.id) {
                    newJobs.append(job)
                    storedJobIds.insert(job.id)
                }
            }
            
            // Send grouped notification if there are new jobs
            if !newJobs.isEmpty {
                sendGroupedNotification(for: newJobs)
            }
            
            jobs = todayJobs.sorted { $0.postingDate > $1.postingDate }
            saveJobs()
            saveStoredJobIds()
            
        } catch {
            lastError = error.localizedDescription
            print("Error fetching jobs: \(error)")
        }
        
        isLoading = false
    }
    
    private func sendGroupedNotification(for newJobs: [Job]) {
        if newJobs.count == 1 {
            // Single job notification
            let job = newJobs[0]
            let content = UNMutableNotificationContent()
            content.title = "New Job Posted"
            content.subtitle = job.title
            content.body = job.location
            content.sound = .default
            content.userInfo = ["jobId": job.id]
            
            let request = UNNotificationRequest(
                identifier: job.id,
                content: content,
                trigger: nil
            )
            
            UNUserNotificationCenter.current().add(request)
        } else {
            // Multiple jobs - grouped notification
            let content = UNMutableNotificationContent()
            content.title = "\(newJobs.count) New Jobs Posted"
            content.subtitle = "Microsoft Careers"
            
            let jobTitles = newJobs.prefix(3).map { "• \($0.title)" }.joined(separator: "\n")
            let moreText = newJobs.count > 3 ? "\n...and \(newJobs.count - 3) more" : ""
            content.body = jobTitles + moreText
            
            content.sound = .default
            content.userInfo = ["jobId": newJobs[0].id] // Open first job when clicked
            
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )
            
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    func openJob(_ job: Job) {
        if let url = URL(string: job.url) {
            NSWorkspace.shared.open(url)
        }
    }
    
    // MARK: - Persistence
    private var jobsURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MicrosoftJobMonitor")
            .appendingPathComponent("jobs.json")
    }
    
    private var storedIdsURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MicrosoftJobMonitor")
            .appendingPathComponent("storedIds.json")
    }
    
    private func saveJobs() {
        do {
            let data = try JSONEncoder().encode(jobs)
            try FileManager.default.createDirectory(at: jobsURL.deletingLastPathComponent(),
                                                   withIntermediateDirectories: true)
            try data.write(to: jobsURL)
        } catch {
            print("Failed to save jobs: \(error)")
        }
    }
    
    private func loadJobs() {
        do {
            let data = try Data(contentsOf: jobsURL)
            jobs = try JSONDecoder().decode([Job].self, from: data)
        } catch {
            print("Failed to load jobs: \(error)")
        }
    }
    
    private func saveStoredJobIds() {
        do {
            let data = try JSONEncoder().encode(Array(storedJobIds))
            try data.write(to: storedIdsURL)
        } catch {
            print("Failed to save stored IDs: \(error)")
        }
    }
    
    private func loadStoredJobIds() {
        do {
            let data = try Data(contentsOf: storedIdsURL)
            let ids = try JSONDecoder().decode([String].self, from: data)
            storedJobIds = Set(ids)
        } catch {
            print("Failed to load stored IDs: \(error)")
        }
    }
}

// MARK: - Job Fetcher
actor MicrosoftJobFetcher {
    private let baseURL = "https://gcsservices.careers.microsoft.com/search/api/v1/search"
    
    func fetchJobs(titleKeywords: [String], location: String) async throws -> [Job] {
        var components = URLComponents(string: baseURL)!
        
        var queryValue = titleKeywords.joined(separator: " ")
        if !location.isEmpty {
            queryValue += " \(location)"
        }
        
        components.queryItems = [
            URLQueryItem(name: "l", value: "en_us"),
            URLQueryItem(name: "pg", value: "1"),
            URLQueryItem(name: "pgSz", value: "100"),
            URLQueryItem(name: "o", value: "Relevance"),
            URLQueryItem(name: "flt", value: "true"),
            URLQueryItem(name: "q", value: queryValue)
        ]
        
        var request = URLRequest(url: components.url!)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw FetchError.invalidResponse
        }
        
        return try parseResponse(data)
    }
    
    private func parseResponse(_ data: Data) throws -> [Job] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let response = try decoder.decode(MSResponse.self, from: data)
        
        return response.operationResult.result.jobs.map { msJob in
            // Build location string properly
            var locationComponents: [String] = []
            
            if let city = msJob.properties?.location?.city, !city.isEmpty {
                locationComponents.append(city)
            }
            if let state = msJob.properties?.location?.state, !state.isEmpty {
                locationComponents.append(state)
            }
            if let country = msJob.properties?.location?.country, !country.isEmpty {
                locationComponents.append(country)
            }
            
            // Check for remote/hybrid
            let workSiteFlexibility = msJob.properties?.workSiteFlexibility ?? ""
            let isRemote = workSiteFlexibility.lowercased().contains("work from home") ||
                          workSiteFlexibility.lowercased().contains("100%")
            let isHybrid = workSiteFlexibility.lowercased().contains("50%") ||
                          workSiteFlexibility.lowercased().contains("hybrid")
            
            var location = locationComponents.joined(separator: ", ")
            if location.isEmpty || isRemote {
                location = "Remote"
            } else if isHybrid {
                location = "\(location) (Hybrid)"
            }
            
            return Job(
                id: "microsoft-\(msJob.jobId)",
                title: msJob.title,
                location: location,
                postingDate: parseDate(msJob.postingDate) ?? Date(),
                url: "https://careers.microsoft.com/us/en/job/\(msJob.jobId)",
                description: msJob.properties?.description ?? "",
                workSiteFlexibility: workSiteFlexibility
            )
        }
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: dateString)
    }
}

// MARK: - API Response Models
struct MSResponse: Codable {
    let operationResult: OperationResult
}

struct OperationResult: Codable {
    let result: SearchResult
}

struct SearchResult: Codable {
    let jobs: [MSJob]
}

struct MSJob: Codable {
    let jobId: String
    let title: String
    let postingDate: String
    let properties: Properties?
}

struct Properties: Codable {
    let description: String?
    let location: Location?
    let workSiteFlexibility: String?
}

struct Location: Codable {
    let city: String?
    let state: String?
    let country: String?
}

enum FetchError: LocalizedError {
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Failed to fetch jobs from Microsoft"
        }
    }
}

// MARK: - Views
struct ContentView: View {
    @EnvironmentObject var jobManager: JobManager
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            VStack(spacing: 20) {
                Image(systemName: "briefcase.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor)
                
                VStack(spacing: 10) {
                    SidebarButton(
                        title: "Jobs",
                        icon: "list.bullet",
                        isSelected: jobManager.selectedTab == "jobs"
                    ) {
                        jobManager.selectedTab = "jobs"
                        jobManager.selectedJob = nil
                    }
                    
                    SidebarButton(
                        title: "Settings",
                        icon: "gear",
                        isSelected: jobManager.selectedTab == "settings"
                    ) {
                        jobManager.selectedTab = "settings"
                        jobManager.selectedJob = nil
                    }
                }
                
                Spacer()
                
                if jobManager.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                
                Text("\(jobManager.jobs.count) jobs today")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(width: 200)
        } detail: {
            // Main content
            if jobManager.selectedTab == "jobs" {
                if let selectedJob = jobManager.selectedJob {
                    JobDetailView(job: selectedJob)
                } else {
                    JobListView()
                }
            } else {
                SettingsView()
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .navigationTitle("Microsoft Job Monitor")
    }
}

struct SidebarButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 20)
                Text(title)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct JobListView: View {
    @EnvironmentObject var jobManager: JobManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Today's Jobs")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    Task {
                        await jobManager.fetchJobs()
                    }
                }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(jobManager.isLoading)
            }
            .padding()
            
            Divider()
            
            // Jobs list
            if jobManager.jobs.isEmpty && !jobManager.isLoading {
                VStack {
                    Spacer()
                    Image(systemName: "tray")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No jobs posted today")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Text("Check your filters in Settings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(jobManager.jobs) { job in
                            JobRow(job: job)
                            Divider()
                        }
                    }
                }
            }
            
            // Error message
            if let error = jobManager.lastError {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
            }
        }
    }
}

struct JobRow: View {
    let job: Job
    @State private var isHovered = false
    @EnvironmentObject var jobManager: JobManager
    
    var body: some View {
        Button(action: {
            jobManager.selectedJob = job
        }) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "briefcase")
                    .font(.title3)
                    .foregroundColor(.accentColor)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(job.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack {
                        Label(job.location, systemImage: "location")
                        Spacer()
                        Text(job.postingDate, style: .time)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    if !job.cleanDescription.isEmpty {
                        Text(job.cleanDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .opacity(isHovered ? 1 : 0.5)
            }
            .padding()
            .background(isHovered ? Color.gray.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct JobDetailView: View {
    let job: Job
    @EnvironmentObject var jobManager: JobManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with back button
                HStack {
                    Button(action: {
                        jobManager.selectedJob = nil
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back to Jobs")
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Button(action: {
                        jobManager.openJob(job)
                    }) {
                        Label("Open in Browser", systemImage: "arrow.up.right.square")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                
                Divider()
                
                // Job details
                VStack(alignment: .leading, spacing: 16) {
                    // Title
                    Text(job.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    // Location and time
                    HStack(spacing: 20) {
                        Label(job.location, systemImage: "location")
                            .font(.title3)
                        
                        Label {
                            Text(job.postingDate, style: .relative)
                        } icon: {
                            Image(systemName: "clock")
                        }
                        .font(.title3)
                    }
                    .foregroundColor(.secondary)
                    
                    if let flexibility = job.workSiteFlexibility, !flexibility.isEmpty {
                        Label(flexibility, systemImage: "house.laptop")
                            .font(.callout)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Divider()
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Job Description")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(job.cleanDescription)
                            .font(.body)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer(minLength: 40)
                    
                    // Action button
                    HStack {
                        Spacer()
                        Button(action: {
                            jobManager.openJob(job)
                        }) {
                            Text("Apply on Microsoft Careers")
                                .font(.headline)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        Spacer()
                    }
                }
                .padding()
            }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var jobManager: JobManager
    @State private var titleFilter = ""
    @State private var locationFilter = ""
    @State private var refreshInterval = 30.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Settings")
                .font(.title2)
                .fontWeight(.semibold)
            
            Divider()
            
            Form {
                Section("Job Filters") {
                    TextField("Job Title", text: $titleFilter)
                        .textFieldStyle(.roundedBorder)
                        .help("Enter keywords to filter job titles (e.g., 'Software Engineer')")
                    
                    TextField("Location", text: $locationFilter)
                        .textFieldStyle(.roundedBorder)
                        .help("Enter location to filter jobs (e.g., 'Seattle' or 'Remote')")
                }
                
                Section("Refresh Settings") {
                    HStack {
                        Text("Check for new jobs every")
                        TextField("", value: $refreshInterval, format: .number)
                            .frame(width: 60)
                            .textFieldStyle(.roundedBorder)
                        Text("minutes")
                    }
                }
                
                Section {
                    HStack {
                        Button("Save Settings") {
                            saveSettings()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Save and Refresh Now") {
                            saveSettings()
                            Task {
                                await jobManager.fetchJobs()
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
            .formStyle(.grouped)
            
            Spacer()
        }
        .padding()
        .onAppear {
            titleFilter = jobManager.jobTitleFilter
            locationFilter = jobManager.locationFilter
            refreshInterval = jobManager.refreshInterval
        }
    }
    
    private func saveSettings() {
        jobManager.jobTitleFilter = titleFilter
        jobManager.locationFilter = locationFilter
        jobManager.refreshInterval = refreshInterval
        
        Task {
            await jobManager.startMonitoring()
        }
    }
}
