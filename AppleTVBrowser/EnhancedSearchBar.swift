//
//  EnhancedSearchBar.swift
//  AppleTVBrowser
//
//  Prominente Suchleiste mit Apple tvOS Human Interface Guidelines
//

import SwiftUI

struct EnhancedSearchBar: View {
    @Binding var searchQuery: String
    @Binding var isSearching: Bool
    let searchHistory: [String]
    let onSearch: () -> Void
    
    @State private var showSuggestions: Bool = false
    @FocusState private var isSearchFieldFocused: Bool
    @FocusState private var focusedSuggestionIndex: Int?
    
    var body: some View {
        VStack(spacing: 0) {
            // Hauptsuchleiste
            searchBarContent
            
            // Auto-Suggestions Dropdown
            if showSuggestions && !filteredSuggestions.isEmpty {
                suggestionsView
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.25), value: showSuggestions)
    }
    
    // MARK: - Search Bar Content
    
    private var searchBarContent: some View {
        HStack(spacing: TVOSDesign.Spacing.elementSpacing) {
            // Suchfeld mit Focus-Effekt
            searchField
            
            // Such-Button
            searchButton
        }
        .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
        .padding(.vertical, 30)
        .background(
            // Liquid Glass Material für Navigation (tvOS HIG)
            ZStack {
                // Blur-Effekt für Glassmorphism
                TVOSDesign.Colors.background
                
                // Subtle top highlight für Glass-Effekt
                VStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 1)
                    Spacer()
                }
            }
        )
    }
    
    // MARK: - Search Field
    
    private var searchField: some View {
        HStack(spacing: 16) {
            // Animiertes Such-Icon
            Image(systemName: "magnifyingglass")
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(isSearchFieldFocused ? .white : TVOSDesign.Colors.tertiaryLabel)
                .animation(TVOSDesign.Animation.focusSpring, value: isSearchFieldFocused)
            
            // Texteingabe
            TextField("", text: $searchQuery, prompt: Text("Suchen oder URL eingeben")
                .foregroundColor(TVOSDesign.Colors.tertiaryLabel))
                .font(.system(size: TVOSDesign.Typography.body, weight: .regular))
                .foregroundColor(TVOSDesign.Colors.primaryLabel)
                .tint(.white)
                .accentColor(.white)
                .focused($isSearchFieldFocused)
                .onChange(of: searchQuery) { oldValue, newValue in
                    withAnimation {
                        showSuggestions = !newValue.isEmpty && newValue.count >= 2
                    }
                }
                .onSubmit {
                    performSearch()
                }
            
            // Clear-Button (nur wenn Text vorhanden) - mit minimalem Touch Target
            if !searchQuery.isEmpty {
                Button(action: clearSearch) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                        .frame(minWidth: TVOSDesign.Spacing.minTouchTarget,
                               minHeight: TVOSDesign.Spacing.minTouchTarget)  // tvOS HIG: Min 56x56pt
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 20)
        .frame(minHeight: TVOSDesign.Spacing.standardTouchTarget)  // tvOS HIG: Standard 66pt Touch Target
        .background(
            RoundedRectangle(cornerRadius: TVOSDesign.Focus.cornerRadius)
                .fill(isSearchFieldFocused ? TVOSDesign.Colors.focusedCardBackground : TVOSDesign.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: TVOSDesign.Focus.cornerRadius)
                .stroke(
                    isSearchFieldFocused ? Color.white : Color.clear,
                    lineWidth: 3
                )
        )
        .scaleEffect(isSearchFieldFocused ? TVOSDesign.Focus.scale : 1.0)  // Verwendet Standard Focus Scale
        .shadow(
            color: isSearchFieldFocused ? Color.white.opacity(0.3) : Color.clear,
            radius: TVOSDesign.Focus.shadowRadius,
            y: 8
        )
        .animation(TVOSDesign.Animation.focusSpring, value: isSearchFieldFocused)
    }
    
    // MARK: - Search Button
    
    private var searchButton: some View {
        TVOSIconButton(
            icon: "arrow.right",
            label: "Suchen",
            isEnabled: !searchQuery.isEmpty,
            gradient: LinearGradient(
                colors: searchQuery.isEmpty ? 
                    [TVOSDesign.Colors.tertiaryBackground, TVOSDesign.Colors.tertiaryBackground] :
                    [Color.white, Color.white.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            foregroundWhenEnabled: .black
        ) {
            performSearch()
        }
    }
    
    // MARK: - Suggestions View
    
    private var suggestionsView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "clock")
                    .font(.system(size: 18))
                Text("Letzte Suchen")
                    .font(.system(size: TVOSDesign.Typography.footnote, weight: .semibold))
                    .textCase(.uppercase)
                    .tracking(1.2)
            }
            .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            Divider()
                .background(TVOSDesign.Colors.tertiaryBackground)
            
            // Suggestions List
            ForEach(Array(filteredSuggestions.prefix(5).enumerated()), id: \.offset) { index, suggestion in
                SuggestionRow(
                    suggestion: suggestion,
                    isFocused: focusedSuggestionIndex == index
                ) {
                    selectSuggestion(suggestion)
                }
                .focused($focusedSuggestionIndex, equals: index)
                
                if index < min(filteredSuggestions.count - 1, 4) {
                    Divider()
                        .background(TVOSDesign.Colors.tertiaryBackground.opacity(0.5))
                        .padding(.leading, 56)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(TVOSDesign.Colors.secondaryBackground)
                .shadow(color: Color.black.opacity(0.4), radius: 30, y: 15)
        )
        .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
    }
    
    // MARK: - Computed Properties
    
    private var filteredSuggestions: [String] {
        guard !searchQuery.isEmpty else { return searchHistory }
        
        return searchHistory.filter { suggestion in
            suggestion.lowercased().contains(searchQuery.lowercased())
        }
    }
    
    // MARK: - Actions
    
    private func performSearch() {
        withAnimation {
            showSuggestions = false
        }
        isSearchFieldFocused = false
        onSearch()
    }
    
    private func selectSuggestion(_ suggestion: String) {
        searchQuery = suggestion
        performSearch()
    }
    
    private func clearSearch() {
        withAnimation {
            searchQuery = ""
            showSuggestions = false
        }
        isSearchFieldFocused = true
    }
}

