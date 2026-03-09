//
//  LocalizedStrings.swift
//  MountainBrowser
//
//  Zentrale Lokalisierungs-Strings für die gesamte App
//

import Foundation

// MARK: - Lokalisierte Strings
// Verwendung: L10n.Settings.title → "Einstellungen" / "Settings" / etc.

enum L10n {
    
    // MARK: - Allgemein
    enum General {
        static let back = String(localized: "general.back", defaultValue: "Back")
        static let cancel = String(localized: "general.cancel", defaultValue: "Cancel")
        static let ok = String(localized: "general.ok", defaultValue: "OK")
        static let close = String(localized: "general.close", defaultValue: "Close")
        static let retry = String(localized: "general.retry", defaultValue: "Try Again")
        static let loading = String(localized: "general.loading", defaultValue: "Loading...")
        static let error = String(localized: "general.error", defaultValue: "Error")
        static let newTab = String(localized: "general.newTab", defaultValue: "New Tab")
        static let search = String(localized: "general.search", defaultValue: "Search")
        static let tabs = String(localized: "general.tabs", defaultValue: "Tabs")
        static let selected = String(localized: "general.selected", defaultValue: "Selected")
        static let active = String(localized: "general.active", defaultValue: "Active")
        static let web = String(localized: "general.web", defaultValue: "Web")
    }
    
    // MARK: - Startseite
    enum Home {
        static let welcome = String(localized: "home.welcome", defaultValue: "Welcome")
        static let enterSearchOrURL = String(localized: "home.enterSearchOrURL", defaultValue: "Enter a search term or URL")
        static let enterURL = String(localized: "home.enterURL", defaultValue: "Enter URL")
        static let openGoogle = String(localized: "home.openGoogle", defaultValue: "Open Google")
        static let recentSearches = String(localized: "home.recentSearches", defaultValue: "Recent Searches")
        static let settings = String(localized: "home.settings", defaultValue: "Settings")
        static let configureBrowser = String(localized: "home.configureBrowser", defaultValue: "Configure browser")
        static let urlOrSearchPromptTitle = String(localized: "home.urlOrSearchPromptTitle", defaultValue: "Enter URL or search term")
        static let urlOrSearchPromptMessage = String(localized: "home.urlOrSearchPromptMessage", defaultValue: "Enter a URL (e.g. google.com) or a search term")
        static let openWebsite = String(localized: "home.openWebsite", defaultValue: "Open Website")
        static let googleSearch = String(localized: "home.googleSearch", defaultValue: "Google Search")
        static let directURL = String(localized: "home.directURL", defaultValue: "Direct URL")
        static let startPageAccessibility = String(localized: "home.startPageAccessibility", defaultValue: "Start page. Enter a search term or URL.")
    }
    
    // MARK: - Suche
    enum Search {
        static let searching = String(localized: "search.searching", defaultValue: "Searching...")
        static let searchAccessibility = String(localized: "search.searchAccessibility", defaultValue: "Search is running")
        static let searchError = String(localized: "search.searchError", defaultValue: "Search Error")
        static let noResults = String(localized: "search.noResults", defaultValue: "No Results")
        static let searchTabs = String(localized: "search.searchTabs", defaultValue: "Search Tabs")
        static let info = String(localized: "search.info", defaultValue: "Info")
        /// Dynamischer Such-Präfix
        static func searchPrefix(_ query: String) -> String {
            let base = String(localized: "search.searchPrefix", defaultValue: "Search")
            return "\(base): \(query)"
        }
        /// Dynamischer keine-Ergebnisse-Präfix
        static func noResultsPrefix(_ query: String) -> String {
            let base = String(localized: "search.noResultsPrefix", defaultValue: "No results")
            return "\(base): \(query)"
        }
        /// Dynamisches Bildlabel
        static func imageLabel(_ query: String, _ index: Int) -> String {
            return "\(query) - Image \(index)"
        }
        /// Dynamische Bildbeschreibung
        static func imageDescription(_ query: String) -> String {
            return "Image for '\(query)'"
        }
        static let web = String(localized: "search.web", defaultValue: "Web")
        static let images = String(localized: "search.images", defaultValue: "Images")
        static let videos = String(localized: "search.videos", defaultValue: "Videos")
    }
    
