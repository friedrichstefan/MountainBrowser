//
//  BrowserNavigationBar.swift
//  MountainBrowser
//
//  Einheitliche Navigation Bar Komponente für WebView-Modi
//

import SwiftUI

struct BrowserNavigationBar: View {
    let pageTitle: String
    let urlString: String
    let canGoBack: Bool
    let canGoForward: Bool
    let isLoading: Bool
    let modeBadge: NavigationBarModeBadge
    
    enum NavigationBarModeBadge {
        case cursor
        case scrollMode
        case reader
        
        var icon: String {
            switch self {
            case .cursor: return "cursorarrow.click.2"
            case .scrollMode: return "scroll"
            case .reader: return "book.fill"
            }
        }
        
        var title: String {
            switch self {
            case .cursor: return "Cursor"
            case .scrollMode: return "Scroll"
            case .reader: return "Reader"
            }
        }
        
        var color: Color {
            switch self {
            case .cursor: return TVOSDesign.Colors.accentBlue
            case .scrollMode: return TVOSDesign.Colors.systemGreen
            case .reader: return TVOSDesign.Colors.systemOrange
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Zurück-Icon
            Image(systemName: "chevron.left")
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                .padding(8)
            
            // URL/Titel-Anzeige
            HStack(spacing: 10) {
                Image(systemName: urlString.hasPrefix("https") ? "lock.fill" : "globe")
                    .font(.system(size: 14))
                    .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                Text(pageTitle.isEmpty ? urlString : pageTitle)
                    .font(.system(size: TVOSDesign.Typography.subheadline, weight: .medium))
                    .foregroundColor(TVOSDesign.Colors.primaryLabel)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: TVOSDesign.CornerRadius.medium)
                    .fill(TVOSDesign.Colors.cardBackground)
            )
            .frame(maxWidth: .infinity)
            
            // Nav-Icons
            HStack(spacing: 14) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(canGoBack ? TVOSDesign.Colors.secondaryLabel : TVOSDesign.Colors.tertiaryLabel.opacity(0.4))
                Image(systemName: "arrow.right")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(canGoForward ? TVOSDesign.Colors.secondaryLabel : TVOSDesign.Colors.tertiaryLabel.opacity(0.4))
                Image(systemName: isLoading ? "xmark" : "arrow.clockwise")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                
                // Modus-Badge
                HStack(spacing: 8) {
                    Image(systemName: modeBadge.icon)
                        .foregroundColor(modeBadge.color)
                        .font(.system(size: 18, weight: .semibold))
                    Text(modeBadge.title)
                        .font(.system(size: TVOSDesign.Typography.footnote, weight: .semibold))
                        .foregroundColor(modeBadge.color)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: TVOSDesign.CornerRadius.medium)
                        .fill(modeBadge.color.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: TVOSDesign.CornerRadius.medium)
                                .strokeBorder(modeBadge.color.opacity(0.25), lineWidth: 1)
                        )
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    TVOSDesign.Colors.navbarBackground.opacity(0.98),
                    TVOSDesign.Colors.navbarBackground.opacity(0.90),
                    TVOSDesign.Colors.navbarBackground.opacity(0.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(.all)
        )
        .allowsHitTesting(false)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        TVOSDesign.Colors.background.ignoresSafeArea()
        
        VStack {
            BrowserNavigationBar(
                pageTitle: "Apple",
                urlString: "https://www.apple.com",
                canGoBack: true,
                canGoForward: false,
                isLoading: false,
                modeBadge: .scrollMode
            )
            Spacer()
        }
    }
}
