//
//  NativeReaderView.swift
//  AppleTVBrowser
//
//  Nativer tvOS Web-Content-Reader (ersetzt WebView)
//  Stellt Webseiten-Inhalte in einer schönen, lesbaren SwiftUI-Oberfläche dar
//

import SwiftUI

struct NativeReaderView: View {
    let url: String
    let title: String
    @Binding var isPresented: Bool
    let sessionManager: SessionManager
    
    @State private var content: WebPageContent?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var navigationStack: [String] = []
    @FocusState private var focusedLink: String?
    
    private let contentService = WebContentService()
    
    var body: some View {
        ZStack {
            TVOSDesign.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navigation Bar
                readerNavigationBar
                
                // Content
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(error)
                } else if let content = content {
                    readerContentView(content)
                }
            }
        }
        .onAppear {
            loadPage(url)
        }
        .onExitCommand {
            if !navigationStack.isEmpty {
                goBack()
            } else {
                isPresented = false
            }
        }
    }
    
    // MARK: - Navigation Bar
    
    private var readerNavigationBar: some View {
        HStack(spacing: TVOSDesign.Spacing.elementSpacing) {
            // Zurück-Button
            Button(action: {
                if !navigationStack.isEmpty {
                    goBack()
                } else {
                    isPresented = false
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 22, weight: .semibold))
                    Text(navigationStack.isEmpty ? "Schließen" : "Zurück")
                        .font(.system(size: TVOSDesign.Typography.subheadline, weight: .semibold))
                }
                .foregroundColor(TVOSDesign.Colors.primaryLabel)
                .padding(.horizontal, 28)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(TVOSDesign.Colors.cardBackground)
                )
            }
            .buttonStyle(.card)
            
            // URL / Titel Anzeige
            HStack(spacing: 12) {
                Image(systemName: "doc.text")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(TVOSDesign.Colors.systemBlue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(content?.title ?? title)
                        .font(.system(size: TVOSDesign.Typography.subheadline, weight: .medium))
                        .foregroundColor(TVOSDesign.Colors.primaryLabel)
                        .lineLimit(1)
                    
                    Text(content?.siteName ?? extractDomain(from: url))
                        .font(.system(size: TVOSDesign.Typography.caption, weight: .regular))
                        .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(TVOSDesign.Colors.cardBackground)
            )
            
            // Reader-Modus Badge
            HStack(spacing: 8) {
                Image(systemName: "book.fill")
                    .font(.system(size: 18, weight: .medium))
                Text("Reader")
                    .font(.system(size: TVOSDesign.Typography.caption, weight: .semibold))
            }
            .foregroundColor(TVOSDesign.Colors.systemOrange)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(TVOSDesign.Colors.systemOrange.opacity(0.15))
            )
        }
        .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
        .padding(.vertical, 20)
        .background(
            TVOSDesign.Colors.background.opacity(0.98)
        )
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: TVOSDesign.Spacing.elementSpacing) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: TVOSDesign.Colors.systemBlue))
                .scaleEffect(2.5)
            
            Text("Seite wird geladen...")
                .font(.system(size: TVOSDesign.Typography.body, weight: .medium))
                .foregroundColor(TVOSDesign.Colors.primaryLabel)
            
            Text(extractDomain(from: url))
                .font(.system(size: TVOSDesign.Typography.callout))
                .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Error View
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: TVOSDesign.Spacing.cardSpacing) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 80))
                .foregroundColor(TVOSDesign.Colors.systemOrange)
            
            Text("Seite konnte nicht geladen werden")
                .font(.system(size: TVOSDesign.Typography.title2, weight: .bold))
                .foregroundColor(TVOSDesign.Colors.primaryLabel)
            
            Text(error)
                .font(.system(size: TVOSDesign.Typography.callout))
                .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 600)
            
            TVOSButton(title: "Erneut versuchen", icon: "arrow.clockwise", style: .primary) {
                loadPage(url)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Reader Content View
    
    private func readerContentView(_ content: WebPageContent) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Hero Image
                if let heroURL = content.heroImageURL {
                    AsyncImage(url: URL(string: heroURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .frame(height: 400)
                            .clipped()
                    } placeholder: {
                        Rectangle()
                            .fill(TVOSDesign.Colors.cardBackground)
                            .frame(height: 400)
                    }
                }
                
                // Inhalt
                VStack(alignment: .leading, spacing: TVOSDesign.Spacing.elementSpacing) {
                    // Titel
                    Text(content.title)
                        .font(.system(size: TVOSDesign.Typography.title1, weight: .bold))
                        .foregroundColor(TVOSDesign.Colors.primaryLabel)
                        .padding(.top, TVOSDesign.Spacing.cardSpacing)
                    
                    // Site Name
                    if !content.siteName.isEmpty {
                        Text(content.siteName)
                            .font(.system(size: TVOSDesign.Typography.callout, weight: .medium))
                            .foregroundColor(TVOSDesign.Colors.systemBlue)
                    }
                    
                    Divider()
                        .background(TVOSDesign.Colors.tertiaryLabel)
                        .padding(.vertical, TVOSDesign.Spacing.elementSpacing)
                    
                    // Abschnitte
                    ForEach(content.sections) { section in
                        sectionView(section)
                    }
                    
                    // Links
                    if !content.links.isEmpty {
                        linksSection(content.links)
                    }
                }
                .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
                .padding(.bottom, TVOSDesign.Spacing.safeAreaBottom + 100)
            }
        }
    }
    
    // MARK: - Section Views
    
    @ViewBuilder
    private func sectionView(_ section: WebPageContent.ContentSection) -> some View {
        switch section.type {
        case .heading1:
            Text(section.text)
                .font(.system(size: TVOSDesign.Typography.title1, weight: .bold))
                .foregroundColor(TVOSDesign.Colors.primaryLabel)
                .padding(.top, TVOSDesign.Spacing.elementSpacing)
            
        case .heading2:
            Text(section.text)
                .font(.system(size: TVOSDesign.Typography.title2, weight: .bold))
                .foregroundColor(TVOSDesign.Colors.primaryLabel)
                .padding(.top, TVOSDesign.Spacing.elementSpacing)
            
        case .heading3:
            Text(section.text)
                .font(.system(size: TVOSDesign.Typography.title3, weight: .semibold))
                .foregroundColor(TVOSDesign.Colors.primaryLabel)
                .padding(.top, 12)
            
        case .paragraph:
            Text(section.text)
                .font(.system(size: TVOSDesign.Typography.body, weight: .regular))
                .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                .lineSpacing(8)
                .fixedSize(horizontal: false, vertical: true)
            
        case .quote:
            HStack(alignment: .top, spacing: 16) {
                Rectangle()
                    .fill(TVOSDesign.Colors.systemBlue)
                    .frame(width: 4)
                
                Text(section.text)
                    .font(.system(size: TVOSDesign.Typography.callout, weight: .regular))
                    .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                    .italic()
                    .lineSpacing(6)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(TVOSDesign.Colors.cardBackground)
            )
            
        case .listItem:
            HStack(alignment: .top, spacing: 12) {
                Text("•")
                    .font(.system(size: TVOSDesign.Typography.body, weight: .bold))
                    .foregroundColor(TVOSDesign.Colors.systemBlue)
                
                Text(section.text)
                    .font(.system(size: TVOSDesign.Typography.callout, weight: .regular))
                    .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                    .lineSpacing(4)
            }
            .padding(.leading, 8)
            
        case .image:
            if let imageURL = section.imageURL {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(TVOSDesign.Colors.cardBackground)
                        .frame(height: 200)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            
        case .code:
            Text(section.text)
                .font(.system(size: TVOSDesign.Typography.footnote, weight: .regular, design: .monospaced))
                .foregroundColor(TVOSDesign.Colors.systemGreen)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(white: 0.08))
                )
        }
    }
    
    // MARK: - Links Section
    
    private func linksSection(_ links: [WebPageContent.PageLink]) -> some View {
        VStack(alignment: .leading, spacing: TVOSDesign.Spacing.elementSpacing) {
            Divider()
                .background(TVOSDesign.Colors.tertiaryLabel)
                .padding(.vertical, TVOSDesign.Spacing.elementSpacing)
            
            Text("Links auf dieser Seite")
                .font(.system(size: TVOSDesign.Typography.title3, weight: .semibold))
                .foregroundColor(TVOSDesign.Colors.primaryLabel)
            
            ForEach(links) { link in
                Button(action: {
                    navigateTo(link.url)
                }) {
                    HStack(spacing: 16) {
                        Image(systemName: "link")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(TVOSDesign.Colors.systemBlue)
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(link.title)
                                .font(.system(size: TVOSDesign.Typography.callout, weight: .medium))
                                .foregroundColor(TVOSDesign.Colors.primaryLabel)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            
                            Text(extractDomain(from: link.url))
                                .font(.system(size: TVOSDesign.Typography.caption))
                                .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(TVOSDesign.Colors.cardBackground)
                    )
                }
                .buttonStyle(.card)
            }
        }
    }
    
    // MARK: - Navigation
    
    private func loadPage(_ urlString: String) {
        isLoading = true
        errorMessage = nil
        content = nil
        
        Task {
            do {
                let pageContent = try await contentService.fetchContent(from: urlString)
                await MainActor.run {
                    self.content = pageContent
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func navigateTo(_ newURL: String) {
        navigationStack.append(content?.url ?? url)
        loadPage(newURL)
    }
    
    private func goBack() {
        guard let previousURL = navigationStack.popLast() else { return }
        loadPage(previousURL)
    }
    
    private func extractDomain(from urlString: String) -> String {
        guard let url = URL(string: urlString), let host = url.host else { return urlString }
        var name = host
        if name.hasPrefix("www.") { name = String(name.dropFirst(4)) }
        return name
    }
}

// MARK: - Preview

#Preview {
    NativeReaderView(
        url: "https://de.wikipedia.org/wiki/Mannheim",
        title: "Mannheim",
        isPresented: .constant(true),
        sessionManager: SessionManager()
    )
}