    // MARK: - Einstellungen
    enum Settings {
        static let title = String(localized: "settings.title", defaultValue: "Settings")
        static let subtitle = String(localized: "settings.subtitle", defaultValue: "Configure browser")
        static let webSettings = String(localized: "settings.webSettings", defaultValue: "WEB SETTINGS")
        static let actions = String(localized: "settings.actions", defaultValue: "ACTIONS")
        
        static let javaScript = String(localized: "settings.javaScript", defaultValue: "JavaScript")
        static let javaScriptSubtitle = String(localized: "settings.javaScriptSubtitle", defaultValue: "Enable interactive web content")
        static let cookies = String(localized: "settings.cookies", defaultValue: "Cookies")
        static let cookiesSubtitle = String(localized: "settings.cookiesSubtitle", defaultValue: "Save website settings")
        static let popupBlocker = String(localized: "settings.popupBlocker", defaultValue: "Pop-up Blocker")
        static let popupBlockerSubtitle = String(localized: "settings.popupBlockerSubtitle", defaultValue: "Block unwanted windows")
        static let navigation = String(localized: "settings.navigation", defaultValue: "Navigation")
        static let navigationSubtitle = String(localized: "settings.navigationSubtitle", defaultValue: "Show URL bar and controls")
        
        static let reset = String(localized: "settings.reset", defaultValue: "Reset")
        static let resetSubtitle = String(localized: "settings.resetSubtitle", defaultValue: "Reset all settings to default")
        static let aboutApp = String(localized: "settings.aboutApp", defaultValue: "About This App")
        static let aboutAppSubtitle = String(localized: "settings.aboutAppSubtitle", defaultValue: "Info, version & credits")
    }
    
    // MARK: - Über die App
    enum About {
        static let features = String(localized: "about.features", defaultValue: "FEATURES")
        static let technicalDetails = String(localized: "about.technicalDetails", defaultValue: "TECHNICAL DETAILS")
        static let legal = String(localized: "about.legal", defaultValue: "LEGAL")
        static let developedForAppleTV = String(localized: "about.developedForAppleTV", defaultValue: "Developed for Apple TV")
        
        // Features
        static let readerMode = String(localized: "about.readerMode", defaultValue: "Reader Mode")
        static let readerModeDesc = String(localized: "about.readerModeDesc", defaultValue: "Display web pages as readable native text")
        static let webSearch = String(localized: "about.webSearch", defaultValue: "Web Search")
        static let webSearchDesc = String(localized: "about.webSearchDesc", defaultValue: "Search the internet with integrated results")
        static let wikipedia = String(localized: "about.wikipedia", defaultValue: "Wikipedia")
        static let wikipediaDesc = String(localized: "about.wikipediaDesc", defaultValue: "Integrated Wikipedia info for your search")
        static let tabManagement = String(localized: "about.tabManagement", defaultValue: "Tab Management")
        static let tabManagementDesc = String(localized: "about.tabManagementDesc", defaultValue: "Open and manage multiple tabs simultaneously")
        static let imagesAndVideos = String(localized: "about.imagesAndVideos", defaultValue: "Images & Videos")
        static let imagesAndVideosDesc = String(localized: "about.imagesAndVideosDesc", defaultValue: "Image and video results in separate tabs")
        static let linkNavigation = String(localized: "about.linkNavigation", defaultValue: "Link Navigation")
        static let linkNavigationDesc = String(localized: "about.linkNavigationDesc", defaultValue: "Navigate through links directly in Reader view")
        
