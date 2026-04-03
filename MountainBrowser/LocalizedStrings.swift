//
//  LocalizedStrings.swift
//  MountainBrowser
//
//  Zentrale Lokalisierungs-Strings für die gesamte App
//  Primärsprache: Deutsch (de)
//

import Foundation

// MARK: - Lokalisierte Strings
// Verwendung: L10n.Settings.title → "Einstellungen" / "Settings" / etc.

enum L10n {

    // MARK: - Allgemein
    enum General {
        static let back = String(localized: "general.back", defaultValue: "Zurück")
        static let cancel = String(localized: "general.cancel", defaultValue: "Abbrechen")
        static let ok = String(localized: "general.ok", defaultValue: "OK")
        static let close = String(localized: "general.close", defaultValue: "Schließen")
        static let retry = String(localized: "general.retry", defaultValue: "Erneut versuchen")
        static let loading = String(localized: "general.loading", defaultValue: "Laden …")
        static let error = String(localized: "general.error", defaultValue: "Fehler")
        static let newTab = String(localized: "general.newTab", defaultValue: "Neuer Tab")
        static let search = String(localized: "general.search", defaultValue: "Suche")
        static let tabs = String(localized: "general.tabs", defaultValue: "Tabs")
        static let selected = String(localized: "general.selected", defaultValue: "Ausgewählt")
        static let active = String(localized: "general.active", defaultValue: "Aktiv")
        static let web = String(localized: "general.web", defaultValue: "Web")
        static let open = String(localized: "general.open", defaultValue: "Öffnen")
    }

    // MARK: - Startseite
    enum Home {
        static let welcome = String(localized: "home.welcome", defaultValue: "Willkommen")
        static let enterSearchOrURL = String(localized: "home.enterSearchOrURL", defaultValue: "Suchbegriff oder URL eingeben")
        static let enterURL = String(localized: "home.enterURL", defaultValue: "URL eingeben")
        static let openGoogle = String(localized: "home.openGoogle", defaultValue: "Google öffnen")
        static let recentSearches = String(localized: "home.recentSearches", defaultValue: "Letzte Suchbegriffe")
        static let settings = String(localized: "home.settings", defaultValue: "Einstellungen")
        static let configureBrowser = String(localized: "home.configureBrowser", defaultValue: "Browser konfigurieren")
        static let urlOrSearchPromptTitle = String(localized: "home.urlOrSearchPromptTitle", defaultValue: "URL oder Suchbegriff eingeben")
        static let urlOrSearchPromptMessage = String(localized: "home.urlOrSearchPromptMessage", defaultValue: "Gib eine URL (z. B. google.com) oder einen Suchbegriff ein")
        static let openWebsite = String(localized: "home.openWebsite", defaultValue: "Webseite öffnen")
        static let googleSearch = String(localized: "home.googleSearch", defaultValue: "Google-Suche")
        static let directURL = String(localized: "home.directURL", defaultValue: "Direkte URL")
        static let startPageAccessibility = String(localized: "home.startPageAccessibility", defaultValue: "Startseite. Gib einen Suchbegriff oder eine URL ein.")
    }

    // MARK: - Suche
    enum Search {
        static let searching = String(localized: "search.searching", defaultValue: "Suche läuft …")
        static let searchAccessibility = String(localized: "search.searchAccessibility", defaultValue: "Suche wird ausgeführt")
        static let searchError = String(localized: "search.searchError", defaultValue: "Suchfehler")
        static let noResults = String(localized: "search.noResults", defaultValue: "Keine Ergebnisse")
        static let searchTabs = String(localized: "search.searchTabs", defaultValue: "Tabs durchsuchen")
        static let info = String(localized: "search.info", defaultValue: "Info")
        static let results = String(localized: "search.results", defaultValue: "Suchergebnisse")
        static let doubleTapToOpen = String(localized: "search.doubleTapToOpen", defaultValue: "Doppeltippen zum Öffnen")
        /// Dynamischer Such-Präfix
        static func searchPrefix(_ query: String) -> String {
            let base = String(localized: "search.searchPrefix", defaultValue: "Suche")
            return "\(base): \(query)"
        }
        /// Dynamischer keine-Ergebnisse-Präfix
        static func noResultsPrefix(_ query: String) -> String {
            let base = String(localized: "search.noResultsPrefix", defaultValue: "Keine Ergebnisse")
            return "\(base): \(query)"
        }
        /// Dynamisches Bildlabel
        static func imageLabel(_ query: String, _ index: Int) -> String {
            let base = String(localized: "search.imageLabel", defaultValue: "Bild")
            return "\(query) - \(base) \(index)"
        }
        /// Dynamische Bildbeschreibung
        static func imageDescription(_ query: String) -> String {
            let base = String(localized: "search.imageDescription", defaultValue: "Bild für")
            return "\(base) '\(query)'"
        }
        /// Dynamische Ergebnisanzahl
        static func resultsFound(_ count: Int) -> String {
            return String(localized: "search.resultsFound", defaultValue: "\(count) Ergebnisse gefunden")
        }
        static let web = String(localized: "search.web", defaultValue: "Web")
        static let images = String(localized: "search.images", defaultValue: "Bilder")
        static let videos = String(localized: "search.videos", defaultValue: "Videos")
        static let imageResults = String(localized: "search.imageResults", defaultValue: "Bildsuchergebnisse")
        static let videoResults = String(localized: "search.videoResults", defaultValue: "Videosuchergebnisse")
    }

