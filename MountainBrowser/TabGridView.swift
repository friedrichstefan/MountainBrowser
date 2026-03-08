//
//  TabGridView.swift
//  MountainBrowser
//
//  Grid-Ansicht für Browser-Tabs — Glasmorphes Design
//

import SwiftUI

struct TabGridView: View {
    @ObservedObject var tabManager: TabManager
    let onTabSelect: (BrowserTab) -> Void
    
    @State private var showingCloseAllAlert = false
    @FocusState private var focusedTabID: UUID?
    
    private let gridColumns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            toolbarSection
            
            ScrollView {
                VStack(spacing: 30) {
                    if !tabManager.tabs.isEmpty || tabManager.canCreateNewTab {
                        tabsGridSection
                    } else {
                        emptyStateSection
                    }
                }
                .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
                .padding(.vertical, 30)
            }
            .scrollClipDisabled()
        }
        .background(TVOSDesign.Colors.background)
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
            VStack(alignment: .leading, spacing: 4) {
                Text("Tabs")
                    .font(.system(size: TVOSDesign.Typography.title2, weight: .bold))
                    .foregroundColor(TVOSDesign.Colors.primaryLabel)
                
                Text("\(tabManager.tabsCount) \(tabManager.tabsCount == 1 ? "Tab" : "Tabs")")
                    .font(.system(size: TVOSDesign.Typography.callout))
                    .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                ToolbarButton(icon: "plus") {
                    let newTab = tabManager.createNewTab()
                    onTabSelect(newTab)
                }
                
                if tabManager.hasMultipleTabs {
                    ToolbarButton(icon: "xmark.bin") {
                        showingCloseAllAlert = true
                    }
                }
            }
        }
        .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
        .padding(.vertical, 20)
        .background(
            LinearGradient(
                colors: [
                    TVOSDesign.Colors.background,
                    TVOSDesign.Colors.background.opacity(0.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Tabs Grid Section
    
    private var tabsGridSection: some View {
        LazyVGrid(columns: gridColumns, spacing: 20) {
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
                .font(.system(size: 80, weight: .thin))
                .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
            
            VStack(spacing: 12) {
                Text("Keine Tabs geöffnet")
                    .font(.system(size: TVOSDesign.Typography.title2, weight: .bold))
                    .foregroundColor(TVOSDesign.Colors.primaryLabel)
                
                Text("Erstelle einen neuen Tab, um mit dem Browsing zu beginnen")
                    .font(.system(size: TVOSDesign.Typography.body))
                    .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                    .multilineTextAlignment(.center)
            }
            
            NewTabButton(action: {
                let newTab = tabManager.createNewTab()
                onTabSelect(newTab)
            })
        }
        .padding(.vertical, 60)
    }
}

// MARK: - NewTabButton (Glasmorph)

struct NewTabButton: View {
    let action: () -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: "plus")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(isFocused ? .white : TVOSDesign.Colors.accentBlue)
                
                Text("Neuer Tab")
                    .font(.system(size: TVOSDesign.Typography.callout, weight: .semibold))
                    .foregroundColor(isFocused ? .white : TVOSDesign.Colors.primaryLabel)
            }
            .frame(width: 140, height: 140)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(isFocused ? Color.white.opacity(0.12) : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(
                        isFocused ? TVOSDesign.Colors.accentBlue.opacity(0.5) : Color.white.opacity(0.06),
                        lineWidth: isFocused ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(TransparentButtonStyle())
        .focused($isFocused)
        .scaleEffect(isFocused ? 1.06 : 1.0)
        .shadow(
            color: isFocused ? TVOSDesign.Colors.accentBlue.opacity(0.2) : Color.clear,
            radius: isFocused ? 16 : 0,
            y: isFocused ? 6 : 0
        )
        .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
    }
}

// MARK: - ToolbarButton (Glasmorph)

struct ToolbarButton: View {
    let icon: String
    let action: () -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(isFocused ? .white : TVOSDesign.Colors.secondaryLabel)
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(isFocused ? Color.white.opacity(0.14) : Color.white.opacity(0.06))
                )
                .overlay(
                    Circle()
                        .strokeBorder(
                            isFocused ? TVOSDesign.Colors.accentBlue.opacity(0.5) : Color.clear,
                            lineWidth: 1.5
                        )
                )
        }
        .buttonStyle(TransparentButtonStyle())
        .focused($isFocused)
        .scaleEffect(isFocused ? 1.08 : 1.0)
        .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
    }
}

// MARK: - ActionButton (Glasmorph)

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
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(isFocused ? TVOSDesign.Colors.accentBlue : TVOSDesign.Colors.tertiaryLabel)
                
                VStack(spacing: 3) {
                    Text(title)
                        .font(.system(size: TVOSDesign.Typography.callout, weight: .semibold))
                        .foregroundColor(isFocused ? .white : TVOSDesign.Colors.primaryLabel)
                        .lineLimit(1)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: TVOSDesign.Typography.caption))
                            .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                            .lineLimit(1)
                    }
                }
            }
            .frame(minWidth: 140)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isFocused ? Color.white.opacity(0.10) : Color.white.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isFocused ? TVOSDesign.Colors.accentBlue.opacity(0.4) : Color.white.opacity(0.05),
                        lineWidth: isFocused ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(TransparentButtonStyle())
        .focused($isFocused)
        .scaleEffect(isFocused ? 1.04 : 1.0)
        .animation(TVOSDesign.Animation.focusSpring, value: isFocused)
    }
}

// MARK: - Previews

#Preview("Tab Grid with Tabs") {
    TabGridView(
        tabManager: TabManager(),
        onTabSelect: { tab in
        }
    )
    .preferredColorScheme(.dark)
}