        // Technical
        static let platform = String(localized: "about.platform", defaultValue: "Platform")
        static let framework = String(localized: "about.framework", defaultValue: "Framework")
        static let minimumTvOS = String(localized: "about.minimumTvOS", defaultValue: "Minimum tvOS")
        static let rendering = String(localized: "about.rendering", defaultValue: "Rendering")
        static let nativeSwiftUI = String(localized: "about.nativeSwiftUI", defaultValue: "Native SwiftUI")
        static let dataStorage = String(localized: "about.dataStorage", defaultValue: "Data Storage")
        static let dataStorageValue = String(localized: "about.dataStorageValue", defaultValue: "SwiftData (local)")
        static let cloudSync = String(localized: "about.cloudSync", defaultValue: "Cloud Sync")
        static let disabled = String(localized: "about.disabled", defaultValue: "Disabled")
        
        // Legal
        static let legalText1 = String(localized: "about.legalText1", defaultValue: "This app is an independent project and is not affiliated with Apple Inc. Apple, Apple TV, tvOS, and Safari are registered trademarks of Apple Inc.")
        static let legalText2 = String(localized: "about.legalText2", defaultValue: "Search results are provided through external APIs. Wikipedia content is subject to the Creative Commons License (CC BY-SA 3.0).")
        static let copyright = String(localized: "about.copyright", defaultValue: "© 2025 Mountain Browser")
    }
    
    // MARK: - Reader
    enum Reader {
        static let pageLoading = String(localized: "reader.pageLoading", defaultValue: "Loading page...")
        static let pageLoadFailed = String(localized: "reader.pageLoadFailed", defaultValue: "Page could not be loaded")
        static let linksOnPage = String(localized: "reader.linksOnPage", defaultValue: "Links on this page")
        static let reader = String(localized: "reader.reader", defaultValue: "Reader")
        static let webpage = String(localized: "reader.webpage", defaultValue: "Web page")
        static let pageNotAvailable = String(localized: "reader.pageNotAvailable", defaultValue: "Page not available")
        static let pageCouldNotBeLoaded = String(localized: "reader.pageCouldNotBeLoaded", defaultValue: "This page could not be loaded.")
    }
    
    // MARK: - Browser Navigation
    enum Browser {
        static let scrollMode = String(localized: "browser.scrollMode", defaultValue: "Scroll Mode")
        static let cursor = String(localized: "browser.cursor", defaultValue: "Cursor")
        static let scroll = String(localized: "browser.scroll", defaultValue: "Scroll")
        static let loadingPage = String(localized: "browser.loadingPage", defaultValue: "Loading...")
        static let webViewNotAvailable = String(localized: "browser.webViewNotAvailable", defaultValue: "⚠️ UIWebView not available\n\nThis tvOS version may not support WebView rendering.")
        static let enterText = String(localized: "browser.enterText", defaultValue: "Enter text")
        static let enterTextAndPressOK = String(localized: "browser.enterTextAndPressOK", defaultValue: "Enter your text and press OK")
    }
    
    // MARK: - Video Player
    enum Video {
        static let videoLoading = String(localized: "video.videoLoading", defaultValue: "Loading video...")
        static let videoCannotPlay = String(localized: "video.videoCannotPlay", defaultValue: "Video cannot be played")
        static let videoNotDirectlyPlayable = String(localized: "video.videoNotDirectlyPlayable", defaultValue: "This video cannot be played directly.\n\nOpen it in the browser to watch it.")
        /// Dynamische Video-Player-Beschreibung
        static func videoPlayerAccessibility(_ title: String) -> String {
            return "Video player: \(title)"
        }
    }
    