    // MARK: - Einstellungen
    enum Settings {
        static let title = String(localized: "settings.title", defaultValue: "Einstellungen")
        static let subtitle = String(localized: "settings.subtitle", defaultValue: "Browser konfigurieren")
        static let webSettings = String(localized: "settings.webSettings", defaultValue: "WEB-EINSTELLUNGEN")
        static let actions = String(localized: "settings.actions", defaultValue: "AKTIONEN")

        static let javaScript = String(localized: "settings.javaScript", defaultValue: "JavaScript")
        static let javaScriptSubtitle = String(localized: "settings.javaScriptSubtitle", defaultValue: "Interaktive Webinhalte aktivieren")
        static let cookies = String(localized: "settings.cookies", defaultValue: "Cookies")
        static let cookiesSubtitle = String(localized: "settings.cookiesSubtitle", defaultValue: "Webseiten-Einstellungen speichern")
        static let popupBlocker = String(localized: "settings.popupBlocker", defaultValue: "Pop-up-Blocker")
        static let popupBlockerSubtitle = String(localized: "settings.popupBlockerSubtitle", defaultValue: "Unerwünschte Fenster blockieren")
        static let navigation = String(localized: "settings.navigation", defaultValue: "Navigation")
        static let navigationSubtitle = String(localized: "settings.navigationSubtitle", defaultValue: "URL-Leiste und Steuerung anzeigen")

        static let reset = String(localized: "settings.reset", defaultValue: "Zurücksetzen")
        static let resetSubtitle = String(localized: "settings.resetSubtitle", defaultValue: "Alle Einstellungen auf Standard zurücksetzen")
        static let aboutApp = String(localized: "settings.aboutApp", defaultValue: "Über diese App")
        static let aboutAppSubtitle = String(localized: "settings.aboutAppSubtitle", defaultValue: "Info, Version & Credits")
    }

    // MARK: - Über die App
    enum About {
        static let features = String(localized: "about.features", defaultValue: "FUNKTIONEN")
        static let technicalDetails = String(localized: "about.technicalDetails", defaultValue: "TECHNISCHE DETAILS")
        static let legal = String(localized: "about.legal", defaultValue: "RECHTLICHES")
        static let developedForAppleTV = String(localized: "about.developedForAppleTV", defaultValue: "Entwickelt für Apple TV")

        // Features
        static let readerMode = String(localized: "about.readerMode", defaultValue: "Lesemodus")
        static let readerModeDesc = String(localized: "about.readerModeDesc", defaultValue: "Webseiten als lesbaren nativen Text anzeigen")
        static let webSearch = String(localized: "about.webSearch", defaultValue: "Websuche")
        static let webSearchDesc = String(localized: "about.webSearchDesc", defaultValue: "Im Internet mit integrierten Ergebnissen suchen")
        static let wikipedia = String(localized: "about.wikipedia", defaultValue: "Wikipedia")
        static let wikipediaDesc = String(localized: "about.wikipediaDesc", defaultValue: "Integrierte Wikipedia-Infos zu deiner Suche")
        static let tabManagement = String(localized: "about.tabManagement", defaultValue: "Tab-Verwaltung")
        static let tabManagementDesc = String(localized: "about.tabManagementDesc", defaultValue: "Mehrere Tabs gleichzeitig öffnen und verwalten")
        static let imagesAndVideos = String(localized: "about.imagesAndVideos", defaultValue: "Bilder & Videos")
        static let imagesAndVideosDesc = String(localized: "about.imagesAndVideosDesc", defaultValue: "Bild- und Videoergebnisse in separaten Tabs")
        static let linkNavigation = String(localized: "about.linkNavigation", defaultValue: "Link-Navigation")
        static let linkNavigationDesc = String(localized: "about.linkNavigationDesc", defaultValue: "Direkt durch Links in der Leseansicht navigieren")

