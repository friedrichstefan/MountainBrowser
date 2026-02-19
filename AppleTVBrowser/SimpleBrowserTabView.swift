//
//  SimpleBrowserTabView.swift
//  AppleTVBrowser
//
//  Vereinfachte Browser-Tab-Ansicht mit allen Tabs auf einen Blick
//

import SwiftUI
import SwiftData

struct SimpleBrowserTabView: View {
    let tabManager: TabManager
    let onTabSelect: (BrowserTab) -> Void
    let onNewTab: () -> Void
    let onCloseTab: (BrowserTab) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedTabId: UUID?
    @State private var selectedTab: BrowserTab?
    @State private var plusButtonId = UUID() // Eindeutige ID für Plus-Button
    
    private let columns = [
        GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 30)
    ]
    
    var body: some View {
        ZStack {
            // Hintergrund
            TVOSDesign.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header mit Titel und Aktionen
                headerView
                    .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
                    .padding(.top, TVOSDesign.Spacing.safeAreaTop)
                
                // Tab Grid
                if tabManager.tabs.isEmpty {
                    emptyStateView
                } else {
                    tabGridView
                }
                
                Spacer()
            }
        }
        .onAppear {
            // Fokus auf aktiven Tab setzen
            if let activeTab = tabManager.activeTab {
                focusedTabId = activeTab.id
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack(alignment: .center) {
            Text("Browser Tabs")
                .font(.system(size: TVOSDesign.Typography.title1, weight: .bold))
                .foregroundColor(TVOSDesign.Colors.primaryLabel)
            
            Spacer()
            
            HStack(spacing: 20) {
                // Tab-Anzahl
                Text("\(tabManager.tabs.count) Tab\(tabManager.tabs.count == 1 ? "" : "s")")
                    .font(.system(size: TVOSDesign.Typography.callout, weight: .medium))
                    .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                
                // Neuer Tab Button
                Button(action: {
                    onNewTab()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                        Text("Neuer Tab")
                            .font(.system(size: TVOSDesign.Typography.callout, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(TVOSDesign.Colors.systemBlue)
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Tab Grid View
    
    private var tabGridView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 40) {
                // Existing Tabs - Plus-Kachel entfernt
                ForEach(tabManager.tabs) { tab in
                    SimpleBrowserTabCard(
                        tab: tab,
                        isActive: tabManager.activeTab?.id == tab.id,
                        onSelect: {
                            selectedTab = tab
                            onTabSelect(tab)
                            dismiss()
                        },
                        onClose: {
                            onCloseTab(tab)
                        }
                    )
                    .focused($focusedTabId, equals: tab.id)
                }
            }
            .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
            .padding(.top, 30)
            .padding(.bottom, TVOSDesign.Spacing.safeAreaBottom)
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 30) {
            Image(systemName: "safari")
                .font(.system(size: 80))
                .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
            
            VStack(spacing: 12) {
                Text("Keine Tabs geöffnet")
                    .font(.system(size: TVOSDesign.Typography.title2, weight: .bold))
                    .foregroundColor(TVOSDesign.Colors.primaryLabel)
                
                Text("Erstelle einen neuen Tab, um loszulegen")
                    .font(.system(size: TVOSDesign.Typography.body))
                    .foregroundColor(TVOSDesign.Colors.secondaryLabel)
            }
            
            Button(action: {
                onNewTab()
                dismiss()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                    Text("Neuer Tab")
                        .font(.system(size: TVOSDesign.Typography.callout, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 20)
                .background(TVOSDesign.Colors.systemBlue)
                .cornerRadius(16)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

// MARK: - Simple Browser Tab Card

struct SimpleBrowserTabCard: View {
    let tab: BrowserTab
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    
    @FocusState private var isFocused: Bool
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isPressed = false
                }
                onSelect()
            }
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // Header mit Close-Button und Active-Indikator
                HStack {
                    // Active Indikator
                    if isActive {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(TVOSDesign.Colors.systemBlue)
                                .frame(width: 8, height: 8)
                            
                            Text("Aktiv")
                                .font(.system(size: TVOSDesign.Typography.caption, weight: .medium))
                                .foregroundColor(TVOSDesign.Colors.systemBlue)
                        }
                    } else {
                        Spacer()
                    }
                    
                    Spacer()
                    
                    // Close Button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            onClose()
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(isFocused ? TVOSDesign.Colors.systemRed : TVOSDesign.Colors.tertiaryLabel)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                // Tab Content
                VStack(alignment: .leading, spacing: 12) {
                    // Icon und Title
                    HStack(alignment: .top, spacing: 12) {
                        tabIcon
                            .frame(width: 32, height: 32)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            // Nur der Suchbegriff, nichts anderes
                            Text(tab.searchQuery ?? "Neuer Tab")
                                .font(.system(size: TVOSDesign.Typography.callout, weight: .semibold))
                                .foregroundColor(TVOSDesign.Colors.primaryLabel)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Spacer()
                    }
                    
                    // Keine zusätzlichen Infos - nur sauber und minimal
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .padding(.top, 8)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
        )
        .scaleEffect(isPressed ? 0.98 : (isFocused ? 1.03 : 1.0))
        .offset(y: isFocused ? -4 : 0)
        .shadow(
            color: shadowColor,
            radius: shadowRadius,
            y: shadowOffset
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isFocused)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
    }
    
    // MARK: - Tab Icon
    
    @ViewBuilder
    private var tabIcon: some View {
        ZStack {
            Circle()
                .fill(iconBackgroundColor)
            
            Image(systemName: iconName)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(iconColor)
        }
    }
    
    private var iconName: String {
        if tab.isSearchTab {
            return "magnifyingglass"
        } else {
            return "house"
        }
    }
    
    private var iconColor: Color {
        if tab.isSearchTab {
            return TVOSDesign.Colors.systemBlue
        } else {
            return TVOSDesign.Colors.systemIndigo
        }
    }
    
    private var iconBackgroundColor: Color {
        if tab.isSearchTab {
            return TVOSDesign.Colors.systemBlue.opacity(0.2)
        } else {
            return TVOSDesign.Colors.systemIndigo.opacity(0.2)
        }
    }
    
    // MARK: - Styling Properties
    
    private var backgroundColor: Color {
        if isPressed {
            return TVOSDesign.Colors.pressedCardBackground
        } else if isFocused {
            return TVOSDesign.Colors.focusedCardBackground
        } else if isActive {
            return TVOSDesign.Colors.cardBackground
        } else {
            return TVOSDesign.Colors.secondaryBackground
        }
    }
    
    private var borderColor: Color {
        if isActive {
            return TVOSDesign.Colors.systemBlue.opacity(0.6)
        } else if isFocused {
            return Color.white.opacity(0.8)
        } else {
            return Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        if isActive || isFocused {
            return 2
        } else {
            return 0
        }
    }
    
    private var shadowColor: Color {
        if isFocused {
            return Color.black.opacity(0.4)
        } else {
            return Color.black.opacity(0.2)
        }
    }
    
    private var shadowRadius: CGFloat {
        isFocused ? 16 : 8
    }
    
    private var shadowOffset: CGFloat {
        isFocused ? 8 : 4
    }
}

// MARK: - Tab Info Badge

struct TabInfoBadge: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
            Text(text)
                .font(.system(size: TVOSDesign.Typography.caption, weight: .medium))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.2))
        .cornerRadius(8)
    }
}

// MARK: - New Tab Card

struct NewTabCard: View {
    let onCreateTab: () -> Void
    
    @FocusState private var isFocused: Bool
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isPressed = false
                }
                onCreateTab()
            }
        }) {
            VStack(spacing: 16) {
                Image(systemName: "plus")
                    .font(.system(size: 60, weight: .light))
                    .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                
                Text("Neuer Tab")
                    .font(.system(size: TVOSDesign.Typography.callout, weight: .medium))
                    .foregroundColor(TVOSDesign.Colors.secondaryLabel)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(height: 200)
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
        )
        .scaleEffect(isPressed ? 0.98 : (isFocused ? 1.03 : 1.0))
        .offset(y: isFocused ? -4 : 0)
        .shadow(
            color: shadowColor,
            radius: shadowRadius,
            y: shadowOffset
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isFocused)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
    }
    
    private var backgroundColor: Color {
        if isPressed {
            return TVOSDesign.Colors.pressedCardBackground
        } else if isFocused {
            return TVOSDesign.Colors.focusedCardBackground
        } else {
            return TVOSDesign.Colors.cardBackground
        }
    }
    
    private var borderColor: Color {
        if isFocused {
            return Color.white.opacity(0.8)
        } else {
            return Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        return isFocused ? 2 : 0
    }
    
    private var shadowColor: Color {
        if isFocused {
            return Color.black.opacity(0.4)
        } else {
            return Color.black.opacity(0.2)
        }
    }
    
    private var shadowRadius: CGFloat {
        isFocused ? 16 : 8
    }
    
    private var shadowOffset: CGFloat {
        isFocused ? 8 : 4
    }
}

// MARK: - Preview

#Preview("Browser Tabs - Mit Inhalt") {
    let tabManager = TabManager()
    
    SimpleBrowserTabView(
        tabManager: tabManager,
        onTabSelect: { tab in
            print("Tab ausgewählt: \(tab.displayTitle)")
        },
        onNewTab: {
            print("Neuer Tab")
        },
        onCloseTab: { tab in
            print("Tab schließen: \(tab.displayTitle)")
        }
    )
    .modelContainer(for: [HistoryEntry.self, Bookmark.self], inMemory: true)
}

#Preview("Browser Tabs - Leer") {
    let tabManager = TabManager()
    
    return SimpleBrowserTabView(
        tabManager: tabManager,
        onTabSelect: { tab in
            print("Tab ausgewählt: \(tab.displayTitle)")
        },
        onNewTab: {
            print("Neuer Tab")
        },
        onCloseTab: { tab in
            print("Tab schließen: \(tab.displayTitle)")
        }
    )
    .modelContainer(for: [HistoryEntry.self, Bookmark.self], inMemory: true)
}
