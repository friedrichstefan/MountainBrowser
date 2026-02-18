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

/// Cursor-Modus mit detaillierter Zustandskontrolle
enum CursorMode: Equatable {
    case navigation   // Cursor-basierte Navigation (Standard)
    case scroll       // Scroll-Modus für Viewport-Bewegung
    case pan          // Pan-Bewegung auf der Seite
    case idle         // Idle-Modus (inaktiv)
    case dragging     // Aktives Zieh-Element
    
    var displayName: String {
        switch self {
        case .navigation: return "CURSOR"
        case .scroll: return "SCROLL"
        case .pan: return "PAN"
        case .idle: return "IDLE"
        case .dragging: return "DRAGGING"
        }
    }
    
    var indicatorColor: Color {
        switch self {
        case .navigation: return Color.blue
        case .scroll: return Color.purple
        case .pan: return Color.orange
        case .idle: return Color.gray
        case .dragging: return Color.red
        }
    }
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
        Text(mode.displayName)
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(mode.indicatorColor)
                    .opacity(0.8)
            )
            .shadow(color: mode.indicatorColor.opacity(0.5), radius: 4, x: 0, y: 0)
    }
}

/// Rand-Position für Auto-Scroll
enum EdgePosition {
    case none
    case top
    case bottom
}

/// Cursor-Manager für Bewegung und Interaktion mit erweiterter Zustandskontrolle
final class CursorManager: ObservableObject {
    @Published var position: CGPoint = .zero
    @Published var state: CursorState = .standard
    @Published var mode: CursorMode = .scroll  // GEÄNDERT: Standard ist jetzt Scroll-Mode für direktes Scrollen
    @Published var isVisible: Bool = true
    @Published var isClicked: Bool = false
    @Published var edgePosition: EdgePosition = .none
    
    // Erweiterte Zustandsverfolgung
    @Published var previousMode: CursorMode = .scroll
    @Published var modeChangeTimestamp: Date = Date()
    @Published var isInMotion: Bool = false
    @Published var lastMoveTime: Date = Date()
    
    // Bewegungs-Konfiguration
    private let moveSpeed: CGFloat = 1.2
    private let smoothingFactor: CGFloat = 0.25
    private var targetPosition: CGPoint = .zero
    private var displayLink: CADisplayLink?
    private var isAnimating: Bool = false
    // Idle-Timer deaktiviert - verursacht ständiges Wechseln
    // private var idleTimer: Timer?
    // private let idleTimeout: TimeInterval = 5.0
    
    // Screen-Boundaries mit Rand-Zone
    var screenBounds: CGRect = .zero
    private let edgeZoneHeight: CGFloat = 80.0
    private let minY: CGFloat = 100.0
    
    // Bewegungs-Historie für Trägheitserkennung
    private var recentMovements: [CGPoint] = []
    private let maxRecentMovements: Int = 10
    
    init() {
        screenBounds = .zero
        position = .zero
        targetPosition = .zero
        // Idle-Timer deaktiviert - verursacht ständiges Wechseln zwischen Modi
    }
    
    deinit {
        stopAnimation()
    }
    
    // MARK: - Mode Management
    
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

    /// Bewegt den Cursor mit verbesserter Zustandsverwaltung
    func move(by translation: CGPoint) {
        // Aktualisiere Bewegungs-Historie
        recentMovements.append(translation)
        if recentMovements.count > maxRecentMovements {
            recentMovements.removeFirst()
        }
        
        lastMoveTime = Date()
        isInMotion = true
        
        targetPosition.x += translation.x * moveSpeed
        targetPosition.y += translation.y * moveSpeed
        
        let padding: CGFloat = 20.0
        targetPosition.x = max(padding, min(targetPosition.x, screenBounds.width - padding))
        
        let maxY = screenBounds.height - edgeZoneHeight
        let clampedY = max(minY, min(targetPosition.y, maxY))
        
        let previousEdge = edgePosition
        if targetPosition.y <= minY {
            edgePosition = .top
            print("🔝 Cursor am oberen Rand - targetY: \(targetPosition.y), minY: \(minY)")
        } else if targetPosition.y >= maxY {
            edgePosition = .bottom
            print("🔽 Cursor am unteren Rand - targetY: \(targetPosition.y), maxY: \(maxY)")
        } else {
            edgePosition = .none
        }
        
        targetPosition.y = clampedY
        
        if previousEdge != edgePosition && edgePosition != .none {
            print("🔳 Edge changed: \(previousEdge) -> \(edgePosition)")
        }
        
        startAnimation()
    }
    
    /// Setzt Cursor an bestimmte Position
    func setCursorPosition(_ point: CGPoint) {
        targetPosition = point
        position = point
        lastMoveTime = Date()
    }
    
    /// Wechselt zwischen Modi mit besseren Übergängen
    func toggleMode() {
        previousMode = mode
        modeChangeTimestamp = Date()
        
        switch mode {
        case .navigation:
            mode = .scroll
        case .scroll:
            mode = .navigation
        case .pan:
            mode = .navigation
        case .idle:
            mode = .navigation
        case .dragging:
            mode = .navigation
        }
        
        print("🔄 Mode-Wechsel: \(previousMode) -> \(mode)")
    }
    
    /// Wechselt zu spezifischem Modus
    func setMode(_ newMode: CursorMode) {
        guard newMode != mode else { return }
        previousMode = mode
        mode = newMode
        modeChangeTimestamp = Date()
        print("🔄 Mode gesetzt zu: \(mode)")
    }
    
    /// Versteckt/Zeigt den Cursor mit weicheren Übergängen
    func toggleVisibility() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isVisible.toggle()
        }
    }
    
    /// Erkennt Element unter Cursor (kann erweitert werden)
    func detectElementAtCursor() -> CursorState {
        return .standard
    }
    
    /// Löst die Klick-Animation aus
    func performClick() {
        print("🔵 CursorManager.performClick() aufgerufen")
        
        if !isClicked {
            isClicked = true
            print("🔵 isClicked auf true gesetzt")
        } else {
            isClicked = false
            DispatchQueue.main.async {
                self.isClicked = true
            }
        }
    }
    
    /// Startet Drag-Bewegung
    func startDragging() {
        previousMode = mode
        mode = .dragging
        print("👐 Dragging-Modus aktiviert")
    }
    
    /// Beendet Drag-Bewegung
    func endDragging() {
        mode = previousMode
        print("👐 Zurück zu Modus: \(mode)")
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