        // Technical
        static let platform = String(localized: "about.platform", defaultValue: "Plattform")
        static let framework = String(localized: "about.framework", defaultValue: "Framework")
        static let minimumTvOS = String(localized: "about.minimumTvOS", defaultValue: "Minimum tvOS")
        static let rendering = String(localized: "about.rendering", defaultValue: "Rendering")
        static let nativeSwiftUI = String(localized: "about.nativeSwiftUI", defaultValue: "Natives SwiftUI")
        static let dataStorage = String(localized: "about.dataStorage", defaultValue: "Datenspeicherung")
        static let dataStorageValue = String(localized: "about.dataStorageValue", defaultValue: "SwiftData (lokal)")
        static let cloudSync = String(localized: "about.cloudSync", defaultValue: "Cloud-Sync")
        static let disabled = String(localized: "about.disabled", defaultValue: "Deaktiviert")

        // Legal
        static let legalText1 = String(localized: "about.legalText1", defaultValue: "Diese App ist ein unabhängiges Projekt und steht in keiner Verbindung zu Apple Inc. Apple, Apple TV, tvOS und Safari sind eingetragene Marken von Apple Inc.")
        static let legalText2 = String(localized: "about.legalText2", defaultValue: "Suchergebnisse werden über externe APIs bereitgestellt. Wikipedia-Inhalte unterliegen der Creative-Commons-Lizenz (CC BY-SA 3.0).")
        static let copyright = String(localized: "about.copyright", defaultValue: "© 2025 Mountain Browser")
    }

    // MARK: - Reader
    enum Reader {
        static let pageLoading = String(localized: "reader.pageLoading", defaultValue: "Seite wird geladen …")
        static let pageLoadFailed = String(localized: "reader.pageLoadFailed", defaultValue: "Seite konnte nicht geladen werden")
        static let linksOnPage = String(localized: "reader.linksOnPage", defaultValue: "Links auf dieser Seite")
        static let reader = String(localized: "reader.reader", defaultValue: "Reader")
        static let webpage = String(localized: "reader.webpage", defaultValue: "Webseite")
        static let pageNotAvailable = String(localized: "reader.pageNotAvailable", defaultValue: "Seite nicht verfügbar")
        static let pageCouldNotBeLoaded = String(localized: "reader.pageCouldNotBeLoaded", defaultValue: "Diese Seite konnte nicht geladen werden.")
    }

    // MARK: - Browser Navigation
    enum Browser {
        static let scrollMode = String(localized: "browser.scrollMode", defaultValue: "Scroll-Modus")
        static let cursor = String(localized: "browser.cursor", defaultValue: "Cursor")
        static let scroll = String(localized: "browser.scroll", defaultValue: "Scroll")
        static let loadingPage = String(localized: "browser.loadingPage", defaultValue: "Laden …")
        static let webViewNotAvailable = String(localized: "browser.webViewNotAvailable", defaultValue: "⚠️ UIWebView nicht verfügbar\n\nDiese tvOS-Version unterstützt möglicherweise kein WebView-Rendering.")
        static let enterText = String(localized: "browser.enterText", defaultValue: "Text eingeben")
        static let enterTextAndPressOK = String(localized: "browser.enterTextAndPressOK", defaultValue: "Gib deinen Text ein und drücke OK")
    }

