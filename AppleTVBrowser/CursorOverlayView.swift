//
//  CursorOverlayView.swift
//  AppleTVBrowser
//
//  Cursor-Modus Overlay für den tvOS WebView Browser
//  Premium-Feature: Ermöglicht freies Navigieren und Klicken auf Webseiten
//

import SwiftUI
import Combine

// MARK: - Cursor Overlay View

struct CursorOverlayView: View {
    @Binding var isCursorActive: Bool
    let onClickAtPosition: (CGPoint) -> Void
    let onMoveToPosition: (CGPoint) -> Void
    
    @StateObject private var cursorState = CursorState()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Transparenter Hintergrund – fängt keine Touches ab
                Color.clear
                
                // Cursor-Grafik
                if isCursorActive && cursorState.isVisible {
                    CursorShape(isClicking: cursorState.isClicking)
                        .position(cursorState.position)
                        .animation(.interactiveSpring(response: 0.08, dampingFraction: 0.85), value: cursorState.position)
                        .animation(.spring(response: 0.15, dampingFraction: 0.6), value: cursorState.isClicking)
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Cursor-Modus Indikator (oben links)
                if isCursorActive {
                    VStack {
                        HStack {
                            cursorModeIndicator
                                .padding(.leading, TVOSDesign.Spacing.safeAreaHorizontal)
                                .padding(.top, 20)
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }
            .onAppear {
                cursorState.bounds = geometry.size
                cursorState.position = CGPoint(
                    x: geometry.size.width / 2,
                    y: geometry.size.height / 2
                )
            }
            .onChange(of: geometry.size) { _, newSize in
                cursorState.bounds = newSize
            }
        }
        .allowsHitTesting(false) // Cursor ist nur visuell, Klicks gehen über JS
    }
    
    // MARK: - Cursor Mode Indicator
    
    private var cursorModeIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: "cursorarrow.click.2")
                .font(.system(size: 14, weight: .semibold))
            Text("Cursor-Modus")
                .font(.system(size: TVOSDesign.Typography.caption, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(TVOSDesign.Colors.systemBlue.opacity(0.85))
        )
    }
    
    // MARK: - Public Interface für Controller
    
    /// Bewegt den Cursor um ein Delta (aufgerufen vom WebView Host Controller)
    func moveCursor(by delta: CGPoint) {
        cursorState.moveCursor(by: delta)
        onMoveToPosition(cursorState.position)
    }
    
    /// Führt einen Klick an der aktuellen Cursor-Position aus
    func performClick() {
        cursorState.click()
        onClickAtPosition(cursorState.position)
    }
    
    /// Aktuelle Cursor-Position
    var currentPosition: CGPoint {
        cursorState.position
    }
}

// MARK: - Cursor Shape

struct CursorShape: View {
    let isClicking: Bool
    
    var body: some View {
        ZStack {
            // Äußerer Glow-Ring
            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(
                    width: isClicking ? 32 : 44,
                    height: isClicking ? 32 : 44
                )
                .blur(radius: 6)
            
            // Hauptkreis
            Circle()
                .fill(Color.white.opacity(isClicking ? 0.95 : 0.75))
                .frame(
                    width: isClicking ? 14 : 20,
                    height: isClicking ? 14 : 20
                )
            
            // Äußerer Ring
            Circle()
                .stroke(Color.white.opacity(0.85), lineWidth: 2.5)
                .frame(
                    width: isClicking ? 18 : 26,
                    height: isClicking ? 18 : 26
                )
            
            // Klick-Ripple-Animation
            if isClicking {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 44, height: 44)
                    .transition(.scale(scale: 0.5).combined(with: .opacity))
            }
        }
        .shadow(color: .black.opacity(0.5), radius: 8, y: 4)
    }
}

// MARK: - Cursor State

@MainActor
class CursorState: ObservableObject {
    @Published var position: CGPoint = .zero
    @Published var isClicking: Bool = false
    @Published var isVisible: Bool = true
    
    var bounds: CGSize = .zero
    
    // Cursor-Einstellungen
    private let sensitivity: CGFloat = 1.8
    private let acceleration: CGFloat = 1.3
    private let edgeMargin: CGFloat = 20
    
    // Idle-Timer
    private var idleTimer: Timer?
    private let idleTimeout: TimeInterval = 8.0
    
    func moveCursor(by delta: CGPoint) {
        let speed = sqrt(delta.x * delta.x + delta.y * delta.y)
        let accelFactor = 1.0 + (speed / 120.0) * acceleration
        
        let adjusted = CGPoint(
            x: delta.x * sensitivity * accelFactor,
            y: delta.y * sensitivity * accelFactor
        )
        
        var newPos = CGPoint(
            x: position.x + adjusted.x,
            y: position.y + adjusted.y
        )
        
        // Begrenze auf Bildschirm
        newPos.x = max(edgeMargin, min(bounds.width - edgeMargin, newPos.x))
        newPos.y = max(edgeMargin, min(bounds.height - edgeMargin, newPos.y))
        
        position = newPos
        isVisible = true
        resetIdleTimer()
    }
    
    func click() {
        isClicking = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.isClicking = false
        }
    }
    
    private func resetIdleTimer() {
        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(withTimeInterval: idleTimeout, repeats: false) { [weak self] _ in
            Task { @MainActor in
                withAnimation(.easeOut(duration: 1.0)) {
                    self?.isVisible = false
                }
            }
        }
    }
}
