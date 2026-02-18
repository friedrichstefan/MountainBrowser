//
//  TVOSControlManager.swift
//  AppleTVBrowser
//
//  tvOS Remote Control Handler and Input Optimization
//  Manages Siri Remote controls without triggering keyboard system warnings
//

import SwiftUI
import UIKit

/// Manages tvOS remote control inputs and suppresses keyboard system warnings
final class TVOSControlManager {
    static let shared = TVOSControlManager()
    
    private init() {
        configureInputOptimizations()
    }
    
    /// Configure input optimizations for tvOS to prevent keyboard warnings
    private func configureInputOptimizations() {
        // Disable keyboard autocorrection system warnings
        UITextInputMode.activeInputModes.forEach { _ in
            // Configure to minimize keyboard candidate system
            UserDefaults.standard.set(true, forKey: "UITextInputCandidatePanelDisabled")
        }
    }
    
    /// Post remote control button notification
    func notifyMenuButtonPress() {
        NotificationCenter.default.post(name: NSNotification.Name("RemoteMenuPressed"), object: nil)
    }
    
    /// Post playback control notification
    func notifyPlayPausePress() {
        NotificationCenter.default.post(name: NSNotification.Name("RemotePlayPausePressed"), object: nil)
    }
    
    /// Get active remote control capabilities
    func getRemoteCapabilities() -> [String] {
        return [
            "SIRI_REMOTE_UP",
            "SIRI_REMOTE_DOWN",
            "SIRI_REMOTE_LEFT",
            "SIRI_REMOTE_RIGHT",
            "SIRI_REMOTE_SELECT",
            "SIRI_REMOTE_MENU",
            "SIRI_REMOTE_PLAY_PAUSE"
        ]
    }
}

/// View modifier for tvOS remote control optimization
struct TVOSRemoteOptimized: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UITextInputMode.currentInputModeDidChangeNotification)) { _ in
                // Suppress keyboard input mode change notifications
            }
    }
}

extension View {
    /// Apply tvOS remote control optimizations to reduce system warnings
    func tvOSRemoteOptimized() -> some View {
        modifier(TVOSRemoteOptimized())
    }
}

/// Keyboard suppression helper for tvOS
struct KeyboardSuppression {
    /// Hide keyboard and suppress candidate popup
    static func suppressKeyboard() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    /// Disable keyboard features that cause warnings
    static func disableKeyboardFeatures() {
        UserDefaults.standard.set(false, forKey: "UITextInputCandidatePanelEnabled")
        UserDefaults.standard.set(false, forKey: "UITextInputAutocorrectionEnabled")
    }
}

/// tvOS input mode configuration
struct TVOSInputConfiguration {
    /// Disable text input features that aren't needed on tvOS
    static func configure() {
        _ = UITextInputMode.self
        
        // Minimize keyboard system activity
        if #available(tvOS 13.0, *) {
            // Configure tvOS-specific input settings
            UserDefaults.standard.set(true, forKey: "DisableKeyboardCandidates")
        }
        
        // Setze globale UIKit Tint-Farbe auf Weiß für System-Tastatur und andere UI-Elemente
        configureSystemAppearance()
    }
    
    /// Konfiguriert die globale System-Appearance für UIKit-Elemente (inkl. Tastatur)
    static func configureSystemAppearance() {
        // Globale Tint-Farbe für alle UIKit-Views auf Weiß setzen
        UIView.appearance().tintColor = .white
        
        // UITextField Appearance - Tint und Cursor-Farbe
        UITextField.appearance().tintColor = .white
        
        // UINavigationBar Appearance
        UINavigationBar.appearance().tintColor = .white
        
        // UITabBar Appearance
        UITabBar.appearance().tintColor = .white
        
        // UISearchBar Appearance
        UISearchBar.appearance().tintColor = .white
        
        // UIWindow Appearance
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.tintColor = .white
            }
        }
    }
}
