//
//  EnhancedSearchBar.swift
//  MountainBrowser
//
//  Prominente Suchleiste mit Apple tvOS Human Interface Guidelines
//

import SwiftUI

struct EnhancedSearchBar: View {
    @Binding var searchQuery: String
    @Binding var isSearching: Bool
    let searchHistory: [String]
    let onSearch: () -> Void
    let onReset: (() -> Void)?
    let hasResults: Bool
    let onShowTabs: (() -> Void)?
    
    @State private var showSuggestions: Bool = false
    @FocusState private var isSearchFieldFocused: Bool
    @FocusState private var focusedSuggestionIndex: Int?
    @FocusState private var backButtonFocused: Bool
    
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
            // Zurück-Button (nur wenn Suchergebnisse vorhanden)
            if hasResults {
                backButton
                    .transition(.scale.combined(with: .opacity))
            }
            
            // Suchfeld mit Focus-Effekt
            searchField
            
            // Tab-Button
            if let onShowTabs = onShowTabs {
                tabButton(action: onShowTabs)
                    .transition(.scale.combined(with: .opacity))
            }
            
            // Such-Button
            searchButton
        }
        .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
        .padding(.vertical, 28)
        .background(
            TVOSDesign.Colors.navbarBackground
        )
    }
    
    // MARK: - Search Field
    
    private var searchField: some View {
        HStack(spacing: 16) {
            // Animiertes Such-Icon
            Image(systemName: "magnifyingglass")
                .font(.system(size: 26, weight: .medium))
                .foregroundColor(isSearchFieldFocused ? TVOSDesign.Colors.accentBlue : TVOSDesign.Colors.tertiaryLabel)
                .animation(TVOSDesign.Animation.focusSpring, value: isSearchFieldFocused)
            
            // Texteingabe
            TextField("", text: $searchQuery, prompt: Text("Suchen oder URL eingeben")
                .foregroundColor(TVOSDesign.Colors.tertiaryLabel))
                .font(.system(size: TVOSDesign.Typography.body, weight: .regular))
                .foregroundColor(TVOSDesign.Colors.primaryLabel)
                .tint(TVOSDesign.Colors.accentBlue)
                .accentColor(TVOSDesign.Colors.accentBlue)
                .focused($isSearchFieldFocused)
                .onChange(of: searchQuery) { oldValue, newValue in
                    withAnimation {
                        showSuggestions = !newValue.isEmpty && newValue.count >= 2
                    }
                }
                .onSubmit {
                    performSearch()
                }
            
            // Clear-Button
            if !searchQuery.isEmpty {
                Button(action: clearSearch) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                        .frame(minWidth: TVOSDesign.Spacing.minTouchTarget,
                               minHeight: TVOSDesign.Spacing.minTouchTarget)
                }
                .buttonStyle(TransparentButtonStyle())
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 20)
        .frame(minHeight: TVOSDesign.Spacing.standardTouchTarget)
        .background(
            RoundedRectangle(cornerRadius: TVOSDesign.Focus.cornerRadius)
                .fill(isSearchFieldFocused ? TVOSDesign.Colors.focusedCardBackground : TVOSDesign.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: TVOSDesign.Focus.cornerRadius)
                .strokeBorder(
                    isSearchFieldFocused ? TVOSDesign.Colors.accentBlue.opacity(0.5) : Color.clear,
                    lineWidth: TVOSDesign.Focus.borderWidth
                )
        )
        .scaleEffect(isSearchFieldFocused ? TVOSDesign.Focus.scale : 1.0)
        .shadow(
            color: isSearchFieldFocused ? TVOSDesign.Colors.accentBlue.opacity(0.2) : Color.clear,
            radius: TVOSDesign.Focus.shadowRadius,
            y: 8
        )
        .animation(TVOSDesign.Animation.focusSpring, value: isSearchFieldFocused)
    }
    
    // MARK: - Back Button
    
    private var backButton: some View {
        Button(action: {
            withAnimation(TVOSDesign.Animation.focusSpring) {
                onReset?()
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .semibold))
                Text("Zurück")
                    .font(.system(size: TVOSDesign.Typography.subheadline, weight: .semibold))
            }
            .foregroundColor(backButtonFocused ? TVOSDesign.Colors.primaryLabel : TVOSDesign.Colors.secondaryLabel)
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .frame(minHeight: TVOSDesign.Spacing.standardTouchTarget)
            .background(
                RoundedRectangle(cornerRadius: TVOSDesign.Focus.cornerRadius)
                    .fill(backButtonFocused ? TVOSDesign.Colors.focusedCardBackground : TVOSDesign.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: TVOSDesign.Focus.cornerRadius)
                    .strokeBorder(
                        backButtonFocused ? TVOSDesign.Colors.accentBlue.opacity(0.5) : Color.clear,
                        lineWidth: TVOSDesign.Focus.borderWidth
                    )
            )
            .scaleEffect(backButtonFocused ? TVOSDesign.Focus.scale : 1.0)
            .shadow(
                color: backButtonFocused ? TVOSDesign.Colors.accentBlue.opacity(0.2) : Color.clear,
                radius: TVOSDesign.Focus.shadowRadius,
                y: backButtonFocused ? 6 : 0
            )
            .animation(TVOSDesign.Animation.focusSpring, value: backButtonFocused)
        }
        .buttonStyle(TransparentButtonStyle())
        .focused($backButtonFocused)
    }
    
    // MARK: - Tab Button
    
    private func tabButton(action: @escaping () -> Void) -> some View {
        TVOSIconButton(
            icon: "rectangle.stack",
            label: "Tabs",
            isEnabled: true,
            gradient: LinearGradient(
                colors: [TVOSDesign.Colors.systemIndigo, TVOSDesign.Colors.systemIndigo.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            foregroundWhenEnabled: .white,
            action: action
        )
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
                    [TVOSDesign.Colors.accentBlue, TVOSDesign.Colors.accentBlue.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            foregroundWhenEnabled: .white
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
                .background(TVOSDesign.Colors.separator)
            
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
                        .background(TVOSDesign.Colors.separator)
                        .padding(.leading, 56)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: TVOSDesign.Focus.cornerRadius)
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
                    .foregroundColor(isFocused ? TVOSDesign.Colors.accentBlue : TVOSDesign.Colors.tertiaryLabel)
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
            .frame(minHeight: TVOSDesign.Spacing.minTouchTarget)
            .background(
                RoundedRectangle(cornerRadius: TVOSDesign.CornerRadius.medium)
                    .fill(isFocused ? TVOSDesign.Colors.focusedCardBackground : Color.clear)
            )
        }
        .buttonStyle(TransparentButtonStyle())
        .scaleEffect(isFocused ? TVOSDesign.Focus.scale : 1.0)
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
                   minHeight: TVOSDesign.Spacing.standardTouchTarget)
            .background(
                RoundedRectangle(cornerRadius: TVOSDesign.Focus.cornerRadius)
                    .fill(gradient)
                    .opacity(isEnabled ? 1 : 0.5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: TVOSDesign.Focus.cornerRadius)
                    .strokeBorder(
                        isFocused ? Color.white.opacity(0.4) : Color.clear,
                        lineWidth: TVOSDesign.Focus.borderWidth
                    )
            )
            .scaleEffect(isPressed ? TVOSDesign.Focus.pressScale : (isFocused ? TVOSDesign.Focus.scale : 1.0))
            .shadow(
                color: isFocused ? TVOSDesign.Colors.accentBlue.opacity(0.2) : Color.clear,
                radius: TVOSDesign.Focus.shadowRadius,
                y: isFocused ? 6 : 0
            )
            .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
            .animation(TVOSDesign.Animation.pressSpring, value: isPressed)
        }
        .buttonStyle(TransparentButtonStyle())
        .focused($isFocused)
        .disabled(!isEnabled)
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
            onSearch: {},
            onReset: {},
            hasResults: true,
            onShowTabs: {}
        )
            
            Spacer()
        }
    }
}