    // MARK: - Tabs
    enum Tabs {
        static let tab = String(localized: "tabs.tab", defaultValue: "Tab")
        static let tabs = String(localized: "tabs.tabs", defaultValue: "Tabs")
        static let empty = String(localized: "tabs.empty", defaultValue: "Empty")
        static let searchTab = String(localized: "tabs.searchTab", defaultValue: "Search")
        static let justNow = String(localized: "tabs.justNow", defaultValue: "Just now")
        static let noResults = String(localized: "tabs.noResults", defaultValue: "No Results")
        static let noTabsOpen = String(localized: "tabs.noTabsOpen", defaultValue: "No tabs open")
        static let createNewTabToStart = String(localized: "tabs.createNewTabToStart", defaultValue: "Create a new tab to get started")
        /// Dynamische Tab-Zähler-Anzeige
        static func tabCountOf(_ count: Int, _ max: Int) -> String {
            let base = String(localized: "tabs.tabCountOf", defaultValue: "\(count) of \(max) Tabs")
            return base
        }
        /// Dynamische Zeitangaben
        static func minutesAgo(_ minutes: Int) -> String {
            let base = String(localized: "tabs.minutesAgo", defaultValue: "\(minutes) min ago")
            return base
        }
        static func hoursAgo(_ hours: Int) -> String {
            let base = String(localized: "tabs.hoursAgo", defaultValue: "\(hours) hrs ago")
            return base
        }
        static func daysAgo(_ days: Int) -> String {
            let base = String(localized: "tabs.daysAgo", defaultValue: "\(days) days ago")
            return base
        }
    }
    
    // MARK: - View Modes
    enum ViewMode {
        static let title = String(localized: "viewMode.title", defaultValue: "VIEW MODE")
        static let selection = String(localized: "viewMode.selection", defaultValue: "Navigation Mode")
        static let scrollView = String(localized: "viewMode.scrollView", defaultValue: "Scroll View")
        static let cursorView = String(localized: "viewMode.cursorView", defaultValue: "Cursor View")
        static let scrollViewDesc = String(localized: "viewMode.scrollViewDesc", defaultValue: "Standard navigation with focus and scroll")
        static let cursorViewDesc = String(localized: "viewMode.cursorViewDesc", defaultValue: "Mouse cursor navigation with touchpad")
    }
    
    // MARK: - Network
    enum Network {
        static let connectionRestored = String(localized: "network.connectionRestored", defaultValue: "Connection restored")
        static let connectedVia = String(localized: "network.connectedVia", defaultValue: "Connected via")
        static let notConnected = String(localized: "network.notConnected", defaultValue: "Not connected")
        static let retryConnection = String(localized: "network.retryConnection", defaultValue: "Try again")
        static let noInternetConnection = String(localized: "network.noInternetConnection", defaultValue: "No Internet Connection")
        static let checkNetworkConnection = String(localized: "network.checkNetworkConnection", defaultValue: "Check your network connection in settings")
        static let checkNetworkAndRetry = String(localized: "network.checkNetworkAndRetry", defaultValue: "Please check your network connection and try again.")
        static let networkSettings = String(localized: "network.networkSettings", defaultValue: "Network Settings")
        // Connection Types
        static let wlan = String(localized: "network.wlan", defaultValue: "Wi-Fi")
        static let ethernet = String(localized: "network.ethernet", defaultValue: "Ethernet")
        static let cellular = String(localized: "network.cellular", defaultValue: "Cellular")
        static let unknown = String(localized: "network.unknown", defaultValue: "Unknown")
        /// Dynamic connection text
        static func connectedViaType(_ type: String) -> String {
            let base = String(localized: "network.connectedViaPrefix", defaultValue: "Connected via")
            return "\(base) \(type)"
        }
    }
    
    // MARK: - Cursor
    enum Cursor {
        static let up = String(localized: "cursor.up", defaultValue: "Up")
        static let down = String(localized: "cursor.down", defaultValue: "Down")
        static let left = String(localized: "cursor.left", defaultValue: "Left")
        static let right = String(localized: "cursor.right", defaultValue: "Right")
    }
    