    // MARK: - Video Player
    enum Video {
        static let videoLoading = String(localized: "video.videoLoading", defaultValue: "Video wird geladen …")
        static let videoCannotPlay = String(localized: "video.videoCannotPlay", defaultValue: "Video kann nicht abgespielt werden")
        static let videoNotDirectlyPlayable = String(localized: "video.videoNotDirectlyPlayable", defaultValue: "Dieses Video kann nicht direkt abgespielt werden.\n\nÖffne es im Browser, um es anzusehen.")
        /// Dynamische Video-Player-Beschreibung
        static func videoPlayerAccessibility(_ title: String) -> String {
            let base = String(localized: "video.videoPlayerAccessibility", defaultValue: "Videoplayer")
            return "\(base): \(title)"
        }
    }

    // MARK: - Tabs
    enum Tabs {
        static let tab = String(localized: "tabs.tab", defaultValue: "Tab")
        static let tabs = String(localized: "tabs.tabs", defaultValue: "Tabs")
        static let empty = String(localized: "tabs.empty", defaultValue: "Leer")
        static let searchTab = String(localized: "tabs.searchTab", defaultValue: "Suche")
        static let justNow = String(localized: "tabs.justNow", defaultValue: "Gerade eben")
        static let noResults = String(localized: "tabs.noResults", defaultValue: "Keine Ergebnisse")
        static let noTabsOpen = String(localized: "tabs.noTabsOpen", defaultValue: "Keine Tabs geöffnet")
        static let createNewTabToStart = String(localized: "tabs.createNewTabToStart", defaultValue: "Erstelle einen neuen Tab, um loszulegen")
        /// Dynamische Tab-Zähler-Anzeige
        static func tabCountOf(_ count: Int, _ max: Int) -> String {
            return String(localized: "tabs.tabCountOf", defaultValue: "\(count) von \(max) Tabs")
        }
        /// Dynamische Zeitangaben
        static func minutesAgo(_ minutes: Int) -> String {
            return String(localized: "tabs.minutesAgo", defaultValue: "\(minutes) Min. her")
        }
        static func hoursAgo(_ hours: Int) -> String {
            return String(localized: "tabs.hoursAgo", defaultValue: "\(hours) Std. her")
        }
        static func daysAgo(_ days: Int) -> String {
            return String(localized: "tabs.daysAgo", defaultValue: "\(days) Tage her")
        }
    }

    // MARK: - View Modes
    enum ViewMode {
        static let title = String(localized: "viewMode.title", defaultValue: "ANSICHTSMODUS")
        static let selection = String(localized: "viewMode.selection", defaultValue: "Navigationsmodus")
        static let scrollView = String(localized: "viewMode.scrollView", defaultValue: "Scroll-Ansicht")
        static let cursorView = String(localized: "viewMode.cursorView", defaultValue: "Cursor-Ansicht")
        static let scrollViewDesc = String(localized: "viewMode.scrollViewDesc", defaultValue: "Standard-Navigation mit Fokus und Scrollen")
        static let cursorViewDesc = String(localized: "viewMode.cursorViewDesc", defaultValue: "Mauszeiger-Navigation mit Touchpad")
    }

    // MARK: - Network
    enum Network {
        static let connectionRestored = String(localized: "network.connectionRestored", defaultValue: "Verbindung wiederhergestellt")
        static let connectedVia = String(localized: "network.connectedVia", defaultValue: "Verbunden über")
        static let notConnected = String(localized: "network.notConnected", defaultValue: "Nicht verbunden")
        static let retryConnection = String(localized: "network.retryConnection", defaultValue: "Erneut versuchen")
        static let noInternetConnection = String(localized: "network.noInternetConnection", defaultValue: "Keine Internetverbindung")
        static let checkNetworkConnection = String(localized: "network.checkNetworkConnection", defaultValue: "Überprüfe deine Netzwerkverbindung in den Einstellungen")
        static let checkNetworkAndRetry = String(localized: "network.checkNetworkAndRetry", defaultValue: "Bitte überprüfe deine Netzwerkverbindung und versuche es erneut.")
        static let networkSettings = String(localized: "network.networkSettings", defaultValue: "Netzwerkeinstellungen")
        // Verbindungstypen
        static let wlan = String(localized: "network.wlan", defaultValue: "WLAN")
        static let ethernet = String(localized: "network.ethernet", defaultValue: "Ethernet")
        static let cellular = String(localized: "network.cellular", defaultValue: "Mobilfunk")
        static let unknown = String(localized: "network.unknown", defaultValue: "Unbekannt")
        /// Dynamischer Verbindungstext
        static func connectedViaType(_ type: String) -> String {
            let base = String(localized: "network.connectedViaPrefix", defaultValue: "Verbunden über")
            return "\(base) \(type)"
        }
    }

