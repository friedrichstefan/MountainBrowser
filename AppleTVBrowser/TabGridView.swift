//
//  TabGridView.swift
//  AppleTVBrowser
//
//  Grid-Ansicht für Browser-Tabs im Safari-Stil für tvOS
//

import SwiftUI

struct TabGridView: View {
    @ObservedObject var tabManager: TabManager
    let onTabSelect: (BrowserTab) -> Void
    
    @State private var showingCloseAllAlert = false
    @FocusState private var focusedTabID: UUID?
    
    // MARK: - Grid Configuration
    
    private let gridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    private let gridSpacing: CGFloat = 20
    private let sectionSpacing: CGFloat = 30
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbarSection
            
            // Main Content
            ScrollView {
                VStack(spacing: sectionSpacing) {
                    // Tabs Grid (including NewTab as card)
                    if !tabManager.tabs.isEmpty || tabManager.canCreateNewTab {
                        tabsGridSection
                    } else {
                        emptyStateSection
                    }
                }
                .padding(.horizontal, 60)
                .padding(.vertical, 30)
            }
        }
        .background(.black)
        .alert("Alle Tabs schließen?", isPresented: $showingCloseAllAlert) {
            Button("Alle schließen", role: .destructive) {
                tabManager.closeAllTabs()
            }
            Button("Abbrechen", role: .cancel) { }
        } message: {
            Text("Dadurch werden alle offenen Tabs geschlossen und ein neuer leerer Tab erstellt.")
        }
    }
    
    // MARK: - Toolbar Section
    
    private var toolbarSection: some View {
        HStack {
            // Titel und Info
            VStack(alignment: .leading, spacing: 4) {
                Text("Tabs")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("\(tabManager.tabsCount) \(tabManager.tabsCount == 1 ? "Tab" : "Tabs")")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Toolbar-Actions
            HStack(spacing: 16) {
                // Neuer Tab (kompakt)
                ToolbarButton(
                    icon: "plus",
                    action: {
                        let newTab = tabManager.createNewTab()
                        onTabSelect(newTab)
                    }
                )
                
                // Alle schließen
                if tabManager.hasMultipleTabs {
                    ToolbarButton(
                        icon: "xmark.bin",
                        action: {
                            showingCloseAllAlert = true
                        }
                    )
                }
                
                // Tab-Sortierung
                if tabManager.hasMultipleTabs {
                    ToolbarButton(
                        icon: "arrow.up.arrow.down",
                        action: {
                            print("Tabs sortieren")
                        }
                    )
                }
            }
        }
        .padding(.horizontal, 60)
        .padding(.vertical, 20)
        .background(.ultraThinMaterial, in: Rectangle())
    }
    
    // MARK: - Tabs Grid Section
    
    private var tabsGridSection: some View {
        LazyVGrid(columns: gridColumns, spacing: gridSpacing) {
            ForEach(tabManager.tabs, id: \.id) { tab in
                TabPreviewCard(
                    tab: tab,
                    onSelect: {
                        tabManager.activateTab(tab)
                        onTabSelect(tab)
                    },
                    onClose: {
                        tabManager.closeTab(tab)
                    }
                )
                .id(tab.id)
                .focused($focusedTabID, equals: tab.id)
            }
        }
    }
    
    // MARK: - Empty State Section
    
    private var emptyStateSection: some View {
        VStack(spacing: 30) {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 80, weight: .light))
                .foregroundColor(.gray)
            
            VStack(spacing: 12) {
                Text("Keine Tabs geöffnet")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Erstelle einen neuen Tab, um mit dem Browsing zu beginnen")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            NewTabButton(action: {
                let newTab = tabManager.createNewTab()
                onTabSelect(newTab)
            })
            .scaleEffect(1.2)
        }
        .padding(.vertical, 60)
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: 24) {
            Divider()
                .background(.gray.opacity(0.3))
            
            HStack(spacing: 40) {
                // Tab Management Actions
                if tabManager.hasMultipleTabs {
                    ActionButton(
                        icon: "arrow.triangle.2.circlepath",
                        title: "Tabs neu anordnen",
                        subtitle: "Nach Datum sortieren",
                        action: {
                            // Implementierung für Tab-Sortierung
                            print("Tabs neu anordnen")
                        }
                    )
                    
                    ActionButton(
                        icon: "trash.square",
                        title: "Alte Tabs bereinigen",
                        subtitle: "Unbenutzte Tabs entfernen",
                        action: {
                            tabManager.cleanupOldTabs()
                        }
                    )
                }
                
                Spacer()
                
                // Statistics
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Tab-Statistik")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(tabManager.tabsCount) von \(tabManager.canCreateNewTab ? "12" : "12") Tabs")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if let activeTab = tabManager.activeTab {
                        Text("Aktiv: \(activeTab.displayTitle)")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}

// MARK: - NewTabButton

struct NewTabButton: View {
    let action: () -> Void
    
    @FocusState private var isFocused: Bool
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.blue.opacity(isFocused ? 0.8 : 0.4), lineWidth: 2)
                    )
                    .shadow(color: .blue.opacity(isFocused ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
                
                VStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(.blue)
                    
                    Text("Neuer Tab")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(scaleEffect)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isFocused)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .focused($isFocused)
        .onLongPressGesture(minimumDuration: 0) { pressing in
            isPressed = pressing
        } perform: {}
    }
    
    private var scaleEffect: CGFloat {
        if isPressed {
            return 0.95
        } else if isFocused {
            return 1.05
        } else {
            return 1.0
        }
    }
}

