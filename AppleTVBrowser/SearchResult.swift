//
//  SearchResult.swift
//  AppleTVBrowser
//

import Foundation

/// Content-Type für Suchergebnisse
enum SearchContentType: String, Codable, CaseIterable, Sendable {
    case web = "web"
    case image = "image"
    case video = "video"
    case info = "info"
    
    var displayName: String {
        switch self {
        case .web: return "Alle"
        case .image: return "Bilder"
        case .video: return "Videos"
        case .info: return "Info"
        }
    }
    
    var iconName: String {
        switch self {
        case .web: return "globe"
        case .image: return "photo.on.rectangle"
        case .video: return "video"
        case .info: return "book.closed"
        }
    }
}

/// Repräsentiert ein einzelnes Suchergebnis aus verschiedenen Suchquellen.
/// Sendable für Thread-sichere Übergabe zwischen Actor-Kontexten.
struct SearchResult: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let title: String
    let url: String
    let description: String
    let contentType: SearchContentType
    
    // Zusätzliche Metadaten für Bilder und Videos
    let thumbnailURL: String?
    let imageWidth: Int?
    let imageHeight: Int?
    let duration: String?  // Format: "HH:MM:SS" oder "MM:SS"
    let source: String?    // z.B. "YouTube", "Vimeo", "Flickr"
    
    var displayURL: String {
        Self.extractDisplayURL(from: url)
    }
    
    var aspectRatio: CGFloat {
        guard let width = imageWidth, let height = imageHeight, width > 0, height > 0 else {
            return contentType == .video ? 16.0/9.0 : 1.0
        }
        return CGFloat(width) / CGFloat(height)
    }
    
    // MARK: - Initialization
    
    /// Standard Web-Suchergebnis
    init(title: String, url: String, description: String) {
        self.id = UUID()
        self.title = title
        self.url = url
        self.description = description
        self.contentType = .web
        self.thumbnailURL = nil
        self.imageWidth = nil
        self.imageHeight = nil
        self.duration = nil
        self.source = nil
    }
    
    /// Erweiterte Initialisierung für alle Content-Typen
    init(
        title: String,
        url: String,
        description: String,
        contentType: SearchContentType,
        thumbnailURL: String? = nil,
        imageWidth: Int? = nil,
        imageHeight: Int? = nil,
        duration: String? = nil,
        source: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.url = url
        self.description = description
        self.contentType = contentType
        self.thumbnailURL = thumbnailURL
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.duration = duration
        self.source = source
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case url
        case description
        case contentType
        case thumbnailURL
        case imageWidth
        case imageHeight
        case duration
        case source
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.title = try container.decode(String.self, forKey: .title)
        self.url = try container.decode(String.self, forKey: .url)
        self.description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        self.contentType = try container.decodeIfPresent(SearchContentType.self, forKey: .contentType) ?? .web
        self.thumbnailURL = try container.decodeIfPresent(String.self, forKey: .thumbnailURL)
        self.imageWidth = try container.decodeIfPresent(Int.self, forKey: .imageWidth)
        self.imageHeight = try container.decodeIfPresent(Int.self, forKey: .imageHeight)
        self.duration = try container.decodeIfPresent(String.self, forKey: .duration)
        self.source = try container.decodeIfPresent(String.self, forKey: .source)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(url, forKey: .url)
        try container.encode(description, forKey: .description)
        try container.encode(contentType, forKey: .contentType)
        try container.encodeIfPresent(thumbnailURL, forKey: .thumbnailURL)
        try container.encodeIfPresent(imageWidth, forKey: .imageWidth)
        try container.encodeIfPresent(imageHeight, forKey: .imageHeight)
        try container.encodeIfPresent(duration, forKey: .duration)
        try container.encodeIfPresent(source, forKey: .source)
    }
    
    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(url)
    }
    
    static func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
        lhs.id == rhs.id && lhs.url == rhs.url
    }
    
    // MARK: - Helper
    private static func extractDisplayURL(from urlString: String) -> String {
        guard let url = URL(string: urlString) else {
            return urlString
        }
        
        // Entferne www. Präfix für kürzere Anzeige
        var host = url.host ?? urlString
        if host.hasPrefix("www.") {
            host = String(host.dropFirst(4))
        }
        
        return host
    }
}

// MARK: - Search Result Extensions
extension SearchResult {
    /// Erstellt ein Beispiel-Suchergebnis für Previews und Tests.
    static var example: SearchResult {
        SearchResult(
            title: "Beispiel Webseite - Interessante Inhalte",
            url: "https://www.example.com/page",
            description: "Dies ist eine Beispiel-Beschreibung für ein Suchergebnis. Sie enthält einen kurzen Überblick über den Inhalt der Seite."
        )
    }
    
    /// Erstellt mehrere Beispiel-Suchergebnisse für Previews.
    static var examples: [SearchResult] {
        [
            SearchResult(
                title: "Apple - Offizielle Website",
                url: "https://www.apple.com",
                description: "Entdecke die innovative Welt von Apple. Kaufe iPhone, iPad, Apple Watch, Mac und Apple TV und finde Zubehör."
            ),
            SearchResult(
                title: "Wikipedia",
                url: "https://de.wikipedia.org",
                description: "Die freie Enzyklopädie mit über 2 Millionen Artikeln in deutscher Sprache."
            ),
            SearchResult(
                title: "GitHub - Where the world builds software",
                url: "https://github.com",
                description: "GitHub is where over 100 million developers shape the future of software, together."
            )
        ]
    }
}