    // MARK: - Wikipedia
    enum Wikipedia {
        static let languageSystem = String(localized: "wikipedia.languageSystem", defaultValue: "System (automatic)")
        static let languageSelection = String(localized: "wikipedia.languageSelection", defaultValue: "Wikipedia Language")
        static let languageSelectionSubtitle = String(localized: "wikipedia.languageSelectionSubtitle", defaultValue: "Language for Wikipedia articles")
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
        // Sprachnamen für Infobox (nonisolated für Actor-Zugriff)
        nonisolated(unsafe) static let languageNameGerman = String(localized: "wikipedia.languageName.german", defaultValue: "Deutsch")
        nonisolated(unsafe) static let languageNameEnglish = String(localized: "wikipedia.languageName.english", defaultValue: "Englisch")
        nonisolated(unsafe) static let languageNameFrench = String(localized: "wikipedia.languageName.french", defaultValue: "Französisch")
        nonisolated(unsafe) static let languageNameSpanish = String(localized: "wikipedia.languageName.spanish", defaultValue: "Spanisch")
        nonisolated(unsafe) static let languageNameItalian = String(localized: "wikipedia.languageName.italian", defaultValue: "Italienisch")
        // Fehlermeldungen (nonisolated für Actor-Zugriff)
        nonisolated(unsafe) static let errorInvalidURL = String(localized: "wikipedia.error.invalidURL", defaultValue: "Ungültige Wikipedia-URL")
        nonisolated(unsafe) static let errorNoResults = String(localized: "wikipedia.error.noResults", defaultValue: "Keine Wikipedia-Artikel gefunden")
        nonisolated(unsafe) static let errorNetwork = String(localized: "wikipedia.error.network", defaultValue: "Netzwerkfehler")
        nonisolated(unsafe) static let errorParsing = String(localized: "wikipedia.error.parsing", defaultValue: "Fehler beim Verarbeiten der Wikipedia-Daten")
        nonisolated(unsafe) static let errorArticleNotFound = String(localized: "wikipedia.error.articleNotFound", defaultValue: "Wikipedia-Artikel nicht gefunden")
    }
    
    // MARK: - Premium
    enum Premium {
        static let premium = String(localized: "premium.premium", defaultValue: "Premium")
        static let cursorMode = String(localized: "premium.cursorMode", defaultValue: "Cursor Mode")
        static let imageSearch = String(localized: "premium.imageSearch", defaultValue: "Image Search")
        static let cursorModeDesc = String(localized: "premium.cursorModeDesc", defaultValue: "Navigate freely on websites with a cursor. Click on links, buttons, and forms.")
        static let imageSearchDesc = String(localized: "premium.imageSearchDesc", defaultValue: "Search the web for images without limits. View all results in full screen.")
        static let generalDesc = String(localized: "premium.generalDesc", defaultValue: "Unlock all premium features and use the browser without limits.")
        static let unlockPremium = String(localized: "premium.unlockPremium", defaultValue: "Unlock Premium")
        static let subscribe = String(localized: "premium.subscribe", defaultValue: "Subscribe")
        static let popular = String(localized: "premium.popular", defaultValue: "POPULAR")
        static let perMonth = String(localized: "premium.perMonth", defaultValue: "per month")
        static let perYear = String(localized: "premium.perYear", defaultValue: "per year")
        static let restorePurchases = String(localized: "premium.restorePurchases", defaultValue: "Restore Purchases")
        static let allUpdates = String(localized: "premium.allUpdates", defaultValue: "All Updates")
        static let allUpdatesDesc = String(localized: "premium.allUpdatesDesc", defaultValue: "Future features included")
        static let cursorModeShort = String(localized: "premium.cursorModeShort", defaultValue: "Click links & navigate")
        static let imageSearchShort = String(localized: "premium.imageSearchShort", defaultValue: "Unlimited image search")
        static let processingPurchase = String(localized: "premium.processingPurchase", defaultValue: "Processing purchase...")
        
        // Status
        static let statusActive = String(localized: "premium.statusActive", defaultValue: "Premium Active")
        static let statusFree = String(localized: "premium.statusFree", defaultValue: "Free Version")
        static let manageSubscription = String(localized: "premium.manageSubscription", defaultValue: "Manage Subscription")
        static let manageSubscriptionSubtitle = String(localized: "premium.manageSubscriptionSubtitle", defaultValue: "View or cancel your subscription")
        