// MARK: - ToolbarButton

struct ToolbarButton: View {
    let icon: String
    let action: () -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(isFocused ? .blue : .white)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .opacity(isFocused ? 0.8 : 0.4)
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isFocused ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
        .focused($isFocused)
    }
}

// MARK: - ActionButton

struct ActionButton: View {
    let icon: String
    let title: String
    let subtitle: String?
    let action: () -> Void
    
    @FocusState private var isFocused: Bool
    
    init(icon: String, title: String, subtitle: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(isFocused ? .blue : .gray)
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
            }
            .frame(minWidth: 140)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .opacity(isFocused ? 0.8 : 0.3)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
        .focused($isFocused)
    }
}

// MARK: - Preview Provider

#Preview("Tab Grid with Tabs") {
    let tabManager = TabManager()
    
    // Simuliere einige Test-Tabs
    let testTabs = [
        BrowserTab(title: "Apple", urlString: "https://www.apple.com", isActive: true),
        BrowserTab(title: "Wikipedia", urlString: "https://de.wikipedia.org"),
        BrowserTab(title: "GitHub", urlString: "https://github.com"),
        BrowserTab(title: "YouTube", urlString: "https://www.youtube.com"),
        BrowserTab()
    ]
    
    tabManager.tabs = testTabs
    tabManager.activeTab = testTabs.first
    
    return TabGridView(
        tabManager: tabManager,
        onTabSelect: { tab in
            print("Tab selected: \(tab.displayTitle)")
        }
    )
    .preferredColorScheme(.dark)
}

#Preview("Empty Tab Grid") {
    let tabManager = TabManager()
    
    return TabGridView(
        tabManager: tabManager,
        onTabSelect: { tab in
            print("Tab selected: \(tab.displayTitle)")
        }
    )
    .preferredColorScheme(.dark)
}

#Preview("Single Tab") {
    let tabManager = TabManager()
    let singleTab = BrowserTab(title: "Apple", urlString: "https://www.apple.com", isActive: true)
    tabManager.tabs = [singleTab]
    tabManager.activeTab = singleTab
    
    return TabGridView(
        tabManager: tabManager,
        onTabSelect: { tab in
            print("Tab selected: \(tab.displayTitle)")
        }
    )
    .preferredColorScheme(.dark)
}