//
//  NetworkMonitor.swift
//  MountainBrowser
//
//  Überwacht den Netzwerkstatus und stellt eine Offline-Erkennung bereit.
//

import Foundation
import Network
import SwiftUI

@Observable
final class NetworkMonitor {
    static let shared = NetworkMonitor()
    
    var isConnected: Bool = true
    var connectionType: ConnectionType = .unknown
    
    enum ConnectionType: String {
        case wifi = "Wi-Fi"
        case ethernet = "Ethernet"
        case cellular = "Cellular"
        case unknown = "Unknown"
    }
    
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "MountainBrowser.NetworkMonitor", qos: .utility)
    
    private init() {
        monitor = NWPathMonitor()
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                guard let self else { return }
                self.isConnected = path.status == .satisfied
                
                if path.usesInterfaceType(.wifi) {
                    self.connectionType = .wifi
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self.connectionType = .ethernet
                } else if path.usesInterfaceType(.cellular) {
                    self.connectionType = .cellular
                } else {
                    self.connectionType = .unknown
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}

// MARK: - Offline-Banner View

struct OfflineBannerView: View {
    @State private var networkMonitor = NetworkMonitor.shared
    @State private var showBanner: Bool = false
    @State private var wasOffline: Bool = false
    @State private var showReconnected: Bool = false
    
    var body: some View {
        VStack {
            if showBanner {
                offlineBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
            } else if showReconnected {
                reconnectedBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer()
        }
        .onChange(of: networkMonitor.isConnected) { _, isConnected in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                if !isConnected {
                    showBanner = true
                    showReconnected = false
                    wasOffline = true
                } else {
                    showBanner = false
                    if wasOffline {
                        showReconnected = true
                        wasOffline = false
                        // Ausblenden nach 3 Sekunden
                        Task { @MainActor in
                            try? await Task.sleep(for: .seconds(3))
                            withAnimation(.easeOut(duration: 0.4)) {
                                showReconnected = false
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            // Initialer Check
            if !networkMonitor.isConnected {
                withAnimation {
                    showBanner = true
                    wasOffline = true
                }
            }
        }
    }
    
    private var offlineBanner: some View {
        HStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.Network.noInternetConnection)
                    .font(.system(size: TVOSDesign.Typography.callout, weight: .bold))
                    .foregroundColor(.white)
                
                Text(L10n.Network.checkNetworkConnection)
                    .font(.system(size: TVOSDesign.Typography.caption, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(TVOSDesign.Colors.systemYellow)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: TVOSDesign.CornerRadius.large)
                .fill(TVOSDesign.Colors.systemRed.opacity(0.85))
                .shadow(color: TVOSDesign.Colors.systemRed.opacity(0.4), radius: 20, y: 8)
        )
        .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
        .padding(.top, 12)
    }
    
    private var reconnectedBanner: some View {
        HStack(spacing: 16) {
            Image(systemName: "wifi")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
            
            Text(L10n.Network.connectionRestored)
                .font(.system(size: TVOSDesign.Typography.callout, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: TVOSDesign.CornerRadius.large)
                .fill(TVOSDesign.Colors.systemGreen.opacity(0.85))
                .shadow(color: TVOSDesign.Colors.systemGreen.opacity(0.4), radius: 20, y: 8)
        )
        .padding(.horizontal, TVOSDesign.Spacing.safeAreaHorizontal)
        .padding(.top, 12)
    }
}

// MARK: - Fullscreen Offline View

struct OfflineStateView: View {
    let onRetry: () -> Void
    
    @State private var networkMonitor = NetworkMonitor.shared
    @State private var animatePulse: Bool = false
    
    var body: some View {
        VStack(spacing: TVOSDesign.Spacing.cardSpacing) {
            // Animiertes Offline-Icon
            ZStack {
                Circle()
                    .fill(TVOSDesign.Colors.systemRed.opacity(0.08))
                    .frame(width: 200, height: 200)
                    .scaleEffect(animatePulse ? 1.15 : 1.0)
                    .opacity(animatePulse ? 0.3 : 0.6)
                
                Circle()
                    .fill(TVOSDesign.Colors.systemRed.opacity(0.05))
                    .frame(width: 160, height: 160)
                
                Image(systemName: "wifi.slash")
                    .font(.system(size: 80, weight: .thin))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [TVOSDesign.Colors.systemRed, TVOSDesign.Colors.systemOrange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: TVOSDesign.Spacing.elementSpacing) {
                Text(L10n.Network.noInternetConnection)
                    .font(.system(size: TVOSDesign.Typography.title2, weight: .bold))
                    .foregroundColor(TVOSDesign.Colors.primaryLabel)
                
                Text(L10n.Network.checkNetworkAndRetry)
                    .font(.system(size: TVOSDesign.Typography.body, weight: .regular))
                    .foregroundColor(TVOSDesign.Colors.secondaryLabel)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 600)
                
                // Verbindungs-Info
                HStack(spacing: 12) {
                    Circle()
                        .fill(networkMonitor.isConnected ? TVOSDesign.Colors.systemGreen : TVOSDesign.Colors.systemRed)
                        .frame(width: 10, height: 10)
                    
                    Text(networkMonitor.isConnected
                         ? L10n.Network.connectedViaType(networkMonitor.connectionType.rawValue)
                         : L10n.Network.notConnected)
                        .font(.system(size: TVOSDesign.Typography.footnote, weight: .medium))
                        .foregroundColor(TVOSDesign.Colors.tertiaryLabel)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule().fill(TVOSDesign.Colors.cardBackground)
                )
            }
            
            HStack(spacing: TVOSDesign.Spacing.elementSpacing) {
                TVOSButton(
                    title: L10n.Network.retryConnection,
                    icon: "arrow.clockwise",
                    style: .primary
                ) {
                    onRetry()
                }
                
                TVOSButton(
                    title: L10n.Network.networkSettings,
                    icon: "gear",
                    style: .secondary
                ) {
                    // Öffnet die tvOS Einstellungen (falls möglich)
                    if let url = URL(string: "App-prefs:root=General&path=Network") {
                        UIApplication.shared.open(url)
                    }
                }
            }
            .padding(.top, TVOSDesign.Spacing.elementSpacing)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animatePulse = true
            }
        }
    }
}
