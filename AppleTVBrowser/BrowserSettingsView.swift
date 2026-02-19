//
//  BrowserSettingsView.swift
//  AppleTVBrowser
//
//  Einstellungsmenü für Browser-Konfiguration
//

import SwiftUI

struct BrowserSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var sessionManager: SessionManager
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(sessionManager: SessionManager) {
        self._sessionManager = State(wrappedValue: sessionManager)
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 40) {
                // Header
                headerSection
                
                // View Mode Settings
                viewModeSection
                
                // Web Settings
                webSettingsSection
                
                // Actions
                actionSection
                
                Spacer()
            }
            .padding(60)
            .background(Color.black)
            .navigationTitle("Einstellungen")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        sessionManager.savePreferences()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .alert("Einstellungen", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Browser Einstellungen")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Passe die Browser-Funktionen nach deinen Wünschen an")
                .font(.title3)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - View Mode Section
    private var viewModeSection: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("Ansichtsmodus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 20) {
                ForEach(BrowserViewMode.allCases, id: \.self) { mode in
                    viewModeCard(for: mode)
                }
            }
        }
    }
    
    private func viewModeCard(for mode: BrowserViewMode) -> some View {
        Button(action: {
            sessionManager.preferences.viewMode = mode
            sessionManager.savePreferences()
            
            withAnimation(.easeInOut(duration: 0.3)) {
                // Visual feedback
            }
        }) {
            HStack(spacing: 30) {
                // Icon
                Image(systemName: iconForMode(mode))
                    .font(.system(size: 40))
                    .foregroundColor(sessionManager.preferences.viewMode == mode ? .blue : .gray)
                    .frame(width: 60)
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    Text(mode.displayName)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(mode.description)
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Selection indicator
                if sessionManager.preferences.viewMode == mode {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.blue)
                }
            }
            .padding(25)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(sessionManager.preferences.viewMode == mode ? 
                          Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(sessionManager.preferences.viewMode == mode ? 
                                   Color.blue : Color.gray.opacity(0.3), 
                                   lineWidth: sessionManager.preferences.viewMode == mode ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(sessionManager.preferences.viewMode == mode ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: sessionManager.preferences.viewMode)
    }
    
    private func iconForMode(_ mode: BrowserViewMode) -> String {
        switch mode {
        case .scrollView:
            return "scroll"
        case .cursorView:
            return "cursorarrow.click.2"
        }
    }
    
    // MARK: - Web Settings Section
    private var webSettingsSection: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("Web-Einstellungen")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 25) {
                settingToggle(
                    title: "JavaScript aktivieren",
                    description: "Ermöglicht interaktive Web-Inhalte",
                    isOn: Binding(
                        get: { sessionManager.preferences.enableJavaScript },
                        set: { sessionManager.preferences.enableJavaScript = $0 }
                    )
                )
                
                settingToggle(
                    title: "Cookies akzeptieren",
                    description: "Speichert Website-Einstellungen",
                    isOn: Binding(
                        get: { sessionManager.preferences.enableCookies },
                        set: { sessionManager.preferences.enableCookies = $0 }
                    )
                )
                
                settingToggle(
                    title: "Pop-ups blockieren",
                    description: "Verhindert unerwünschte Fenster",
                    isOn: Binding(
                        get: { sessionManager.preferences.blockPopups },
                        set: { sessionManager.preferences.blockPopups = $0 }
                    )
                )
                
                settingToggle(
                    title: "Navigation anzeigen",
                    description: "Zeigt URL-Leiste und Bedienelemente",
                    isOn: Binding(
                        get: { sessionManager.preferences.showTopNavigation },
                        set: { sessionManager.preferences.showTopNavigation = $0 }
                    )
                )
            }
        }
    }
    
    private func settingToggle(title: String, description: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 25) {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .toggleStyle(SwitchToggleStyle())
                .scaleEffect(1.2)
        }
        .padding(.vertical, 10)
    }
    
    // MARK: - Action Section
    private var actionSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Aktionen")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            HStack(spacing: 30) {
                Button(action: resetToDefaults) {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Zurücksetzen")
                    }
                    .padding(.horizontal, 25)
                    .padding(.vertical, 15)
                    .background(Color.red.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: saveSettings) {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark")
                        Text("Speichern")
                    }
                    .padding(.horizontal, 25)
                    .padding(.vertical, 15)
                    .background(Color.green.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Actions
    private func resetToDefaults() {
        sessionManager.preferences = BrowserPreferences()
        sessionManager.savePreferences()
        
        alertMessage = "Einstellungen wurden auf Standard zurückgesetzt"
        showingAlert = true
    }
    
    private func saveSettings() {
        sessionManager.savePreferences()
        
        alertMessage = "Einstellungen wurden gespeichert"
        showingAlert = true
    }
}

#Preview {
    BrowserSettingsView(sessionManager: SessionManager())
        .preferredColorScheme(.dark)
}