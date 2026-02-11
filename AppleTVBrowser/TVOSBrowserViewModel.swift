//
//  TVOSBrowserViewModel.swift
//  AppleTVBrowser
//
//  ViewModel for tvOS Browser functionality
//

import Foundation
import SwiftUI
import Combine

@MainActor
class TVOSBrowserViewModel: ObservableObject {
    @Published var currentURL: String = "https://www.google.com"
    @Published var pageTitle: String = ""
    @Published var isLoading: Bool = false
    @Published var canGoBack: Bool = false {
        didSet {
            canGoBackPublisher.send(canGoBack)
        }
    }
    @Published var canGoForward: Bool = false {
        didSet {
            canGoForwardPublisher.send(canGoForward)
        }
    }
    
    private var canGoBackPublisher = PassthroughSubject<Bool, Never>()
    private var canGoForwardPublisher = PassthroughSubject<Bool, Never>()
    private var cancellables = Set<AnyCancellable>()
    @Published var showInstructions: Bool = false
    
    // User preferences
    @AppStorage("homepage") private var homepage: String = "https://www.google.com"
    @AppStorage("showNavigationBar") private var showNavigationBar: Bool = true
    @AppStorage("textSize") private var textSize: Int = 100
    @AppStorage("mobileMode") private var mobileMode: Bool = false
    
    // History and Bookmarks
    var history: [HistoryItem] = []
    var bookmarks: [BookmarkItem] = []
    
    init() {
        loadUserDefaults()
        
        canGoBackPublisher
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] value in
                self?.canGoBack = value
            }
            .store(in: &cancellables)
        
        canGoForwardPublisher
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] value in
                self?.canGoForward = value
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Navigation Functions
    func loadURL(_ urlString: String) {
        var processedURL = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Handle search vs URL
        if processedURL.contains(" ") || !processedURL.contains(".") {
            // Treat as search query
            let encodedQuery = processedURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            processedURL = "https://www.google.com/search?q=\(encodedQuery)"
        } else if !processedURL.hasPrefix("http://") && !processedURL.hasPrefix("https://") {
            processedURL = "https://" + processedURL
        }
        
        currentURL = processedURL
        addToHistory(url: processedURL, title: "Loading...")
    }
    
    func goBack() {
        // Will be handled by the UIWebView
    }
    
    func goForward() {
        // Will be handled by the UIWebView
    }
    
    func reload() {
        // Force reload by updating URL
        let url = currentURL
        currentURL = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.currentURL = url
        }
    }
    
    func loadHomePage() {
        loadURL(homepage)
    }
    
    func setCurrentPageAsHomePage() {
        homepage = currentURL
    }
    
    // MARK: - User Interface
    func showInstructionsTemporarily() {
        if !UserDefaults.standard.bool(forKey: "hasShownInstructions") {
            showInstructions = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self.showInstructions = false
            }
            
            UserDefaults.standard.set(true, forKey: "hasShownInstructions")
        }
    }
    
    func toggleNavigationBar() {
        showNavigationBar.toggle()
    }
    
    func toggleMobileMode() {
        mobileMode.toggle()
        // This would require reloading the web view with new user agent
    }
    
    // MARK: - Text Size Control
    func increaseTextSize() {
        textSize = min(200, textSize + 10)
    }
    
    func decreaseTextSize() {
        textSize = max(50, textSize - 10)
    }
    
    // MARK: - History Management
    func addToHistory(url: String, title: String) {
        let historyItem = HistoryItem(
            url: url,
            title: title,
            timestamp: Date()
        )
        
        // Remove duplicate if exists
        history.removeAll { $0.url == url }
        
        // Add to beginning
        history.insert(historyItem, at: 0)
        
        // Keep only last 100 items
        if history.count > 100 {
            history.removeLast(history.count - 100)
        }
        
        saveHistory()
    }
    
    func clearHistory() {
        history.removeAll()
        saveHistory()
    }
    
    // MARK: - Bookmark Management
    func addBookmark(url: String, title: String) {
        let bookmark = BookmarkItem(
            url: url,
            title: title.isEmpty ? url : title,
            timestamp: Date()
        )
        
        // Check if already bookmarked
        if !bookmarks.contains(where: { $0.url == url }) {
            bookmarks.append(bookmark)
            saveBookmarks()
        }
    }
    
    func removeBookmark(_ bookmark: BookmarkItem) {
        bookmarks.removeAll { $0.id == bookmark.id }
        saveBookmarks()
    }
    
    func isBookmarked(url: String) -> Bool {
        return bookmarks.contains { $0.url == url }
    }
    
    // MARK: - Cache Management
    func clearCache() {
        URLCache.shared.removeAllCachedResponses()
    }
    
    func clearCookies() {
        HTTPCookieStorage.shared.cookies?.forEach { cookie in
            HTTPCookieStorage.shared.deleteCookie(cookie)
        }
    }
    
    // MARK: - User Defaults
    private func loadUserDefaults() {
        // Load history
        if let historyData = UserDefaults.standard.data(forKey: "browserHistory"),
           let decodedHistory = try? JSONDecoder().decode([HistoryItem].self, from: historyData) {
            history = decodedHistory
        }
        
        // Load bookmarks
        if let bookmarksData = UserDefaults.standard.data(forKey: "browserBookmarks"),
           let decodedBookmarks = try? JSONDecoder().decode([BookmarkItem].self, from: bookmarksData) {
            bookmarks = decodedBookmarks
        }
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: "browserHistory")
        }
    }
    
    private func saveBookmarks() {
        if let encoded = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(encoded, forKey: "browserBookmarks")
        }
    }
    
    // MARK: - Error Handling
    func handleLoadError(_ error: Error) {
        print("Browser load error: \(error.localizedDescription)")
        // Could show error UI or retry logic here
    }
}

// MARK: - Data Models
struct HistoryItem: Identifiable, Codable {
    var id: UUID
    let url: String
    let title: String
    let timestamp: Date
    
    init(url: String, title: String, timestamp: Date) {
        self.id = UUID()
        self.url = url
        self.title = title
        self.timestamp = timestamp
    }
}

struct BookmarkItem: Identifiable, Codable {
    var id: UUID
    let url: String
    let title: String
    let timestamp: Date
    
    init(url: String, title: String, timestamp: Date) {
        self.id = UUID()
        self.url = url
        self.title = title
        self.timestamp = timestamp
    }
}