    // MARK: - Cursor
    enum Cursor {
        static let up = String(localized: "cursor.up", defaultValue: "Hoch")
        static let down = String(localized: "cursor.down", defaultValue: "Runter")
        static let left = String(localized: "cursor.left", defaultValue: "Links")
        static let right = String(localized: "cursor.right", defaultValue: "Rechts")
    }

    // MARK: - Wikipedia
    enum Wikipedia {
        static let languageSystem = String(localized: "wikipedia.languageSystem", defaultValue: "System (automatisch)")
        static let languageSelection = String(localized: "wikipedia.languageSelection", defaultValue: "Wikipedia-Sprache")
        static let languageSelectionSubtitle = String(localized: "wikipedia.languageSelectionSubtitle", defaultValue: "Sprache für Wikipedia-Artikel")
        static let readMore = String(localized: "wikipedia.readMore", defaultValue: "Vollständigen Artikel lesen")
        static let learnMore = String(localized: "wikipedia.learnMore", defaultValue: "Mehr erfahren")
        static let fromWikipedia = String(localized: "wikipedia.fromWikipedia", defaultValue: "Aus Wikipedia")
        static let viewFullArticle = String(localized: "wikipedia.viewFullArticle", defaultValue: "Vollständigen Artikel anzeigen")
        static let readFullArticle = String(localized: "wikipedia.readFullArticle", defaultValue: "Vollständigen Artikel lesen")
        static let readCompletely = String(localized: "wikipedia.readCompletely", defaultValue: "Vollständig lesen")
        static let information = String(localized: "wikipedia.information", defaultValue: "Information")
        static let language = String(localized: "wikipedia.language", defaultValue: "Sprache")
        static let germanWikipedia = String(localized: "wikipedia.germanWikipedia", defaultValue: "Deutsche Wikipedia")
        static let englishWikipedia = String(localized: "wikipedia.englishWikipedia", defaultValue: "Englische Wikipedia")
        static let frenchWikipedia = String(localized: "wikipedia.frenchWikipedia", defaultValue: "Französische Wikipedia")
        static let spanishWikipedia = String(localized: "wikipedia.spanishWikipedia", defaultValue: "Spanische Wikipedia")
        static let italianWikipedia = String(localized: "wikipedia.italianWikipedia", defaultValue: "Italienische Wikipedia")
        static let accessibilityHint = String(localized: "wikipedia.accessibilityHint", defaultValue: "Doppeltippen für den vollständigen Wikipedia-Artikel")
        // Sprachnamen für Infobox
        static let languageNameGerman = String(localized: "wikipedia.languageName.german", defaultValue: "Deutsch")
        static let languageNameEnglish = String(localized: "wikipedia.languageName.english", defaultValue: "Englisch")
        static let languageNameFrench = String(localized: "wikipedia.languageName.french", defaultValue: "Französisch")
        static let languageNameSpanish = String(localized: "wikipedia.languageName.spanish", defaultValue: "Spanisch")
        static let languageNameItalian = String(localized: "wikipedia.languageName.italian", defaultValue: "Italienisch")
        // Fehlermeldungen
        static let errorInvalidURL = String(localized: "wikipedia.error.invalidURL", defaultValue: "Ungültige Wikipedia-URL")
        static let errorNoResults = String(localized: "wikipedia.error.noResults", defaultValue: "Keine Wikipedia-Artikel gefunden")
        static let errorNetwork = String(localized: "wikipedia.error.network", defaultValue: "Netzwerkfehler")
        static let errorParsing = String(localized: "wikipedia.error.parsing", defaultValue: "Fehler beim Verarbeiten der Wikipedia-Daten")
        static let errorArticleNotFound = String(localized: "wikipedia.error.articleNotFound", defaultValue: "Wikipedia-Artikel nicht gefunden")
    }

    // MARK: - URL Input
    enum URLInput {
        static let openWebsite = String(localized: "urlInput.openWebsite", defaultValue: "Webseite öffnen")
        static let startGoogleSearch = String(localized: "urlInput.startGoogleSearch", defaultValue: "Google-Suche starten")
        static let enterText = String(localized: "urlInput.enterText", defaultValue: "Text eingeben")
    }

