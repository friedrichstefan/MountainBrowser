//
//  CursorView.swift
//  AppleTVBrowser
//
//  Visuelles Cursor-System für präzise Website-Navigation auf tvOS
//

import SwiftUI
import Combine

/// Cursor-Status für Context-Sensiti, ve-Darstellung
enum CursorState {
    case standard
    case pointer      // Über Links/Buttons
    case text         // Über Texteingabefeldern
    case loading      // Während Ladevorgang
}

/// Cursor-Modus
enum CursorMode {
    case navigation   // Cursor-basierte Navigation
    case scroll       // Scroll-Modus für Viewport-Bewegung
}

struct CursorView: View {
    @Binding var position: CGPoint
    @Binding var state: CursorState
    @Binding var mode: CursorMode
    @Binding var isVisible: Bool
    @Binding var isClicked: Bool
    
    // Animation
    @State private var clickScale: CGFloat = 1.0
    @State private var standardCursorScale: CGFloat = 1.0

    // Cursor-Konfiguration laut Spezifikation (64x64pt)
    private let cursorSize: CGFloat = 64
    private let animationDuration: Double = 0.15
    
    var body: some View {
        ZStack {
            // Cursor-Grafik basierend auf Status
            cursorShape
                .frame(width: cursorSize, height: cursorSize)
                .scaleEffect(clickScale)
                .opacity(isVisible ? 1.0 : 0.0)
                .animation(.easeInOut(duration: animationDuration), value: isVisible)
                .animation(.spring(response: 0.2, dampingFraction: 0.7), value: position)
            
            // Modus-Indikator
            if isVisible {
                modeIndicator
                    .offset(y: cursorSize / 2 + 20)
            }
        }
        .position(position)
        .allowsHitTesting(false) // Cursor soll keine Touch-Events blockieren
        .onChange(of: isClicked) { _, newValue in
            guard newValue else { return }

            // Klick-Animation: Schnell vergrößern und wieder verkleinern
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5, blendDuration: 0)) {
                clickScale = 1.4
            }
            
            // Verzögert zurücksetzen
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)) {
                    clickScale = 1.0
                }
                // Wichtig: Den isClicked-Status zurücksetzen, damit er erneut ausgelöst werden kann
                isClicked = false
            }
        }
    }
    
    @ViewBuilder
    private var cursorShape: some View {
        switch state {
        case .standard:
            standardCursor
                .scaleEffect(standardCursorScale)

        case .pointer:
            pointerCursor
        case .text:
            textCursor
        case .loading:
            loadingCursor
        }
    }
    
    private var standardCursor: some View {
        ZStack {
            // Äußerer Kreis mit Glow-Effekt
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.6),
                            Color.blue.opacity(0.2)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: cursorSize / 2
                    )
                )
                .blur(radius: 3)
            
            // Hauptkreis
            Circle()
                .fill(Color.white)
                .frame(width: cursorSize * 0.6, height: cursorSize * 0.6)
            
            // Innerer Kreis
            Circle()
                .stroke(Color.blue, lineWidth: 3)
                .frame(width: cursorSize * 0.6, height: cursorSize * 0.6)
            
            // Zentraler Punkt
            Circle()
                .fill(Color.blue)
                .frame(width: 8, height: 8)
        }
    }
    
    private var pointerCursor: some View {
        ZStack {
            // Hand-Symbol für Links/Buttons
            Circle()
                .fill(Color.orange.opacity(0.3))
                .blur(radius: 4)
            
            Circle()
                .fill(Color.white)
                .frame(width: cursorSize * 0.7, height: cursorSize * 0.7)
            
            Image(systemName: "hand.point.up.fill")
                .font(.system(size: 28))
                .foregroundColor(.orange)
        }
        .scaleEffect(1.1)
    }
    
    private var textCursor: some View {
        ZStack {
            Circle()
                .fill(Color.green.opacity(0.3))
                .blur(radius: 4)
            
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .frame(width: cursorSize * 0.8, height: cursorSize * 0.5)
            
            Image(systemName: "text.cursor")
                .font(.system(size: 28))
                .foregroundColor(.green)
        }
    }
    
    private var loadingCursor: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .blur(radius: 4)
            
            Circle()
                .fill(Color.white)
                .frame(width: cursorSize * 0.6, height: cursorSize * 0.6)
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(1.5)
        }
    }
    
    @ViewBuilder
    private var modeIndicator: some View {
        Text(mode == .navigation ? "CURSOR" : "SCROLL")
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(mode == .navigation ? Color.blue : Color.purple)
                    .opacity(0.8)
            )
    }
}

/// Rand-Position für Auto-Scroll
enum EdgePosition {
    case none
    case top
    case bottom
}

/// Cursor-Manager für Bewegung und Interaktion
final class CursorManager: ObservableObject {
    @Published var position: CGPoint = .zero
    @Published var state: CursorState = .standard
    @Published var mode: CursorMode = .navigation
    @Published var isVisible: Bool = true
    @Published var isClicked: Bool = false // Für die Klick-Animation
    @Published var edgePosition: EdgePosition = .none
    
