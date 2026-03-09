//
//  BrowserPreferences.swift
//  MountainBrowser
//
//  Session-Management und Browser-Präferenzen
//

import Foundation
import SwiftData
import Combine

/// Wikipedia-Sprachcode
enum WikipediaLanguage: String, Codable, CaseIterable {
    case system = "system"  // Folgt der Systemsprache
    case german = "de"
    case english = "en"
    case french = "fr"
    case spanish = "es"
    case italian = "it"
    
    var displayName: String {
        switch self {
        case .system:
            return L10n.Wikipedia.languageSystem
        case .german:
            return L10n.Wikipedia.languageNameGerman
        case .english:
            return L10n.Wikipedia.languageNameEnglish
        case .french:
            return L10n.Wikipedia.languageNameFrench
        case .spanish:
            return L10n.Wikipedia.languageNameSpanish
        case .italian:
            return L10n.Wikipedia.languageNameItalian
        }
    }
    
    /// Gibt den tatsächlichen Sprachcode zurück (bei system die Systemsprache)
    var resolvedLanguageCode: String {
        if self == .system {
            // Systemsprache ermitteln
            let preferredLanguages = Locale.preferredLanguages
            for lang in preferredLanguages {
                let code = String(lang.prefix(2))
                if ["de", "en", "fr", "es", "it"].contains(code) {
                    return code
                }
            }
            return "de" // Default
        }
        return rawValue
    }
}

/// Browser-Ansichtsmodus
enum BrowserViewMode: String, Codable, CaseIterable {
    case scrollView = "scroll"    // Standard Fokus-basierte Navigation
    case cursorView = "cursor"    // Maus-Cursor basierte Navigation
    
    var displayName: String {
        switch self {
        case .scrollView:
            return L10n.ViewMode.scrollView
        case .cursorView:
            return L10n.ViewMode.cursorView
        }
    }
    
    var description: String {
        switch self {
        case .scrollView:
            return L10n.ViewMode.scrollViewDesc
        case .cursorView:
            return L10n.ViewMode.cursorViewDesc
        }
    }
}

/// Browser-Einstellungen und Präferenzen
/// KEIN @Model — wird über UserDefaults in SessionManager verwaltet
struct BrowserPreferences {
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
    var wikipediaLanguage: WikipediaLanguage
    
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
        viewMode: BrowserViewMode = .scrollView,
        wikipediaLanguage: WikipediaLanguage = .system
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
        self.wikipediaLanguage = wikipediaLanguage
    }
}

/// Browser-Session für Persistierung
@Model
final class BrowserSession {
    var currentURL: String?
    var scrollPosition: Double
    var lastAccessDate: Date
    var cookies: Data?
    
    // Preferences als einzelne Felder statt @Model-Referenz
    var prefHomepage: String?
    var prefSearchEngine: String?
    var prefViewMode: String?
    
    init(
        currentURL: String? = nil,
        scrollPosition: Double = 0,
        lastAccessDate: Date = Date(),
        cookies: Data? = nil
    ) {
        self.currentURL = currentURL
        self.scrollPosition = scrollPosition
        self.lastAccessDate = lastAccessDate
        self.cookies = cookies
    }
}

/// Session-Manager für Browser-State-Verwaltung
import SwiftUI

final class SessionManager: ObservableObject {
    @Published var currentSession: BrowserSession?
    @Published var preferences: BrowserPreferences
    
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
        static let wikipediaLanguage = "browser.wikipediaLanguage"
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
            viewMode: BrowserViewMode(rawValue: UserDefaults.standard.string(forKey: Keys.viewMode) ?? "scroll") ?? .scrollView,
            wikipediaLanguage: WikipediaLanguage(rawValue: UserDefaults.standard.string(forKey: Keys.wikipediaLanguage) ?? "system") ?? .system
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
        UserDefaults.standard.set(preferences.wikipediaLanguage.rawValue, forKey: Keys.wikipediaLanguage)
    }
    
    /// Erstellt neue Session
    func createSession(url: String?) {
        currentSession = BrowserSession(
            currentURL: url
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
        }
        
        return nil
    }
    
    /// Löscht aktuelle Session
    func clearSession() {
        currentSession = nil
    }
}