    // MARK: - Tab Actions
    enum TabActions {
        static let closeAll = String(localized: "tabActions.closeAll", defaultValue: "Alle schließen")
        static let closeAllTabs = String(localized: "tabActions.closeAllTabs", defaultValue: "Alle Tabs schließen?")
        static let closeAllMessage = String(localized: "tabActions.closeAllMessage", defaultValue: "Dadurch werden alle offenen Tabs geschlossen und ein neuer leerer Tab erstellt.")
    }

    // MARK: - Suggestions
    enum Suggestions {
        static let otherSearchTerms = String(localized: "suggestions.otherSearchTerms", defaultValue: "Andere Suchbegriffe")
        static let switchTab = String(localized: "suggestions.switchTab", defaultValue: "Tab wechseln")
    }

    // MARK: - Validation Errors
    enum Validation {
        static let invalidURL = String(localized: "validation.invalidURL", defaultValue: "Ungültige URL")
        static let unsafeProtocol = String(localized: "validation.unsafeProtocol", defaultValue: "Unsicheres Protokoll. Nur HTTP und HTTPS sind erlaubt.")
        static let maliciousContent = String(localized: "validation.maliciousContent", defaultValue: "Potenziell gefährlicher Inhalt erkannt")
        static let blacklistedDomain = String(localized: "validation.blacklistedDomain", defaultValue: "Diese Domain ist gesperrt")
        static let privateIP = String(localized: "validation.privateIP", defaultValue: "Private IP-Adressen sind nicht erlaubt")
        static let localhost = String(localized: "validation.localhost", defaultValue: "Localhost-URLs sind nicht erlaubt")
        static let rateLimited = String(localized: "validation.rateLimited", defaultValue: "Zu viele Validierungsanfragen")
    }

    // MARK: - Results Summary
    enum Results {
        static let noResults = String(localized: "results.noResults", defaultValue: "Keine Ergebnisse")
        static func webCount(_ count: Int) -> String {
            return "\(count) Web"
        }
        static func imageCount(_ count: Int) -> String {
            let base = String(localized: "results.images", defaultValue: "Bilder")
            return "\(count) \(base)"
        }
        static func videoCount(_ count: Int) -> String {
            return "\(count) Videos"
        }
    }

    // MARK: - Image Results
    enum ImageResults {
        static let noImages = String(localized: "imageResults.noImages", defaultValue: "Keine Bilder gefunden")
        static let noImagesMessage = String(localized: "imageResults.noImagesMessage", defaultValue: "Für diese Suchanfrage wurden keine Bilder gefunden.\nVersuche es mit anderen Suchbegriffen.")
        static let imageUnavailable = String(localized: "imageResults.imageUnavailable", defaultValue: "Bild nicht verfügbar")
    }

    // MARK: - Video Results
    enum VideoResults {
        static let noVideos = String(localized: "videoResults.noVideos", defaultValue: "Keine Videos gefunden")
        static let noVideosMessage = String(localized: "videoResults.noVideosMessage", defaultValue: "Für diese Suchanfrage wurden keine Videos gefunden.")
        static let noVideosTip = String(localized: "videoResults.noVideosTip", defaultValue: "Versuche es mit anderen Suchbegriffen oder wechsle zu einem anderen Tab.")
        static let videoUnavailable = String(localized: "videoResults.videoUnavailable", defaultValue: "Video nicht verfügbar")
    }

    // MARK: - Image Viewer
    enum ImageViewer {
        static let imageLoading = String(localized: "imageViewer.imageLoading", defaultValue: "Bild wird geladen …")
        static let imageLoadFailed = String(localized: "imageViewer.imageLoadFailed", defaultValue: "Bild konnte nicht geladen werden")
    }

    // MARK: - Text Preview
    enum TextPreview {
        static let disclaimer = String(localized: "textPreview.disclaimer", defaultValue: "Textansicht — Für die vollständige Webseite öffne die URL auf einem anderen Gerät.")
        static let fullWebsiteDisclaimer = String(localized: "textPreview.fullWebsiteDisclaimer", defaultValue: "Webseiten können auf Apple TV nur als Text dargestellt werden.\nÖffne die URL auf einem iPhone, iPad oder Mac für die vollständige Ansicht.")
    }
}
