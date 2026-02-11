//
//  SearchResultGridView.swift
//  AppleTVBrowser
//
//  Modern Grid Layout für Suchergebnisse mit tvOS-optimiertem Design
//

import SwiftUI

struct SearchResultGridView: View {
    let results: [SearchResult]
    let onSelect: (SearchResult) -> Void
    
    @Namespace private var animation
    @FocusState private var focusedIndex: Int?
    @State private var pressedIndex: Int?
    
    // Grid-Konfiguration laut Spezifikation
    private let columns = [
        GridItem(.adaptive(minimum: 420, maximum: 420), spacing: 20)
    ]
    private let cardHeight: CGFloat = 280
    private let cardSpacing: CGFloat = 20
    private let focusScale: CGFloat = 1.08
    private let pressScale: CGFloat = 0.95
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: cardSpacing) {
                ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                    resultCard(for: result, at: index)
                }
            }
            .padding(40)
        }
    }
    
    @ViewBuilder
    private func resultCard(for result: SearchResult, at index: Int) -> some View {
        Button(action: {
            handleCardPress(index: index, result: result)
        }) {
            SearchResultCard(
                result: result,
                isFocused: focusedIndex == index,
                isPressed: pressedIndex == index
            )
            .frame(height: cardHeight)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(getScaleForCard(index: index))
        .shadow(
            color: focusedIndex == index ? Color.orange.opacity(0.6) : Color.clear,
            radius: focusedIndex == index ? 12 : 0
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: focusedIndex)
        .animation(.easeOut(duration: 0.15), value: pressedIndex)
        .focused($focusedIndex, equals: index)
    }
    
    // MARK: - Helper Methods
    
    private func getScaleForCard(index: Int) -> CGFloat {
        if pressedIndex == index {
            return pressScale
        } else if focusedIndex == index {
            return focusScale
        }
        return 1.0
    }
    
    private func handleCardPress(index: Int, result: SearchResult) {
        // Visuelles Feedback
        pressedIndex = index
        
        // Kurze Verzögerung für Animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            pressedIndex = nil
            onSelect(result)
        }
    }
}

struct SearchResultCard: View {
    let result: SearchResult
    let isFocused: Bool
    var isPressed: Bool = false
    
    @State private var faviconImage: UIImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header mit Favicon und Titel
            HStack(alignment: .top, spacing: 12) {
                // Favicon (32x32pt laut Spezifikation)
                if let favicon = faviconImage {
                    Image(uiImage: favicon)
                        .resizable()
                        .frame(width: 32, height: 32)
                        .cornerRadius(6)
                } else {
                    Image(systemName: "globe")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                        .frame(width: 32, height: 32)
                }
                
                // Titel (max. 2 Zeilen)
                Text(result.title)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
            }
            
            // URL-Anzeige
            Text(result.displayURL)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.blue)
                .lineLimit(1)
                .truncationMode(.middle)
            
            // Beschreibung (max. 3 Zeilen)
            Text(result.description.isEmpty ? "Keine Beschreibung verfügbar" : result.description)
                .font(.system(size: 18, weight: .light))
                .foregroundColor(.gray)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(getBackgroundColor())
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(getBorderColor(), lineWidth: isFocused ? 3 : 0)
        )
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            loadFavicon()
        }
    }
    
    // MARK: - Visual Feedback
    
    private func getBackgroundColor() -> Color {
        if isPressed {
            return Color.white.opacity(0.20)
        } else if isFocused {
            return Color.white.opacity(0.12)
        } else {
            return Color.white.opacity(0.08)
        }
    }
    
    private func getBorderColor() -> Color {
        if isPressed {
            return Color.orange.opacity(0.8)
        } else if isFocused {
            return Color.orange.opacity(0.6)
        } else {
            return Color.clear
        }
    }
    
    private func loadFavicon() {
        // Favicon laden (vereinfachte Version)
        guard let url = URL(string: result.url),
              let host = url.host else { return }
        
        let faviconURL = "https://www.google.com/s2/favicons?domain=\(host)&sz=32"
        
        Task {
            do {
                guard let url = URL(string: faviconURL) else { return }
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        self.faviconImage = image
                    }
                }
            } catch {
                // Favicon konnte nicht geladen werden
            }
        }
    }
}

// Preview
#Preview {
    SearchResultGridView(
        results: [
            SearchResult(title: "Apple", url: "https://www.apple.com", description: "Discover the innovative world of Apple"),
            SearchResult(title: "Wikipedia", url: "https://www.wikipedia.org", description: "The free encyclopedia"),
            SearchResult(title: "GitHub", url: "https://www.github.com", description: "Where the world builds software")
        ],
        onSelect: { _ in }
    )
    .background(Color.black)
}