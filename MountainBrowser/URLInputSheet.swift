//
//  URLInputSheet.swift
//  MountainBrowser
//
//  Custom Sheet für URL/Suchbegriff-Eingabe — tvOS optimiert
//

import SwiftUI

struct URLInputSheet: View {
    @Binding var isPresented: Bool
    @Binding var inputText: String
    let onOpenURL: (String) -> Void
    let onGoogleSearch: (String) -> Void
    
    @FocusState private var isTextFieldFocused: Bool
    @State private var hasAppeared: Bool = false
    @State private var localText: String = ""  // Lokaler State für TextField
    @State private var showKeyboardHint: Bool = true
    @State private var keyboardVisible: Bool = false
    @State private var displayText: String = ""  // Für Anzeige (wird nach Tastaturschließen aktualisiert)
    
    var body: some View {
        ZStack {
            // Glasmorphic Background
            GlassmorphicBackground()
            
            VStack(spacing: TVOSDesign.Spacing.cardSpacing) {
                Spacer()
                    .frame(height: 40)
                
                // Header
                VStack(spacing: TVOSDesign.Spacing.elementSpacing) {
                    Image(systemName: "link.circle.fill")
                        .font(.system(size: 70, weight: .thin))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [TVOSDesign.Colors.accentBlue, TVOSDesign.Colors.systemPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text(L10n.Home.urlOrSearchPromptTitle)
                        .font(.system(size: TVOSDesign.Typography.title2, weight: .bold))
                        .foregroundColor(TVOSDesign.Colors.primaryLabel)
                }
                
                // Großes Eingabefeld - tvOS optimiert mit prominentem Button
                VStack(spacing: TVOSDesign.Spacing.elementSpacing * 1.5) {
                    
                    // tvOS TextField mit direktem Binding
                    TextField(L10n.Home.enterSearchOrURL, text: $localText)
                        .font(.system(size: TVOSDesign.Typography.title3, weight: .semibold))
                        .foregroundColor(TVOSDesign.Colors.primaryLabel)
                        .keyboardType(.default)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($isTextFieldFocused)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 25)
                        .background(
                            RoundedRectangle(cornerRadius: TVOSDesign.CornerRadius.large)
                                .fill(Color.white.opacity(0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: TVOSDesign.CornerRadius.large)
                                        .strokeBorder(
                                            isTextFieldFocused ? TVOSDesign.Colors.accentBlue : Color.white.opacity(0.4),
                                            lineWidth: isTextFieldFocused ? 4 : 2
                                        )
                                )
                        )
                        .frame(maxWidth: 900)
                        .submitLabel(.search)
                        .onSubmit {
                            // SOFORT suchen wenn Enter/Return gedrückt wird
                            let trimmed = localText.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            displayText = trimmed
                            inputText = trimmed
                            executeActionImmediately(trimmed)
                        }
                        .onChange(of: localText) { _, newValue in
                            showKeyboardHint = newValue.isEmpty
                            // Immer synchron halten
                            displayText = newValue
                            inputText = newValue
                        }
                        .onChange(of: isTextFieldFocused) { oldFocused, newFocused in
                            keyboardVisible = newFocused
                            
                            // Wenn Tastatur geschlossen wird - automatisch ausführen wenn Text vorhanden
                            if oldFocused && !newFocused {
                                displayText = localText
                                inputText = localText
                                
                                // Automatisch Aktion ausführen wenn Text eingegeben wurde
                                let trimmed = localText.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !trimmed.isEmpty {
                                    Task { @MainActor in
                                        try? await Task.sleep(for: .milliseconds(300))
                                        executeActionImmediately(trimmed)
                                    }
                                }
                            }
                        }
                    
                    // Hinweis zum Drücken auf das Eingabefeld
                    if showKeyboardHint && localText.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "hand.tap.fill")
                                .foregroundColor(TVOSDesign.Colors.accentBlue)
                            Text(String(localized: "urlInput.tapFieldHint", defaultValue: "Tap the text field to open keyboard"))
                                .font(.system(size: TVOSDesign.Typography.callout, weight: .medium))
                                .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(TVOSDesign.Colors.accentBlue.opacity(0.15))
                        )
                    }
                    
                    // Aktuelle Eingabe anzeigen (displayText für stabilere Anzeige)
                    if !displayText.isEmpty {
                        VStack(spacing: 8) {
                            Text(String(localized: "urlInput.currentInput", defaultValue: "Current input:"))
                                .font(.system(size: TVOSDesign.Typography.footnote, weight: .medium))
                                .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                            
                            Text(displayText)
                                .font(.system(size: TVOSDesign.Typography.body, weight: .bold))
                                .foregroundColor(TVOSDesign.Colors.primaryLabel)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .strokeBorder(TVOSDesign.Colors.accentBlue.opacity(0.5), lineWidth: 2)
                                        )
                                )
                                .frame(maxWidth: 800)
                        }
                        
