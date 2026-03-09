//
//  SimpleBrowserTabView.swift
//  MountainBrowser
//
//  Browser-Tab-Übersicht für tvOS mit klarem, modernem Design
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
    @FocusState private var isNewTabFocused: Bool
    
    private let columns = [
        GridItem(.flexible(), spacing: 40),
        GridItem(.flexible(), spacing: 40),
        GridItem(.flexible(), spacing: 40)
    ]
    
    var body: some View {
        ZStack {
            // Glassmorphic Background wie in BrowserSettingsView
            GlassmorphicBackground()
            
            VStack(spacing: 0) {
                headerView
                    .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
                    .padding(.top, TVOSDesign.Spacing.safeAreaTop)
                    .padding(.bottom, 30)
                
                if tabManager.tabs.isEmpty {
                    emptyStateView
                } else {
                    tabGridView
                }
            }
        }
        .onAppear {
            if let activeTab = tabManager.activeTab {
                focusedTabId = activeTab.id
            }
        }
        .onExitCommand {
            dismiss()
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.General.tabs)
                    .font(.system(size: TVOSDesign.Typography.largeTitle, weight: .bold))
                    .foregroundColor(TVOSDesign.Colors.primaryLabel)
                
                Text(L10n.Tabs.tabCountOf(tabManager.tabs.count, 8))
                    .font(.system(size: TVOSDesign.Typography.callout, weight: .medium))
                    .foregroundColor(TVOSDesign.Colors.secondaryLabel)
            }
            
            Spacer()
            
            // Alle schließen
            if tabManager.hasMultipleTabs {
                Button(action: {
                    tabManager.closeAllTabs()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "trash")
                            .font(.system(size: 20))
                        Text(L10n.TabActions.closeAll)
                            .font(.system(size: TVOSDesign.Typography.callout, weight: .medium))
                    }
                    .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(TVOSDesign.Colors.cardBackground)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Tab Grid View
    
    private var tabGridView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 40) {
                // Bestehende Tabs
                ForEach(tabManager.tabs) { tab in
                    TabCard(
                        tab: tab,
                        isActive: tabManager.activeTab?.id == tab.id,
                        onSelect: {
                            onTabSelect(tab)
                            dismiss()
                        },
                        onClose: {
                            withAnimation(TVOSDesign.Animation.focusSpring) {
                                onCloseTab(tab)
                            }
                        }
                    )
                    .focused($focusedTabId, equals: tab.id)
                    .id(tab.id)
                }
                
                // Neuer Tab Kachel — immer am Ende
                if tabManager.canCreateNewTab {
                    NewTabKachel(onTap: {
                        onNewTab()
                        dismiss()
                    })
                    .focused($isNewTabFocused)
                }
            }
            .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
            .padding(.top, 10)
            .padding(.bottom, TVOSDesign.Spacing.safeAreaBottom + 40)
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 30) {
            Image(systemName: "square.on.square.dashed")
                .font(.system(size: 80, weight: .thin))
                .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
            
            VStack(spacing: 12) {
                Text(L10n.Tabs.noTabsOpen)
                    .font(.system(size: TVOSDesign.Typography.title2, weight: .bold))
                    .foregroundColor(TVOSDesign.Colors.primaryLabel)
                
                Text(L10n.Tabs.createNewTabToStart)
                    .font(.system(size: TVOSDesign.Typography.body))
                    .foregroundColor(TVOSDesign.Colors.secondaryLabel)
            }
            
            TVOSButton(title: L10n.General.newTab, icon: "plus.circle.fill", style: .primary) {
                onNewTab()
                dismiss()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
    }
}

// MARK: - Tab Card

