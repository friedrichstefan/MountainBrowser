//
//  SearchError.swift
//  MountainBrowser
//
//  Globale Fehlertypen für Suchoperationen
//

import Foundation

/// Globale Fehlertypen für alle Such-Services
enum SearchError: LocalizedError {
    case invalidURL
    case invalidQuery
    case networkError(Error)
    case parsingError
    case noResults
    case rateLimited
    case apiKeyMissing
    case apiQuotaExceeded
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Ungültige Such-URL"
        case .invalidQuery:
            return "Ungültige Suchanfrage"
        case .networkError(let error):
            return "Netzwerkfehler: \(error.localizedDescription)"
        case .parsingError:
            return "Fehler beim Verarbeiten der Suchergebnisse"
        case .noResults:
            return "Keine Ergebnisse gefunden"
        case .rateLimited:
            return "Zu viele Anfragen. Bitte warte einen Moment."
        case .apiKeyMissing:
            return "API-Key nicht konfiguriert"
        case .apiQuotaExceeded:
            return "API-Limit erreicht. Versuche es später erneut."
        case .cancelled:
            return "Suche wurde abgebrochen"
        }
    }
}