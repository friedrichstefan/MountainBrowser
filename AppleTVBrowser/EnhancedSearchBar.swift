//
//  EnhancedSearchBar.swift
//  AppleTVBrowser
//
//  Prominente Suchleiste mit Siri-Integration und Auto-Suggestions
//

import SwiftUI

struct EnhancedSearchBar: View {
    @Binding var searchQuery: String
    @Binding var isSearching: Bool
    let searchHistory: [String]
    let onSearch: () -> Void
    let onVoiceSearch: () -> Void
    
    @State private var isFocused: Bool = false
    @State private var showSuggestions: Bool = false
    @FocusState private var searchFieldFocused: Bool
    
    // Suchleisten-Konfiguration laut Spezifikation (120pt Höhe, 28pt Font)
    private let searchBarHeight: CGFloat = 120
    private let fontSize: CGFloat = 28
    
    var body: some View {
        VStack(spacing: 0) {
            // Hauptsuchleiste
            searchBarContent
            
            // Auto-Suggestions
            if showSuggestions && !filteredSuggestions.isEmpty {
                suggestionsView
            }
        }
    }
    
    // MARK: - Search Bar Content
    
    private var searchBarContent: some View {
        HStack(spacing: 20) {
            // Suchfeld
            HStack(spacing: 16) {
                // Suchicon
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(isFocused ? .blue : .gray)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
                
                // Texteingabe
                TextField("", text: $searchQuery, prompt: Text("Mit Google suchen oder URL eingeben")
                    .foregroundColor(.gray))
                    .font(.system(size: fontSize, weight: .medium))
                    .foregroundColor(.white)
                    .focused($searchFieldFocused)
                    .onChange(of: searchQuery) { oldValue, newValue in
                        showSuggestions = !newValue.isEmpty && newValue != oldValue
                    }
                    .onSubmit {
                        performSearch()
                    }
                
                // Clear-Button
                if !searchQuery.isEmpty {
                    Button(action: clearSearch) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isFocused ? 0.15 : 0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isFocused ? Color.blue : Color.clear, lineWidth: 3)
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
            
            // Siri Voice Search Button
            Button(action: onVoiceSearch) {
                HStack(spacing: 12) {
                    Image(systemName: "waveform")
                        .font(.system(size: 24, weight: .semibold))
                    Text("Siri")
                        .font(.system(size: 20, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.purple,
                                    Color.blue
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Such-Button
            Button(action: performSearch) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 24, weight: .semibold))
                    Text("Suchen")
                        .font(.system(size: 20, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(searchQuery.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(searchQuery.isEmpty)
        }
        .frame(height: searchBarHeight)
        .padding(.horizontal, 40)
        .padding(.vertical, 20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0x1C / 255.0, green: 0x1C / 255.0, blue: 0x1E / 255.0),
                    Color(red: 0x1C / 255.0, green: 0x1C / 255.0, blue: 0x1E / 255.0).opacity(0.95)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Suggestions View
    
    private var suggestionsView: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(filteredSuggestions.prefix(5), id: \.self) { suggestion in
                Button(action: {
                    selectSuggestion(suggestion)
                }) {
                    HStack(spacing: 16) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                        
                        Text(suggestion)
                            .font(.system(size: 22, weight: .regular))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.left")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.05))
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                    .background(Color.white.opacity(0.1))
            }
        }
        .background(Color(red: 0x1C / 255.0, green: 0x1C / 255.0, blue: 0x1E / 255.0).opacity(0.98))
        .cornerRadius(12)
        .padding(.horizontal, 40)
        .shadow(color: Color.black.opacity(0.3), radius: 20, y: 10)
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.easeOut(duration: 0.2), value: showSuggestions)
    }
    
    // MARK: - Computed Properties
    
    private var filteredSuggestions: [String] {
        guard !searchQuery.isEmpty else { return [] }
        
        return searchHistory.filter { suggestion in
            suggestion.lowercased().contains(searchQuery.lowercased())
        }
    }
    
    // MARK: - Actions
    
    private func performSearch() {
        showSuggestions = false
        searchFieldFocused = false
        onSearch()
    }
    
    private func selectSuggestion(_ suggestion: String) {
        searchQuery = suggestion
        showSuggestions = false
        performSearch()
    }
    
    private func clearSearch() {
        searchQuery = ""
        showSuggestions = false
        searchFieldFocused = true
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack {
            EnhancedSearchBar(
                searchQuery: .constant(""),
                isSearching: .constant(false),
                searchHistory: ["Apple", "Wikipedia", "GitHub", "Swift Documentation", "tvOS Development"],
                onSearch: {},
                onVoiceSearch: {}
            )
            
            Spacer()
        }
    }
}