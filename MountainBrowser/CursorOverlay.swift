//
//  CursorOverlay.swift
//  MountainBrowser
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
        // OPTIMIERT: Nur den Cursor zeichnen, kein unsichtbares Rectangle mehr
        // Canvas ist deutlich performanter als ZStack + .position()
        Canvas { context, size in
            let cursorCenter = position
            
            // Outer glow (subtil)
            let glowRect = CGRect(
                x: cursorCenter.x - 15,
                y: cursorCenter.y - 15,
                width: 30,
                height: 30
            )
            context.fill(
                Circle().path(in: glowRect),
                with: .color(.white.opacity(0.15))
            )
            
            // Main cursor circle
            let mainRect = CGRect(
                x: cursorCenter.x - 10,
                y: cursorCenter.y - 10,
                width: 20,
                height: 20
            )
            context.fill(
                Circle().path(in: mainRect),
                with: .color(.white)
            )
            // Border
            context.stroke(
                Circle().path(in: mainRect),
                with: .color(TVOSDesign.Colors.accentBlue),
                lineWidth: 2
            )
            
            // Center dot
            let dotRect = CGRect(
                x: cursorCenter.x - 3,
                y: cursorCenter.y - 3,
                width: 6,
                height: 6
            )
            context.fill(
                Circle().path(in: dotRect),
                with: .color(TVOSDesign.Colors.accentBlue)
            )
        }
        .allowsHitTesting(false)
        .ignoresSafeArea(.all)
    }
}

// MARK: - Cursor Position Manager
// OPTIMIERT: Exponential Moving Average (EMA) Filter für glatte Cursor-Bewegung
@Observable
final class CursorPositionManager {
    var position: CGPoint = CGPoint(x: 960, y: 540)
    var screenSize: CGSize = CGSize(width: 1920, height: 1080)
    
    // Scroll-Edge-Bereiche
    private let scrollEdgeThreshold: CGFloat = 120
    
    // OPTIMIERT: EMA-Smoothing-Faktor (0.0 = maximal glatt, 1.0 = kein Smoothing)
    // 0.45 bietet guten Kompromiss zwischen Reaktionszeit und Glätte
    private let smoothingFactor: CGFloat = 0.45
    
    // OPTIMIERT: Interner ungefilterter Zustand für Berechnungen
    private var rawTargetPosition: CGPoint = CGPoint(x: 960, y: 540)
    
    func updateScreenSize(_ size: CGSize) {
        screenSize = size
        if position.x == 960 && position.y == 540 {
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            position = center
            rawTargetPosition = center
        }
    }
    
    func resetToCenter() {
        let center = CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
        position = center
        rawTargetPosition = center
    }
    
    /// OPTIMIERT: Bewegt den Cursor um ein Delta mit EMA-Smoothing
    /// Wird direkt vom Gesture Handler aufgerufen statt über Binding
    func moveCursor(byDelta delta: CGPoint) {
        let margin: CGFloat = 25
        
        // Zielposition berechnen (ungefiltert)
        rawTargetPosition = CGPoint(
            x: max(margin, min(screenSize.width - margin, rawTargetPosition.x + delta.x)),
            y: max(margin, min(screenSize.height - margin, rawTargetPosition.y + delta.y))
        )
        
        // EMA-Filter: position = α * target + (1-α) * position
        let smoothedX = smoothingFactor * rawTargetPosition.x + (1.0 - smoothingFactor) * position.x
        let smoothedY = smoothingFactor * rawTargetPosition.y + (1.0 - smoothingFactor) * position.y
        
        position = CGPoint(x: smoothedX, y: smoothedY)
    }
    
    /// OPTIMIERT: Setzt Position direkt (ohne Smoothing, z.B. beim Reset)
    func setPositionDirect(_ newPosition: CGPoint) {
        let margin: CGFloat = 25
        let clamped = CGPoint(
            x: max(margin, min(screenSize.width - margin, newPosition.x)),
            y: max(margin, min(screenSize.height - margin, newPosition.y))
        )
        position = clamped
        rawTargetPosition = clamped
    }
    
    func clampToScreen() {
        let margin: CGFloat = 25
        position = CGPoint(
            x: max(margin, min(screenSize.width - margin, position.x)),
            y: max(margin, min(screenSize.height - margin, position.y))
        )
        rawTargetPosition = position
    }
    
    // MARK: - Scroll Edge Detection
    func isInTopScrollEdge() -> Bool {
        return position.y <= scrollEdgeThreshold
    }
    
    func isInBottomScrollEdge() -> Bool {
        return position.y >= (screenSize.height - scrollEdgeThreshold)
    }
    
    func getScrollDirection() -> ScrollDirection? {
        if isInTopScrollEdge() {
            return .up
        } else if isInBottomScrollEdge() {
            return .down
        }
        return nil
    }
}

// MARK: - Scroll Direction Enum
enum ScrollDirection {
    case up
    case down
    
    var description: String {
        switch self {
        case .up: return "Nach oben"
        case .down: return "Nach unten"
        }
    }
}

#Preview {
    @Previewable @State var position = CGPoint(x: 400, y: 300)
    let screenSize = CGSize(width: 800, height: 600)
    
    return ZStack {
        TVOSDesign.Colors.background.ignoresSafeArea()
        
        CursorOverlay(
            position: $position,
            screenSize: screenSize,
            onTap: {
            }
        )
    }
}