    // Bewegungs-Konfiguration
    private let moveSpeed: CGFloat = 1.2
    private let smoothingFactor: CGFloat = 0.25
    private var targetPosition: CGPoint = .zero
    private var displayLink: CADisplayLink?
    private var isAnimating: Bool = false
    
    // Screen-Boundaries mit Rand-Zone
    var screenBounds: CGRect = .zero
    private let edgeZoneHeight: CGFloat = 80.0 // Zone am Rand für Auto-Scroll
    private let minY: CGFloat = 100.0          // Obere Grenze (unter der Nav-Bar)
    
    init() {
        // Die screenBounds werden jetzt von der aufrufenden View gesetzt.
        // Initialisiere mit .zero, um einen Absturz zu vermeiden.
        screenBounds = .zero
        position = .zero
        targetPosition = .zero
    }
    
    deinit {
        stopAnimation()
    }
    
    private func startAnimation() {
        guard !isAnimating else { return }
        isAnimating = true
        
        let target = DisplayLinkTarget { [weak self] in
            self?.updatePosition()
        }
        displayLink = CADisplayLink(target: target, selector: #selector(DisplayLinkTarget.step))
        displayLink?.add(to: .main, forMode: .common)
    }

    private func stopAnimation() {
        guard isAnimating else { return }
        isAnimating = false
        displayLink?.invalidate()
        displayLink = nil
    }

    private func updatePosition() {
        let distance = position.distance(to: targetPosition)
        
        // Stoppe Animation, wenn Ziel erreicht
        guard distance > 0.5 else {
            if position != targetPosition {
                position = targetPosition
            }
            stopAnimation()
            return
        }
        
        let newX = position.x + (targetPosition.x - position.x) * smoothingFactor
        let newY = position.y + (targetPosition.y - position.y) * smoothingFactor
        position = CGPoint(x: newX, y: newY)
    }

    /// Bewegt den Cursor basierend auf der Translation einer Geste
    func move(by translation: CGPoint) {
        targetPosition.x += translation.x * moveSpeed
        targetPosition.y += translation.y * moveSpeed
        
        // Begrenze auf Bildschirmgrenzen (horizontale Grenzen)
        let padding: CGFloat = 20.0
        targetPosition.x = max(padding, min(targetPosition.x, screenBounds.width - padding))
        
        // Vertikale Grenzen: Oben unter der Nav-Bar, unten über dem Bildschirmrand
        let maxY = screenBounds.height - edgeZoneHeight
        let clampedY = max(minY, min(targetPosition.y, maxY))
        
        // Prüfe, ob Cursor am Rand ist für Auto-Scroll
        let previousEdge = edgePosition
        if targetPosition.y <= minY {
            // Cursor versucht über oberen Rand zu gehen
            edgePosition = .top
            print("🔝 Cursor am oberen Rand - targetY: \(targetPosition.y), minY: \(minY)")
        } else if targetPosition.y >= maxY {
            // Cursor versucht über unteren Rand zu gehen
            edgePosition = .bottom
            print("🔽 Cursor am unteren Rand - targetY: \(targetPosition.y), maxY: \(maxY)")
        } else {
            edgePosition = .none
        }
        
        // Cursor auf Grenzen clampen
        targetPosition.y = clampedY
        
        // Debug-Ausgabe bei Randwechsel
        if previousEdge != edgePosition && edgePosition != .none {
            print("🔳 Edge changed: \(previousEdge) -> \(edgePosition)")
        }
        
        // Starte Animation bei neuer Bewegung
        startAnimation()
    }
    
    /// Setzt Cursor an bestimmte Position
    func setCursorPosition(_ point: CGPoint) {
        targetPosition = point
        position = point
    }
    
    /// Wechselt zwischen Cursor- und Scroll-Modus
    func toggleMode() {
        mode = mode == .navigation ? .scroll : .navigation
    }
    
    /// Versteckt/Zeigt den Cursor
    func toggleVisibility() {
        isVisible.toggle()
    }
    
    /// Erkennt Element unter Cursor
    func detectElementAtCursor() -> CursorState {
        return .standard
    }
    
    /// Löst die Klick-Animation aus
    func performClick() {
        print("🔵 CursorManager.performClick() aufgerufen")
        print("🔵 isClicked war: \(isClicked)")
        
        // Setze isClicked auf true, um die Animation in der View via .onChange auszulösen
        if !isClicked {
            isClicked = true
            print("🔵 isClicked auf true gesetzt")
        } else {
            print("🔵 isClicked war bereits true, setze trotzdem neu")
            // Force reset und dann wieder setzen
            isClicked = false
            DispatchQueue.main.async {
                self.isClicked = true
            }
        }
    }
}

/// Helper-Klasse für CADisplayLink, um Retain Cycles zu vermeiden
private class DisplayLinkTarget {
    private let callback: () -> Void
    
    init(callback: @escaping () -> Void) {
        self.callback = callback
    }
    
    @objc func step() {
        callback()
    }
}

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(point.x - x, 2) + pow(point.y - y, 2))
    }
}

// Preview
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        CursorView(
            position: .constant(CGPoint(x: 500, y: 300)),
            state: .constant(.standard),
            mode: .constant(.navigation),
            isVisible: .constant(true),
            isClicked: .constant(false)
        )
    }
}
