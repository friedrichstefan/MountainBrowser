//
//  BrowserPreferences.swift
//  AppleTVBrowser
//
//  Session-Management und Browser-Präferenzen
//

import Foundation
import SwiftData

/// Browser-Ansichtsmodus
enum BrowserViewMode: String, Codable, CaseIterable {
    case scrollView = "scroll"    // Standard Fokus-basierte Navigation
    case cursorView = "cursor"    // Maus-Cursor basierte Navigation
    
    var displayName: String {
        switch self {
        case .scrollView:
            return "Scroll View"
        case .cursorView:
            return "Cursor View"
        }
    }
    
    var description: String {
        switch self {
        case .scrollView:
            return "Standard-Navigation mit Fokus und Scroll"
        case .cursorView:
            return "Maus-Cursor Navigation mit Touchpad"
        }
    }
}

/// Browser-Einstellungen und Präferenzen
@Model
final class BrowserPreferences {
    var homepage: String
    var searchEngine: String
    var userAgent: String
    var fontSize: Int
    var enableCookies: Bool
    var enableJavaScript: Bool
    var blockPopups: Bool
    var showTopNavigation: Bool
    var defaultZoom: Float
    var viewMode: BrowserViewMode
    
    init(
        homepage: String = "https://www.google.com",
        searchEngine: String = "Google",
        userAgent: String = "Mozilla/5.0 (AppleTV; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15",
        fontSize: Int = 16,
        enableCookies: Bool = true,
        enableJavaScript: Bool = true,
        blockPopups: Bool = true,
        showTopNavigation: Bool = true,
        defaultZoom: Float = 1.0,
        viewMode: BrowserViewMode = .scrollView
    ) {
        self.homepage = homepage
        self.searchEngine = searchEngine
        self.userAgent = userAgent
        self.fontSize = fontSize
        self.enableCookies = enableCookies
        self.enableJavaScript = enableJavaScript
        self.blockPopups = blockPopups
        self.showTopNavigation = showTopNavigation
        self.defaultZoom = defaultZoom
        self.viewMode = viewMode
    }
}

/// Browser-Session für Persistierung
@Model
final class BrowserSession {
    var currentURL: String?
    var scrollPosition: Double
    var lastAccessDate: Date
    var cookies: Data?
    var preferences: BrowserPreferences?
    
    init(
        currentURL: String? = nil,
        scrollPosition: Double = 0,
        lastAccessDate: Date = Date(),
        cookies: Data? = nil,
        preferences: BrowserPreferences? = nil
    ) {
        self.currentURL = currentURL
        self.scrollPosition = scrollPosition
        self.lastAccessDate = lastAccessDate
        self.cookies = cookies
        self.preferences = preferences
    }
}

/// Session-Manager für Browser-State-Verwaltung
@Observable
final class SessionManager {
    var currentSession: BrowserSession?
    var preferences: BrowserPreferences
    
    // UserDefaults Keys
    private enum Keys {
        static let homepage = "browser.homepage"
        static let searchEngine = "browser.searchEngine"
        static let userAgent = "browser.userAgent"
        static let fontSize = "browser.fontSize"
        static let enableCookies = "browser.enableCookies"
        static let enableJavaScript = "browser.enableJavaScript"
        static let blockPopups = "browser.blockPopups"
        static let showTopNavigation = "browser.showTopNavigation"
        static let defaultZoom = "browser.defaultZoom"
        static let viewMode = "browser.viewMode"
    }
    
    init() {
        // Lade Preferences aus UserDefaults
        self.preferences = BrowserPreferences(
            homepage: UserDefaults.standard.string(forKey: Keys.homepage) ?? "https://www.google.com",
            searchEngine: UserDefaults.standard.string(forKey: Keys.searchEngine) ?? "Google",
            userAgent: UserDefaults.standard.string(forKey: Keys.userAgent) ?? "Mozilla/5.0 (AppleTV; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15",
            fontSize: UserDefaults.standard.integer(forKey: Keys.fontSize) != 0 ? UserDefaults.standard.integer(forKey: Keys.fontSize) : 16,
            enableCookies: UserDefaults.standard.object(forKey: Keys.enableCookies) as? Bool ?? true,
            enableJavaScript: UserDefaults.standard.object(forKey: Keys.enableJavaScript) as? Bool ?? true,
            blockPopups: UserDefaults.standard.object(forKey: Keys.blockPopups) as? Bool ?? true,
            showTopNavigation: UserDefaults.standard.object(forKey: Keys.showTopNavigation) as? Bool ?? true,
            defaultZoom: UserDefaults.standard.object(forKey: Keys.defaultZoom) as? Float ?? 1.0,
            viewMode: BrowserViewMode(rawValue: UserDefaults.standard.string(forKey: Keys.viewMode) ?? "scroll") ?? .scrollView
        )
    }
    
    /// Speichert aktuelle Preferences
    func savePreferences() {
        UserDefaults.standard.set(preferences.homepage, forKey: Keys.homepage)
        UserDefaults.standard.set(preferences.searchEngine, forKey: Keys.searchEngine)
        UserDefaults.standard.set(preferences.userAgent, forKey: Keys.userAgent)
        UserDefaults.standard.set(preferences.fontSize, forKey: Keys.fontSize)
        UserDefaults.standard.set(preferences.enableCookies, forKey: Keys.enableCookies)
        UserDefaults.standard.set(preferences.enableJavaScript, forKey: Keys.enableJavaScript)
        UserDefaults.standard.set(preferences.blockPopups, forKey: Keys.blockPopups)
        UserDefaults.standard.set(preferences.showTopNavigation, forKey: Keys.showTopNavigation)
        UserDefaults.standard.set(preferences.defaultZoom, forKey: Keys.defaultZoom)
        UserDefaults.standard.set(preferences.viewMode.rawValue, forKey: Keys.viewMode)
    }
    
    /// Erstellt neue Session
    func createSession(url: String?) {
        currentSession = BrowserSession(
            currentURL: url,
            preferences: preferences
        )
    }
    
    /// Updated aktuelle Session
    func updateSession(url: String?, scrollPosition: Double) {
        guard let session = currentSession else {
            createSession(url: url)
            return
        }
        
        session.currentURL = url
        session.scrollPosition = scrollPosition
        session.lastAccessDate = Date()
    }
    
    /// Speichert Cookies
    func saveCookies(_ cookies: [HTTPCookie]) {
        guard let session = currentSession else { return }
        
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: cookies, requiringSecureCoding: true)
            session.cookies = data
        } catch {
            print("Fehler beim Speichern der Cookies: \(error)")
        }
    }
    
    /// Lädt gespeicherte Cookies
    func loadCookies() -> [HTTPCookie]? {
        guard let session = currentSession,
              let data = session.cookies else { return nil }
        
        do {
            if let cookies = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, HTTPCookie.self], from: data) as? [HTTPCookie] {
                return cookies
            }
        } catch {
            print("Fehler beim Laden der Cookies: \(error)")
        }
        
        return nil
    }
    
    /// Löscht aktuelle Session
    func clearSession() {
        currentSession = nil
    }
}