private struct TabCard: View {
    let tab: BrowserTab
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 0) {
                // Oberer Bereich: Typ-Icon + Aktiv-Badge
                HStack(alignment: .top) {
                    tabTypeBadge
                    
                    Spacer()
                    
                    if isActive {
                        Text(L10n.General.active)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(TVOSDesign.Colors.accentBlue)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                
                Spacer().frame(height: 16)
                
                // Titel
                Text(tab.displayTitle)
                    .font(.system(size: TVOSDesign.Typography.headline, weight: .bold))
                    .foregroundColor(TVOSDesign.Colors.primaryLabel)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 20)
                
                Spacer().frame(height: 8)
                
                // Untertitel / Meta-Info
                if tab.isSearchTab {
                    Text(tab.resultsSummary)
                        .font(.system(size: TVOSDesign.Typography.footnote, weight: .medium))
                        .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                        .lineLimit(1)
                        .padding(.horizontal, 20)
                } else if !tab.shortDisplayURL.isEmpty {
                    Text(tab.shortDisplayURL)
                        .font(.system(size: TVOSDesign.Typography.footnote, weight: .medium))
                        .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                        .lineLimit(1)
                        .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Footer: Zeitstempel + Schließen
                HStack {
                    Text(tab.lastAccessedRelative)
                        .font(.system(size: TVOSDesign.Typography.caption, weight: .regular))
                        .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                    
                    Spacer()
                    
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(isFocused ? TVOSDesign.Colors.systemRed : TVOSDesign.Colors.tertiaryLabel)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 18)
            }
            .frame(height: 220)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isFocused ? TVOSDesign.Colors.focusedCardBackground : TVOSDesign.Colors.secondaryBackground)
            )
            // Einheitlicher Focus-Effekt mit strokeBorder — kein Überlappen
            .tvOSFocusEffect(
                isFocused: isFocused,
                cornerRadius: 20,
                accentColor: isActive ? TVOSDesign.Colors.accentBlue : nil
            )
        }
        .buttonStyle(.plain)
        .focused($isFocused)
        .zIndex(isFocused ? 100 : 0)
    }
    
    // MARK: - Tab Type Badge
    
    @ViewBuilder
    private var tabTypeBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: tabIconName)
                .font(.system(size: 16, weight: .semibold))
            Text(tabTypeLabel)
                .font(.system(size: 14, weight: .semibold))
        }
        .foregroundColor(tabBadgeColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(tabBadgeColor.opacity(0.15))
        )
    }
    
    private var tabIconName: String {
        if tab.isSearchTab { return "magnifyingglass" }
        if tab.isBlank { return "plus" }
        return "globe"
    }
    
    private var tabTypeLabel: String {
        if tab.isSearchTab { return L10n.Tabs.searchTab }
        if tab.isBlank { return L10n.Tabs.empty }
        return L10n.General.web
    }
    
    private var tabBadgeColor: Color {
        if tab.isSearchTab { return TVOSDesign.Colors.accentBlue }
        if tab.isBlank { return TVOSDesign.Colors.tertiaryLabel }
        return TVOSDesign.Colors.systemGreen
    }
}

// MARK: - Neue Tab Kachel

private struct NewTabKachel: View {
    let onTap: () -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                Spacer()
                
                Image(systemName: "plus")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(isFocused ? TVOSDesign.Colors.accentBlue : TVOSDesign.Colors.tertiaryLabel)
                
                Text(L10n.General.newTab)
                    .font(.system(size: TVOSDesign.Typography.callout, weight: .medium))
                    .foregroundColor(isFocused ? TVOSDesign.Colors.primaryLabel : TVOSDesign.Colors.secondaryLabel)
                
                Spacer()
            }
            .frame(height: 220)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isFocused ? TVOSDesign.Colors.focusedCardBackground : TVOSDesign.Colors.secondaryBackground)
            )
            // Gestrichelte Linie INNEN via strokeBorder
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 2, dash: [10, 6])
                    )
                    .foregroundColor(
                        isFocused ? TVOSDesign.Colors.accentBlue.opacity(0.6) : TVOSDesign.Colors.tertiaryLabel.opacity(0.3)
                    )
            )
            .tvOSFocusEffect(
                isFocused: isFocused,
                cornerRadius: 20,
                accentColor: TVOSDesign.Colors.accentBlue.opacity(0.5)
            )
        }
        .buttonStyle(.plain)
        .focused($isFocused)
        .zIndex(isFocused ? 100 : 0)
    }
}

// MARK: - Preview

#Preview("Browser Tabs") {
    let tabManager = TabManager()
    
    SimpleBrowserTabView(
        tabManager: tabManager,
        onTabSelect: { tab in
        },
        onNewTab: {
        },
        onCloseTab: { tab in
        }
    )
    .modelContainer(for: [HistoryEntry.self, Bookmark.self], inMemory: true)
}

