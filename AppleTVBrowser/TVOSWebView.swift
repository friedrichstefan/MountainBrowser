//
//  TVOSWebView.swift
//  AppleTVBrowser
//
//  Native tvOS Web View - NO WebKit!
//  Displays search results and basic content without WebKit
//

import SwiftUI

/// Native tvOS Web View - displays content without WebKit framework
struct TVOSWebView: View {
    @Binding var urlString: String
    @Binding var isLoading: Bool
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var pageTitle: String
    
    @State private var displayContent: String = "Welcome to tvOS Browser"
    @State private var contentType: ContentType = .welcome
    
    enum ContentType {
        case welcome
        case searchResults
        case plainText
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Content Display Area
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch contentType {
                    case .welcome:
                        welcomeContent
                    case .searchResults:
                        searchResultsContent
                    case .plainText:
                        plainTextContent
                    }
                }
                .padding(40)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.black)
            .onAppear {
                updateContent()
            }
            .onChange(of: urlString) { _, _ in
                updateContent()
            }
        }
    }
    
    // MARK: - Welcome Content
    private var welcomeContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Welcome to tvOS Browser")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)
            
            Text("Enter a URL or search query to begin")
                .font(.system(size: 32, weight: .regular))
                .foregroundColor(.gray)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Features:")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.blue)
                        Text("Search the web with DuckDuckGo and Google")
                            .foregroundColor(.gray)
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: "bookmark")
                            .foregroundColor(.blue)
                        Text("Bookmark your favorite pages")
                            .foregroundColor(.gray)
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: "clock")
                            .foregroundColor(.blue)
                        Text("Browse history")
                            .foregroundColor(.gray)
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: "gearshape")
                            .foregroundColor(.blue)
                        Text("Customize your experience")
                            .foregroundColor(.gray)
                    }
                }
                .font(.system(size: 24, weight: .regular))
            }
        }
    }
    
    // MARK: - Search Results Content
    private var searchResultsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isLoading {
                HStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                    Text("Loading search results...")
                        .font(.system(size: 28, weight: .regular))
                        .foregroundColor(.white)
                }
                .frame(maxHeight: .infinity, alignment: .center)
            } else {
                Text(pageTitle)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(urlString)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .truncationMode(.tail)
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                Text(displayContent)
                    .font(.system(size: 24, weight: .regular))
                    .foregroundColor(.white)
                    .lineSpacing(4)
            }
        }
    }
    
    // MARK: - Plain Text Content
    private var plainTextContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(pageTitle.isEmpty ? "Content" : pageTitle)
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(.white)
            
            Text(displayContent)
                .font(.system(size: 24, weight: .regular))
                .foregroundColor(.white)
                .lineSpacing(4)
        }
    }
    
    // MARK: - Helper Methods
    private func updateContent() {
        DispatchQueue.main.async {
            if urlString.isEmpty {
                contentType = .welcome
                pageTitle = "tvOS Browser"
                displayContent = "Welcome to tvOS Browser"
                return
            }
            
            // Determine content type
            if urlString.contains("google.com/search") || urlString.contains("duckduckgo.com") {
                contentType = .searchResults
                pageTitle = "Search Results"
                displayContent = "Loading search results from \(urlString)..."
            } else if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
                contentType = .plainText
                pageTitle = "Page Content"
                displayContent = "Content from: \(urlString)\n\nNote: This is a tvOS browser that displays text-based content. Full web rendering is not available on tvOS."
            } else {
                contentType = .plainText
                pageTitle = urlString
                displayContent = urlString
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack {
        TVOSWebView(
            urlString: .constant("https://www.example.com"),
            isLoading: .constant(false),
            canGoBack: .constant(false),
            canGoForward: .constant(false),
            pageTitle: .constant("Example Domain")
        )
    }
    .background(Color.black)
}