        // Paywall
        static let premiumRequired = String(localized: "premium.premiumRequired", defaultValue: "Premium Required")
        static let cursorModePremiumOnly = String(localized: "premium.cursorModePremiumOnly", defaultValue: "Cursor Mode is only available with Premium.")
        static let imageSearchLimit = String(localized: "premium.imageSearchLimit", defaultValue: "Image search limit reached")
        static let unlockAllImages = String(localized: "premium.unlockAllImages", defaultValue: "Unlock all images")
        static let freePreviewLimit = String(localized: "premium.freePreviewLimit", defaultValue: "Free preview limit")
        static func remainingSearches(_ count: Int) -> String {
            return "\(count) " + String(localized: "premium.remainingSearchesSuffix", defaultValue: "free searches remaining today")
        }
        static func moreImagesAvailable(_ count: Int) -> String {
            return "\(count) " + String(localized: "premium.moreImagesAvailableSuffix", defaultValue: "more images available with Premium")
        }
        
        // Errors
        static let errorLoadingProducts = String(localized: "premium.errorLoadingProducts", defaultValue: "Could not load products.")
        static let retryLoading = String(localized: "premium.retryLoading", defaultValue: "Retry")
        static let purchasePending = String(localized: "premium.purchasePending", defaultValue: "Purchase is being reviewed...")
        static let purchaseFailed = String(localized: "premium.purchaseFailed", defaultValue: "Purchase failed")
        static let restoreFailed = String(localized: "premium.restoreFailed", defaultValue: "Restore failed.")
        static let verificationFailed = String(localized: "premium.verificationFailed", defaultValue: "Transaction could not be verified.")
        
        // Settings
        static let settingsTitle = String(localized: "premium.settingsTitle", defaultValue: "PREMIUM")
        static let settingsSubtitle = String(localized: "premium.settingsSubtitle", defaultValue: "Subscription & Features")
        
        // Premium Theme
        static let premiumTheme = String(localized: "premium.theme", defaultValue: "Premium Theme")
        static let premiumThemeSubtitle = String(localized: "premium.themeSubtitle", defaultValue: "Warmes, angenehmes Farbschema")
        static let upgradeToPremium = String(localized: "premium.upgradeToPremium", defaultValue: "Upgrade to Premium")
        static let upgradeToPremiumSubtitle = String(localized: "premium.upgradeToPremiumSubtitle", defaultValue: "Unlock all features")
        static let tryItFree = String(localized: "premium.tryItFree", defaultValue: "Try It Free")
        static let annualPlan = String(localized: "premium.annualPlan", defaultValue: "Annual Plan")
        
        // Subscription Type
        static let subscriptionMonthly = String(localized: "premium.subscriptionMonthly", defaultValue: "Monthly Subscription")
        static let subscriptionYearly = String(localized: "premium.subscriptionYearly", defaultValue: "Yearly Subscription")
        static let monthlyShort = String(localized: "premium.monthlyShort", defaultValue: "Monthly")
        static let yearlyShort = String(localized: "premium.yearlyShort", defaultValue: "Yearly")
        static let renewsOn = String(localized: "premium.renewsOn", defaultValue: "Renews on")
        static let currentPlan = String(localized: "premium.currentPlan", defaultValue: "Current Plan")
        static let changePlan = String(localized: "premium.changePlan", defaultValue: "Change Plan")
        static let changePlanSubtitle = String(localized: "premium.changePlanSubtitle", defaultValue: "Switch between monthly and yearly")
        static let cancelSubscription = String(localized: "premium.cancelSubscription", defaultValue: "Cancel Subscription")
        static let cancelSubscriptionSubtitle = String(localized: "premium.cancelSubscriptionSubtitle", defaultValue: "Manage in App Store settings")
        static let activeUntil = String(localized: "premium.activeUntil", defaultValue: "Active until")
        static let monthlyPlan = String(localized: "premium.monthlyPlan", defaultValue: "Monthly Plan")
        static let bestValue = String(localized: "premium.bestValue", defaultValue: "Best Value")
        static let everythingIncluded = String(localized: "premium.everythingIncluded", defaultValue: "Everything included in Premium")
        
