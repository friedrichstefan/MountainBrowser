//
//  SearchError.swift
//  AppleTVBrowser
//
//  Gemeinsamer Fehler-Typ für alle Such-Services
//

import Foundation

/// Gemeinsamer Fehler-Typ für Such-Operationen
enum SearchError: LocalizedError {
    case invalidURL
    case invalidQuery
    case networkError(Error)
    case parsingError
    case noResults
    case rateLimited
    case backendError(String)
    case apiKeyMissing
    case apiQuotaExceeded
    
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
        case .backendError(let message):
            return "Backend-Fehler: \(message)"
        case .apiKeyMissing:
            return "API-Key nicht konfiguriert"
        case .apiQuotaExceeded:
            return "API-Limit erreicht. Versuche es später erneut."
        }
    }
}
