//
//  SearchResult.swift
//  AppleTVBrowser
//

import Foundation

/// Repräsentiert ein einzelnes Suchergebnis aus der Google-Suche.
/// Sendable für Thread-sichere Übergabe zwischen Actor-Kontexten.
struct SearchResult: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let title: String
    let url: String
    let description: String
    
    var displayURL: String {
        Self.extractDisplayURL(from: url)
    }
    
    // MARK: - Initialization
    init(title: String, url: String, description: String) {
        self.id = UUID()
        self.title = title
        self.url = url
        self.description = description
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case url
        case description
        case displayURL
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // ID ist optional beim Dekodieren (für JavaScript-Parsing)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.title = try container.decode(String.self, forKey: .title)
        self.url = try container.decode(String.self, forKey: .url)
        self.description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        
        // displayURL is now computed and does not need to be decoded.
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(url, forKey: .url)
        try container.encode(description, forKey: .description)
        try container.encode(displayURL, forKey: .displayURL)
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