        // Manage View
        static let yourSubscription = String(localized: "premium.yourSubscription", defaultValue: "Your Subscription")
        static let subscriptionDetails = String(localized: "premium.subscriptionDetails", defaultValue: "SUBSCRIPTION DETAILS")
        static let plan = String(localized: "premium.plan", defaultValue: "Plan")
        static let status = String(localized: "premium.status", defaultValue: "Status")
        static let price = String(localized: "premium.price", defaultValue: "Price")
        static let nextRenewal = String(localized: "premium.nextRenewal", defaultValue: "Next Renewal")
        static let includedFeatures = String(localized: "premium.includedFeatures", defaultValue: "INCLUDED FEATURES")
        static let cursorModeFeature = String(localized: "premium.cursorModeFeature", defaultValue: "Cursor Mode")
        static let cursorModeFeatureDesc = String(localized: "premium.cursorModeFeatureDesc", defaultValue: "Navigate freely on any website with a virtual cursor. Click links, buttons, and interact with forms.")
        static let unlimitedImageSearch = String(localized: "premium.unlimitedImageSearch", defaultValue: "Unlimited Image Search")
        static let unlimitedImageSearchDesc = String(localized: "premium.unlimitedImageSearchDesc", defaultValue: "Search for images without daily limits. View all results in full screen quality.")
        static let allFutureUpdates = String(localized: "premium.allFutureUpdates", defaultValue: "All Future Updates")
        static let allFutureUpdatesDesc = String(localized: "premium.allFutureUpdatesDesc", defaultValue: "Get access to all new premium features as they are released.")
        static let manageInAppStore = String(localized: "premium.manageInAppStore", defaultValue: "Manage in App Store")
        static let manageInAppStoreSubtitle = String(localized: "premium.manageInAppStoreSubtitle", defaultValue: "Change plan or cancel via Apple TV Settings")
        static let thankYou = String(localized: "premium.thankYou", defaultValue: "Thank you for your support!")
        static let thankYouSubtitle = String(localized: "premium.thankYouSubtitle", defaultValue: "You have full access to all premium features.")
    }
    
    // MARK: - URL Input
    enum URLInput {
        static let openWebsite = String(localized: "urlInput.openWebsite", defaultValue: "Open website")
        static let startGoogleSearch = String(localized: "urlInput.startGoogleSearch", defaultValue: "Start Google search")
        static let enterText = String(localized: "urlInput.enterText", defaultValue: "Enter text")
    }
    
    // MARK: - Tab Actions
    enum TabActions {
        static let closeAll = String(localized: "tabActions.closeAll", defaultValue: "Close all")
        static let closeAllTabs = String(localized: "tabActions.closeAllTabs", defaultValue: "Close all tabs?")
    }
    
    // MARK: - Suggestions
    enum Suggestions {
        static let otherSearchTerms = String(localized: "suggestions.otherSearchTerms", defaultValue: "Other search terms")
        static let switchTab = String(localized: "suggestions.switchTab", defaultValue: "Switch tab")
    }
    
    // MARK: - Validation Errors
    enum Validation {
        static let invalidURL = String(localized: "validation.invalidURL", defaultValue: "Invalid URL")
        static let unsafeProtocol = String(localized: "validation.unsafeProtocol", defaultValue: "Unsafe protocol. Only HTTP and HTTPS are allowed.")
        static let maliciousContent = String(localized: "validation.maliciousContent", defaultValue: "Potentially dangerous content detected")
        static let blacklistedDomain = String(localized: "validation.blacklistedDomain", defaultValue: "This domain is blocked")
        static let privateIP = String(localized: "validation.privateIP", defaultValue: "Private IP addresses are not allowed")
        static let localhost = String(localized: "validation.localhost", defaultValue: "Localhost URLs are not allowed")
        static let rateLimited = String(localized: "validation.rateLimited", defaultValue: "Too many validation requests")
    }
    
    // MARK: - Results Summary
    enum Results {
        static let noResults = String(localized: "results.noResults", defaultValue: "No results")
        static func webCount(_ count: Int) -> String {
            return "\(count) Web"
        }
        static func imageCount(_ count: Int) -> String {
            let base = String(localized: "results.images", defaultValue: "Images")
            return "\(count) \(base)"
        }
        static func videoCount(_ count: Int) -> String {
            return "\(count) Videos"
        }
    }
}
