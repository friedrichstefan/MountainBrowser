//
//  URLValidator.swift
//  MountainBrowser
//

import Foundation
import Network

/// Sicherheits-Service für URL-Validierung und Input-Sanitization
actor URLValidator {
    
    // MARK: - Error Types
    enum ValidationError: LocalizedError {
        case invalidURL
        case unsafeProtocol
        case maliciousContent
        case blacklistedDomain
        case privateIP
        case localhost
        case rateLimited
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Ungültige URL"
            case .unsafeProtocol:
                return "Unsicheres Protokoll. Nur HTTP und HTTPS sind erlaubt."
            case .maliciousContent:
                return "Potentiell gefährlicher Inhalt erkannt"
            case .blacklistedDomain:
                return "Diese Domain ist blockiert"
            case .privateIP:
                return "Private IP-Adressen sind nicht erlaubt"
            case .localhost:
                return "Localhost-URLs sind nicht erlaubt"
            case .rateLimited:
                return "Zu viele Validierungsanfragen"
            }
        }
    }
    
    // MARK: - Configuration
    private struct Configuration {
        static let allowedSchemes: Set<String> = ["http", "https"]
        static let maxURLLength = 2048
        static let maxValidationsPerMinute = 100
        
        // Blacklisted domains (malware, phishing, etc.)
        static let blacklistedDomains: Set<String> = [
            "malware.com",
            "phishing.net",
            "suspicious.org"
            // In production, this would be loaded from a security service
        ]
        
        // Suspicious patterns in URLs
        static let suspiciousPatterns = [
            "javascript:",
            "data:",
            "vbscript:",
            "file:",
            "about:",
            "<script",
            "eval(",
            "document.cookie",
            "window.location"
        ]
    }
    
    // MARK: - Properties
    private var validationHistory: [Date] = []
    
    // MARK: - Public Methods
    
    /// Validiert eine URL auf Sicherheit und Korrektheit
    func validateURL(_ urlString: String) async throws -> URL {
        try await checkRateLimit()
        
        let cleanedURLString = sanitizeInput(urlString)
        
        guard cleanedURLString.count <= Configuration.maxURLLength else {
            throw ValidationError.invalidURL
        }
        
        guard let url = URL(string: cleanedURLString) else {
            throw ValidationError.invalidURL
        }
        
        try validateScheme(url)
        try validateHost(url)
        try await validateContent(cleanedURLString)
        
        return url
    }
    
    /// Säubert und validiert Suchbegriffe
    func sanitizeSearchQuery(_ query: String) -> String {
        let cleaned = query
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "<script[^>]*>.*?</script>", with: "", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "javascript:", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "data:", with: "", options: .caseInsensitive)
        
        return String(cleaned.prefix(500)) // Limit length
    }
    
    // MARK: - Private Validation Methods
    
    private func validateScheme(_ url: URL) throws {
        guard let scheme = url.scheme?.lowercased(),
              Configuration.allowedSchemes.contains(scheme) else {
            throw ValidationError.unsafeProtocol
        }
    }
    
    private func validateHost(_ url: URL) throws {
        guard let host = url.host?.lowercased() else {
            throw ValidationError.invalidURL
        }
        
        // Check for localhost
        if host == "localhost" || host == "127.0.0.1" || host == "::1" {
            throw ValidationError.localhost
        }
        
        // Check for private IP ranges
        if isPrivateIP(host) {
            throw ValidationError.privateIP
        }
        
        // Check blacklisted domains
        for domain in Configuration.blacklistedDomains {
            if host == domain || host.hasSuffix(".\(domain)") {
                throw ValidationError.blacklistedDomain
            }
        }
    }
    
    private func validateContent(_ urlString: String) async throws {
        let lowercaseURL = urlString.lowercased()
        
        for pattern in Configuration.suspiciousPatterns {
            if lowercaseURL.contains(pattern.lowercased()) {
                throw ValidationError.maliciousContent
            }
        }
    }
    
    private func isPrivateIP(_ host: String) -> Bool {
        // Check common private IP ranges
        let privatePatterns = [
            "^10\\.",
            "^192\\.168\\.",
            "^172\\.(1[6-9]|2[0-9]|3[0-1])\\.",
            "^fc00:",
            "^fe80:"
        ]
        
        for pattern in privatePatterns {
            if host.range(of: pattern, options: .regularExpression) != nil {
                return true
            }
        }
        
        return false
    }
    
    private func sanitizeInput(_ input: String) -> String {
        let cleaned = input
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\t", with: "")
        
        // Remove potential XSS attempts
        let xssPatterns = [
            "<script[^>]*>.*?</script>",
            "<iframe[^>]*>.*?</iframe>",
            "<object[^>]*>.*?</object>",
            "<embed[^>]*>.*?</embed>",
            "javascript:",
            "data:",
            "vbscript:"
        ]
        
        var result = cleaned
        for pattern in xssPatterns {
            result = result.replacingOccurrences(
                of: pattern,
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
        }
        
        return result
    }
    
    private func checkRateLimit() async throws {
        let now = Date()
        let oneMinuteAgo = now.addingTimeInterval(-60)
        
        // Remove old entries
        validationHistory = validationHistory.filter { $0 > oneMinuteAgo }
        
        // Check rate limit
        if validationHistory.count >= Configuration.maxValidationsPerMinute {
            throw ValidationError.rateLimited
        }
        
        // Add current request
        validationHistory.append(now)
    }
}

// MARK: - Extensions

extension URLValidator {
    
    /// Quick validation for simple URL strings without full security checks
    static func isValidURLFormat(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host != nil else {
            return false
        }
        return true
    }
    
    /// Extract domain from URL string
    static func extractDomain(_ urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }
        return url.host
    }
}