// MARK: - Suggestion Row Component

private struct SuggestionRow: View {
    let suggestion: String
    let isFocused: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 22))
                    .foregroundColor(isFocused ? .white : TVOSDesign.Colors.tertiaryLabel)
                    .frame(width: 32)
                
                Text(suggestion)
                    .font(.system(size: TVOSDesign.Typography.callout, weight: .regular))
                    .foregroundColor(isFocused ? TVOSDesign.Colors.primaryLabel : TVOSDesign.Colors.secondaryLabel)
                
                Spacer()
                
                Image(systemName: "arrow.up.left")
                    .font(.system(size: 18))
                    .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                    .opacity(isFocused ? 1 : 0)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .frame(minHeight: TVOSDesign.Spacing.minTouchTarget)  // tvOS HIG: Minimum 56pt Touch Target
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isFocused ? TVOSDesign.Colors.focusedCardBackground : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isFocused ? TVOSDesign.Focus.scale : 1.0)  // Verwendet Standard Focus Scale
        .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
    }
}

// MARK: - tvOS Icon Button Component

struct TVOSIconButton: View {
    let icon: String
    var label: String? = nil
    var isEnabled: Bool = true
    let gradient: LinearGradient
    var foregroundWhenEnabled: Color = TVOSDesign.Colors.primaryLabel
    let action: () -> Void
    
    @FocusState private var isFocused: Bool
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button(action: {
            guard isEnabled else { return }
            withAnimation(TVOSDesign.Animation.pressSpring) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(TVOSDesign.Animation.pressSpring) {
                    isPressed = false
                }
                action()
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                
                if let label = label {
                    Text(label)
                        .font(.system(size: TVOSDesign.Typography.subheadline, weight: .semibold))
                }
            }
            .foregroundColor(isEnabled ? foregroundWhenEnabled : TVOSDesign.Colors.tertiaryLabel)
            .padding(.horizontal, label != nil ? 32 : 24)
            .padding(.vertical, 20)
            .frame(minWidth: TVOSDesign.Spacing.standardTouchTarget,
                   minHeight: TVOSDesign.Spacing.standardTouchTarget)  // tvOS HIG: Standard 66x66pt Touch Target
            .background(
                RoundedRectangle(cornerRadius: TVOSDesign.Focus.cornerRadius)
                    .fill(gradient)
                    .opacity(isEnabled ? 1 : 0.5)
            )
            .scaleEffect(isPressed ? TVOSDesign.Focus.pressScale : (isFocused ? TVOSDesign.Focus.scale : 1.0))
            .shadow(
                color: isFocused ? Color.white.opacity(0.4) : Color.clear,
                radius: TVOSDesign.Focus.shadowRadius,
                y: 8
            )
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .disabled(!isEnabled)
        .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
        .animation(TVOSDesign.Animation.pressSpring, value: isPressed)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        TVOSDesign.Colors.background.ignoresSafeArea()
        
        VStack {
        EnhancedSearchBar(
            searchQuery: .constant("Apple"),
            isSearching: .constant(false),
            searchHistory: ["Apple", "Wikipedia", "GitHub", "Swift", "tvOS"],
            onSearch: {}
        )
            
            Spacer()
        }
    }
}