                        // Status-Anzeige
                        HStack(spacing: 12) {
                            Image(systemName: looksLikeURL(displayText) ? "globe" : "magnifyingglass")
                                .foregroundColor(TVOSDesign.Colors.accentBlue)
                            Text(looksLikeURL(displayText) 
                                 ? String(localized: "urlInput.urlDetected", defaultValue: "URL detected → Open website")
                                 : String(localized: "urlInput.searchTermDetected", defaultValue: "Search term → Google search"))
                                .font(.system(size: TVOSDesign.Typography.callout, weight: .semibold))
                                .foregroundColor(TVOSDesign.Colors.primaryLabel)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: TVOSDesign.CornerRadius.small)
                                .fill(TVOSDesign.Colors.accentBlue.opacity(0.2))
                        )
                    }
                }
                .padding(.horizontal, TVOSDesign.Spacing.cardSpacing)
                
                Spacer()
                    .frame(height: TVOSDesign.Spacing.elementSpacing)
                
                // Action Buttons - prominenter gestaltet
                VStack(spacing: TVOSDesign.Spacing.elementSpacing) {
                    if hasDisplayInput {
                        // Primär-Button - Automatische Aktion
                        Button {
                            let trimmed = displayText.trimmingCharacters(in: .whitespacesAndNewlines)
                            executeActionImmediately(trimmed)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: looksLikeURL(displayText) ? "globe" : "magnifyingglass")
                                    .font(.system(size: 24))
                                Text(looksLikeURL(displayText) ? L10n.URLInput.openWebsite : L10n.URLInput.startGoogleSearch)
                                    .font(.system(size: TVOSDesign.Typography.title3, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 60)
                            .padding(.vertical, 25)
                            .background(
                                RoundedRectangle(cornerRadius: TVOSDesign.CornerRadius.large)
                                    .fill(
                                        LinearGradient(
                                            colors: [TVOSDesign.Colors.accentBlue, TVOSDesign.Colors.systemPurple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Sekundäre Buttons
                    HStack(spacing: TVOSDesign.Spacing.cardSpacing) {
                        Button {
                            openURL()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "globe")
                                Text(String(localized: "urlInput.openAsURL", defaultValue: "Open as URL"))
                            }
                            .font(.system(size: TVOSDesign.Typography.body, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: TVOSDesign.CornerRadius.medium)
                                    .fill(hasInput ? Color.white.opacity(0.15) : Color.white.opacity(0.08))
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(!hasInput)
                        .opacity(hasInput ? 1.0 : 0.5)
                        
                        Button {
                            searchGoogle()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                Text(String(localized: "urlInput.searchInGoogle", defaultValue: "Search in Google"))
                            }
                            .font(.system(size: TVOSDesign.Typography.body, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: TVOSDesign.CornerRadius.medium)
                                    .fill(hasInput ? Color.white.opacity(0.15) : Color.white.opacity(0.08))
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(!hasInput)
                        .opacity(hasInput ? 1.0 : 0.5)
                    }
                }
                
                Spacer()
                
                // Cancel Button
                Button {
                    localText = ""
                    inputText = ""
                    isPresented = false
                } label: {
                    Text(L10n.General.cancel)
                        .font(.system(size: TVOSDesign.Typography.body, weight: .medium))
                        .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                        .padding(.horizontal, TVOSDesign.Spacing.cardSpacing * 2)
                        .padding(.vertical, TVOSDesign.Spacing.elementSpacing * 1.5)
                        .background(
                            RoundedRectangle(cornerRadius: TVOSDesign.CornerRadius.medium)
                                .fill(Color.white.opacity(0.08))
                        )
                }
                .buttonStyle(.plain)
                
                Spacer()
                    .frame(height: TVOSDesign.Spacing.safeAreaBottom)
            }
            .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
        }
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            
            // Initialisiere lokalen Text
            localText = inputText
            displayText = inputText
            
            // Focus auf TextField setzen
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(200))
                isTextFieldFocused = true
            }
        }
        .onExitCommand {
            inputText = ""
            isPresented = false
        }
    }
    
    // MARK: - Computed Properties
    
    private var hasInput: Bool {
        !localText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var hasDisplayInput: Bool {
        !displayText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Actions
    
    private func looksLikeURL(_ text: String) -> Bool {
        let urlPatterns = [
            "http://", "https://", "www.",
            ".com", ".de", ".org", ".net", ".io", ".ch", ".at", ".eu"
        ]
        let lower = text.lowercased()
        return urlPatterns.contains { lower.contains($0) }
    }
    
    /// Direkte Ausführung der Aktion - Callback ZUERST, dann Sheet schließen
    private func executeActionImmediately(_ text: String) {
        
        guard !text.isEmpty else {
            return
        }
        
        // Speichere die Aktion und den Text
        let isURL = looksLikeURL(text)
        let actionText = text
        
        // Setze Parent-Binding
        inputText = actionText
        
        // Führe Callback ZUERST aus (WICHTIG: vor dem Schließen!)
        if isURL {
            onOpenURL(actionText)
        } else {
            onGoogleSearch(actionText)
        }
        
        // Sheet DANACH schließen (mit kleiner Verzögerung für Animation)
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(100))
            localText = ""
            isPresented = false
        }
    }
    
    private func openURL() {
        let text = displayText.isEmpty ? localText : displayText
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        executeActionImmediately(trimmed)
    }
    
    private func searchGoogle() {
        let text = displayText.isEmpty ? localText : displayText
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        executeActionImmediately(trimmed)
    }
}

// MARK: - Preview

#Preview {
    URLInputSheet(
        isPresented: .constant(true),
        inputText: .constant(""),
        onOpenURL: { _ in },
        onGoogleSearch: { _ in }
    )
}