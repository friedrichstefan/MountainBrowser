//
//  CursorOverlay.swift
//  AppleTVBrowser
//
//  Cursor-Overlay für die Cursor View Navigation
//

import SwiftUI

struct CursorOverlay: View {
    @Binding var position: CGPoint
    @State private var isPressed: Bool = false
    
    let screenSize: CGSize
    let onTap: () -> Void
    
    var body: some View {
        ZStack {
            // Invisible overlay for gesture recognition
            // Gesture handling is done by TVOSCursorGestureHandler instead
            Color.clear
                .contentShape(Rectangle())
            
            // Cursor visual
            cursorView
                .position(position)
        }
        .ignoresSafeArea(.all)
    }
    
    // MARK: - Cursor Visual
    private var cursorView: some View {
        ZStack {
            // Outer glow ring (only shows when pressed)
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.6),
                            Color.blue.opacity(0.3),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 5,
                        endRadius: 25
                    )
                )
                .frame(width: 50, height: 50)
                .scaleEffect(isPressed ? 1.3 : 0.8)
                .opacity(isPressed ? 0.8 : 0.2)
            
            // Main cursor circle
            Circle()
                .fill(Color.white)
                .frame(width: 20, height: 20)
                .overlay(
                    Circle()
                        .stroke(Color.blue, lineWidth: 2)
                )
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .shadow(color: .black.opacity(0.3), radius: 4, x: 2, y: 2)
            
            // Center dot
            Circle()
                .fill(Color.blue)
                .frame(width: 6, height: 6)
                .scaleEffect(isPressed ? 1.3 : 1.0)
        }
        .animation(.easeInOut(duration: 0.15), value: isPressed)
    }
    
    // MARK: - Click Handling
    private func performClick() {
        // Visual feedback
        withAnimation(.easeInOut(duration: 0.1)) {
            isPressed = true
        }
        
        // Haptic feedback (if available)
        #if os(iOS)
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        #endif
        
        // Execute click
        onTap()
        
        // Reset visual state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = false
            }
        }
    }
}

// MARK: - Cursor Position Manager
@Observable
final class CursorPositionManager {
    var position: CGPoint = CGPoint(x: 960, y: 540) // Center of 1920x1080
    var screenSize: CGSize = CGSize(width: 1920, height: 1080)
    
    func updateScreenSize(_ size: CGSize) {
        screenSize = size
        // Keep cursor centered if this is first time setting screen size
        if position.x == 960 && position.y == 540 {
            position = CGPoint(x: size.width / 2, y: size.height / 2)
        }
    }
    
    func resetToCenter() {
        position = CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
    }
    
    func clampToScreen() {
        let margin: CGFloat = 25
        position = CGPoint(
            x: max(margin, min(screenSize.width - margin, position.x)),
            y: max(margin, min(screenSize.height - margin, position.y))
        )
    }
}

#Preview {
    @Previewable @State var position = CGPoint(x: 400, y: 300)
    let screenSize = CGSize(width: 800, height: 600)
    
    return ZStack {
        Color.black.ignoresSafeArea()
        
        CursorOverlay(
            position: $position,
            screenSize: screenSize,
            onTap: {
                print("Cursor clicked at: \(position)")
            }
        )
    }
}
