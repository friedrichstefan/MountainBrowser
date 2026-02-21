//
//  BrowserSettingsView.swift
//  AppleTVBrowser
//
//  Einstellungsmenü im Apple-Design für Browser-Konfiguration
//

import SwiftUI

struct BrowserSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var sessionManager: SessionManager
    @FocusState private var focusedItem: SettingsItem?
    
    enum SettingsItem: Hashable {
        case backButton
        case viewModeSection
        case viewMode(BrowserViewMode)
        case webSettingsSection
        case javaScript
        case cookies
        case popups
        case navigation
        case actionsSection
        case reset
    }
    
    init(sessionManager: SessionManager) {
        self._sessionManager = State(wrappedValue: sessionManager)
    }
    
    var body: some View {
        ZStack {
            // Apple-typischer dunkler Hintergrund
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Zurück-Button oben links
                HStack {
                    backButton
                    Spacer()
                }
                .padding(.top, 60)
                .padding(.horizontal, 60)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 50) {
                        // Header
                        headerSection
                        
                        // Ansichtsmodus-Sektion
                        viewModeSection
                        
                        // Web-Einstellungen
                        webSettingsSection
                        
                        // Aktionen
                        actionsSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 60)
                    .padding(.vertical, 40)
                }
                .scrollClipDisabled()
            }
        }
        .onExitCommand {
            dismiss()
        }
    }
    
    // MARK: - Back Button
    
    private var backButton: some View {
        let isFocused = focusedItem == .backButton
        
        return Button(action: {
            dismiss()
        }) {
            HStack(spacing: 12) {
                // Größerer Pfeil mit Kreis-Hintergrund
                ZStack {
                    Circle()
                        .fill(isFocused ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text("Zurück")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isFocused ? .white : .gray)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isFocused ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                    .stroke(isFocused ? Color.blue.opacity(0.6) : Color.gray.opacity(0.3), lineWidth: 2)
            )
            .shadow(color: isFocused ? Color.blue.opacity(0.3) : Color.black.opacity(0.1), radius: isFocused ? 8 : 3, y: isFocused ? 4 : 2)
        }
        .buttonStyle(PlainButtonStyle())
        .focused($focusedItem, equals: .backButton)
        .scaleEffect(isFocused ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 20) {
            // Settings Icon
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.white, Color.gray.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            Text("Einstellungen")
                .font(.system(size: 48, weight: .bold, design: .default))
                .foregroundColor(.white)
            
            Text("Browser-Konfiguration anpassen")
                .font(.system(size: 24, weight: .regular))
                .foregroundColor(.gray)
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - View Mode Section
    
    private var viewModeSection: some View {
        VStack(alignment: .leading, spacing: 30) {
            sectionHeader(title: "Ansichtsmodus", icon: "rectangle.split.3x1")
                .focused($focusedItem, equals: .viewModeSection)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 20),
                GridItem(.flexible(), spacing: 20)
            ], spacing: 20) {
                ForEach(BrowserViewMode.allCases, id: \.self) { mode in
                    viewModeCard(for: mode)
                        .focused($focusedItem, equals: .viewMode(mode))
                }
            }
        }
    }
    
    private func viewModeCard(for mode: BrowserViewMode) -> some View {
        let isSelected = sessionManager.preferences.viewMode == mode
        let isFocused = focusedItem == .viewMode(mode)
        
        return Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                sessionManager.preferences.viewMode = mode
                sessionManager.savePreferences()
            }
        }) {
            VStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: iconForMode(mode))
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(isSelected ? .blue : .gray)
                }
                
                VStack(spacing: 8) {
                    Text(mode.displayName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(mode.description)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                
                // Auswahlindikator
                if isSelected {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                        
                        Text("Ausgewählt")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                    }
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 20)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(cardBackgroundColor(isSelected: isSelected, isFocused: isFocused))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        cardBorderColor(isSelected: isSelected, isFocused: isFocused),
                        lineWidth: isFocused ? 3 : (isSelected ? 2 : 1)
                    )
            )
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .shadow(color: .black.opacity(isFocused ? 0.3 : 0.1), radius: isFocused ? 15 : 5, y: isFocused ? 8 : 2)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
    }
    
    // MARK: - Web Settings Section
    
    private var webSettingsSection: some View {
        VStack(alignment: .leading, spacing: 25) {
            sectionHeader(title: "Web-Einstellungen", icon: "globe")
                .focused($focusedItem, equals: .webSettingsSection)
            
            VStack(spacing: 16) {
                settingRowWithToggle(
                    title: "JavaScript",
                    description: "Interaktive Web-Inhalte aktivieren",
                    icon: "swift",
                    isOn: Binding(
                        get: { sessionManager.preferences.enableJavaScript },
                        set: { sessionManager.preferences.enableJavaScript = $0 }
                    ),
                    focusItem: .javaScript
                )
                
                settingRowWithToggle(
                    title: "Cookies",
                    description: "Website-Einstellungen speichern",
                    icon: "externaldrive.connected.to.line.below",
                    isOn: Binding(
                        get: { sessionManager.preferences.enableCookies },
                        set: { sessionManager.preferences.enableCookies = $0 }
                    ),
                    focusItem: .cookies
                )
                
                settingRowWithToggle(
                    title: "Pop-up Blocker",
                    description: "Unerwünschte Fenster blockieren",
                    icon: "shield.fill",
                    isOn: Binding(
                        get: { sessionManager.preferences.blockPopups },
                        set: { sessionManager.preferences.blockPopups = $0 }
                    ),
                    focusItem: .popups
                )
                
                settingRowWithToggle(
                    title: "Navigation",
                    description: "URL-Leiste und Bedienelemente anzeigen",
                    icon: "safari.fill",
                    isOn: Binding(
                        get: { sessionManager.preferences.showTopNavigation },
                        set: { sessionManager.preferences.showTopNavigation = $0 }
                    ),
                    focusItem: .navigation
                )
            }
        }
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 30) {
            sectionHeader(title: "Aktionen", icon: "slider.horizontal.3")
                .focused($focusedItem, equals: .actionsSection)
            
            // Zurücksetzen Button - volle Breite
            actionButton(
                title: "Zurücksetzen",
                subtitle: "Standardwerte wiederherstellen",
                icon: "arrow.counterclockwise",
                color: .red,
                focusItem: .reset
            ) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    sessionManager.preferences = BrowserPreferences()
                    sessionManager.savePreferences()
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(.blue)
            
            Text(title)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.bottom, 10)
    }
    
    
    private func settingRowWithToggle(
        title: String,
        description: String,
        icon: String,
        isOn: Binding<Bool>,
        focusItem: SettingsItem
    ) -> some View {
        let isFocused = focusedItem == focusItem
        
        return HStack(spacing: 20) {
            // Icon
            ZStack {
                Circle()
                    .fill(isOn.wrappedValue ? Color.green.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isOn.wrappedValue ? .green : .gray)
            }
            
            // Text Content
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Custom Toggle mit dunklem Design und besserer Sichtbarkeit
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isOn.wrappedValue.toggle()
                    sessionManager.savePreferences()
                }
            }) {
                ZStack {
                    // Hintergrund-Kapsel
                    Capsule()
                        .fill(isOn.wrappedValue ? 
                              LinearGradient(colors: [Color.green, Color.green.opacity(0.8)], startPoint: .leading, endPoint: .trailing) :
                              LinearGradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)], startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: 60, height: 32)
                        .overlay(
                            Capsule()
                                .stroke(isOn.wrappedValue ? Color.green.opacity(0.5) : Color.gray.opacity(0.4), lineWidth: 1)
                        )
                    
                    // Beweglicher Kreis
                    Circle()
                        .fill(Color.white)
                        .frame(width: 26, height: 26)
                        .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                        .offset(x: isOn.wrappedValue ? 14 : -14)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isOn.wrappedValue)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .focused($focusedItem, equals: focusItem)
            .scaleEffect(isFocused ? 1.1 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isFocused)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isFocused ? Color.gray.opacity(0.15) : Color.gray.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isFocused ? Color.white.opacity(0.3) : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .shadow(color: .black.opacity(isFocused ? 0.2 : 0.05), radius: isFocused ? 10 : 3, y: isFocused ? 5 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isOn.wrappedValue)
    }
    
    private func actionButton(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        focusItem: SettingsItem,
        action: @escaping () -> Void
    ) -> some View {
        let isFocused = focusedItem == focusItem
        
        return Button(action: action) {
            VStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: icon)
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(color)
                }
                
                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isFocused ? color.opacity(0.1) : Color.gray.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isFocused ? color : Color.clear, lineWidth: isFocused ? 3 : 0)
            )
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .shadow(color: .black.opacity(isFocused ? 0.3 : 0.1), radius: isFocused ? 15 : 5, y: isFocused ? 8 : 2)
        }
        .buttonStyle(PlainButtonStyle())
        .focused($focusedItem, equals: focusItem)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
    }
    
    // MARK: - Helper Methods
    
    private func iconForMode(_ mode: BrowserViewMode) -> String {
        switch mode {
        case .scrollView:
            return "scroll"
        case .cursorView:
            return "cursorarrow.click.2"
        }
    }
    
    private func cardBackgroundColor(isSelected: Bool, isFocused: Bool) -> Color {
        if isFocused {
            return isSelected ? Color.blue.opacity(0.15) : Color.gray.opacity(0.15)
        } else {
            return isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05)
        }
    }
    
    private func cardBorderColor(isSelected: Bool, isFocused: Bool) -> Color {
        if isFocused {
            return isSelected ? .blue : .white.opacity(0.3)
        } else {
            return isSelected ? .blue.opacity(0.5) : .clear
        }
    }
}

#Preview {
    BrowserSettingsView(sessionManager: SessionManager())
        .preferredColorScheme(.dark)
}
