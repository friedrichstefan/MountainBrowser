//
//  TVOSCursorGestureHandler.swift
//  MountainBrowser
//
//  Gesture Handler für tvOS Fernbedienung Cursor-Navigation
//  OPTIMIERT: Reduzierte Latenz durch direkten CursorPositionManager-Zugriff
//

import SwiftUI
import GameController

struct TVOSCursorGestureHandler: UIViewRepresentable {
    // OPTIMIERT: Direkter Zugriff auf CursorPositionManager statt Binding
    let cursorManager: CursorPositionManager
    let screenSize: CGSize
    let onTap: () -> Void
    let onMenuPress: () -> Void
    let onPlayPause: () -> Void
    let onScroll: ((ScrollDirection) -> Void)?
    
    func makeUIView(context: Context) -> CursorGestureView {
        let view = CursorGestureView()
        view.delegate = context.coordinator
        view.backgroundColor = .clear
        return view
    }
    
    func updateUIView(_ uiView: CursorGestureView, context: Context) {
        context.coordinator.cursorManager = cursorManager
        context.coordinator.screenSize = screenSize
        context.coordinator.onTap = onTap
        context.coordinator.onMenuPress = onMenuPress
        context.coordinator.onPlayPause = onPlayPause
        context.coordinator.onScroll = onScroll
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            cursorManager: cursorManager,
            screenSize: screenSize,
            onTap: onTap,
            onMenuPress: onMenuPress,
            onPlayPause: onPlayPause
        )
    }
    
    class Coordinator: NSObject, CursorGestureViewDelegate {
        var cursorManager: CursorPositionManager
        var screenSize: CGSize
        var onTap: () -> Void
        var onMenuPress: () -> Void
        var onPlayPause: () -> Void
        var onScroll: ((ScrollDirection) -> Void)?
        
        // OPTIMIERT: Reduzierte Sensitivity und erhöhte Dead Zone gegen Rauschen
        private let sensitivity: CGFloat = 0.9
        private let acceleration: CGFloat = 1.15
        private let deadZone: CGFloat = 0.8  // Erhöht: filtert Micro-Jitter der Siri Remote
        
        // Scroll settings
        private let scrollEdgeThreshold: CGFloat = 100
        private let navigationBarHeight: CGFloat = 100
        private var scrollTimer: Timer?
        private var currentScrollSpeed: TimeInterval = 0.8
        private let minScrollInterval: TimeInterval = 0.4
        private let maxScrollInterval: TimeInterval = 0.8
        
        // Auto-Scroll am Rand
        private var isAutoScrolling = false
        private let autoScrollThreshold: CGFloat = 80
        private let swipeThreshold: CGFloat = 25.0
        
        // Cooldown um Scroll-Spam zu verhindern
        private var lastEdgeScrollTime: Date = .distantPast
        private let edgeScrollCooldown: TimeInterval = 0.3
        
        // Scroll-Beschleunigung
        private var lastScrollDirection: ScrollDirection?
        private var scrollVelocityAccumulator: CGFloat = 0
        
        // FIX: Flag um zu verhindern, dass Callbacks nach deinit feuern
        private var isInvalidated = false
        
        // FIX: Observer für StopAllTimers-Notification
        private var stopTimersObserver: NSObjectProtocol?
        
        // OPTIMIERT: Velocity-basiertes Smoothing — bei langsamer Bewegung mehr glätten
        private let lowSpeedThreshold: CGFloat = 200.0
        private let highSpeedThreshold: CGFloat = 1500.0
        
        init(cursorManager: CursorPositionManager, screenSize: CGSize, onTap: @escaping () -> Void, onMenuPress: @escaping () -> Void, onPlayPause: @escaping () -> Void) {
            self.cursorManager = cursorManager
            self.screenSize = screenSize
            self.onTap = onTap
            self.onMenuPress = onMenuPress
            self.onPlayPause = onPlayPause
            
            super.init()
            
            stopTimersObserver = NotificationCenter.default.addObserver(
                forName: NSNotification.Name("StopAllTimers"),
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.stopScrolling()
            }
        }
        
        func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
            guard !isInvalidated else { return }
            
            let translation = gesture.translation(in: gesture.view)
            let velocity = gesture.velocity(in: gesture.view)
            
            let speed = sqrt(velocity.x * velocity.x + velocity.y * velocity.y)
            
            // OPTIMIERT: Sanftere Acceleration-Kurve
            let normalizedSpeed = min(speed / highSpeedThreshold, 1.0)
            let accelerationFactor = 1.0 + (acceleration - 1.0) * normalizedSpeed
            
            var deltaX = translation.x * sensitivity * accelerationFactor
            var deltaY = translation.y * sensitivity * accelerationFactor
            
            // OPTIMIERT: Größere Dead Zone filtert Siri Remote Rauschen
            if abs(deltaX) < deadZone { deltaX = 0 }
            if abs(deltaY) < deadZone { deltaY = 0 }
            
            // Wenn kein tatsächliches Delta, nichts tun (spart SwiftUI-Updates)
            guard deltaX != 0 || deltaY != 0 else {
                gesture.setTranslation(.zero, in: gesture.view)
                return
            }
            
            // Auto-Scroll am Rand
            let currentY = cursorManager.position.y
            let isNearTop = currentY <= autoScrollThreshold
            let isNearBottom = currentY >= (screenSize.height - autoScrollThreshold)
            let now = Date()
            
            if isNearTop && deltaY < -swipeThreshold && now.timeIntervalSince(lastEdgeScrollTime) >= edgeScrollCooldown {
                onScroll?(.up)
                lastEdgeScrollTime = now
                deltaY = 0
            } else if isNearBottom && deltaY > swipeThreshold && now.timeIntervalSince(lastEdgeScrollTime) >= edgeScrollCooldown {
                onScroll?(.down)
                lastEdgeScrollTime = now
                deltaY = 0
            }
            
            // OPTIMIERT: Direkt CursorPositionManager aufrufen (kein Binding-Overhead)
            cursorManager.moveCursor(byDelta: CGPoint(x: deltaX, y: deltaY))
            
            gesture.setTranslation(.zero, in: gesture.view)
            
            if gesture.state == .ended || gesture.state == .cancelled {
                stopScrolling()
            }
        }
        
        func handleTapGesture(_ gesture: UITapGestureRecognizer) {
            guard !isInvalidated else { return }
            onTap()
        }
        
        func handleMenuPress() {
            guard !isInvalidated else { return }
            stopScrolling()
            onMenuPress()
        }
        
        func handlePlayPause() {
            guard !isInvalidated else { return }
            onPlayPause()
        }
        
        // MARK: - Scroll Logic
        private func startScrolling(direction: ScrollDirection) {
            guard !isInvalidated else { return }
            stopScrolling()
            
            lastScrollDirection = direction
            onScroll?(direction)
            
            scrollTimer = Timer.scheduledTimer(withTimeInterval: currentScrollSpeed, repeats: true) { [weak self] timer in
                guard let self = self, !self.isInvalidated else {
                    timer.invalidate()
                    return
                }
                self.onScroll?(direction)
                self.accelerateScrolling()
            }
        }
        
        private func accelerateScrolling() {
            guard !isInvalidated else { return }
            
            scrollVelocityAccumulator += 0.002
            let newSpeed = max(minScrollInterval, currentScrollSpeed - scrollVelocityAccumulator * 0.005)
            
            if abs(newSpeed - currentScrollSpeed) > 0.01 {
                currentScrollSpeed = newSpeed
                if let direction = lastScrollDirection {
                    scrollTimer?.invalidate()
                    scrollTimer = Timer.scheduledTimer(withTimeInterval: currentScrollSpeed, repeats: true) { [weak self] timer in
                        guard let self = self, !self.isInvalidated else {
                            timer.invalidate()
                            return
                        }
                        self.onScroll?(direction)
                    }
                }
            }
        }
        
        private func stopScrolling() {
            scrollTimer?.invalidate()
            scrollTimer = nil
            currentScrollSpeed = maxScrollInterval
            scrollVelocityAccumulator = 0
            lastScrollDirection = nil
        }
        
        deinit {
            isInvalidated = true
            
            if let observer = stopTimersObserver {
                NotificationCenter.default.removeObserver(observer)
            }
            
            if let timer = scrollTimer {
                if Thread.isMainThread {
                    timer.invalidate()
                } else {
                    DispatchQueue.main.sync {
                        timer.invalidate()
                    }
                }
            }
            scrollTimer = nil
        }
    }
}

// MARK: - UIView für Gesture Recognition
protocol CursorGestureViewDelegate: AnyObject {
    func handlePanGesture(_ gesture: UIPanGestureRecognizer)
    func handleTapGesture(_ gesture: UITapGestureRecognizer)
    func handleMenuPress()
    func handlePlayPause()
}

class CursorGestureView: UIView {
    weak var delegate: CursorGestureViewDelegate?
    
    private var panGesture: UIPanGestureRecognizer!
    private var tapGesture: UITapGestureRecognizer!
    private var gameController: GCController?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGestures()
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            setupGameController()
        } else {
            teardownGameController()
        }
    }
    
    private func setupGestures() {
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirect.rawValue)]
        addGestureRecognizer(panGesture)
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapGesture.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirect.rawValue)]
        addGestureRecognizer(tapGesture)
        
        isUserInteractionEnabled = true
    }
    
    private func setupGameController() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(controllerDidConnect(_:)),
            name: .GCControllerDidConnect,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(controllerDidDisconnect(_:)),
            name: .GCControllerDidDisconnect,
            object: nil
        )
        
        if let controller = GCController.controllers().first {
            setupControllerHandlers(controller)
        }
    }
    
    private func teardownGameController() {
        NotificationCenter.default.removeObserver(self, name: .GCControllerDidConnect, object: nil)
        NotificationCenter.default.removeObserver(self, name: .GCControllerDidDisconnect, object: nil)
        
        if let controller = gameController {
            controller.microGamepad?.dpad.valueChangedHandler = nil
            controller.microGamepad?.buttonA.valueChangedHandler = nil
            controller.microGamepad?.buttonMenu.valueChangedHandler = nil
            controller.extendedGamepad?.buttonA.valueChangedHandler = nil
            controller.extendedGamepad?.buttonMenu.valueChangedHandler = nil
            controller.extendedGamepad?.buttonOptions?.valueChangedHandler = nil
        }
        gameController = nil
    }
    
    @objc private func controllerDidConnect(_ notification: Notification) {
        guard let controller = notification.object as? GCController else { return }
        setupControllerHandlers(controller)
    }
    
    @objc private func controllerDidDisconnect(_ notification: Notification) {
        gameController = nil
    }
    
    private func setupControllerHandlers(_ controller: GCController) {
        gameController = controller
        
        if let microGamepad = controller.microGamepad {
            microGamepad.allowsRotation = true
            
            microGamepad.dpad.valueChangedHandler = { (dpad, xValue, yValue) in
            }
            
            microGamepad.buttonA.valueChangedHandler = { [weak self] (button, value, pressed) in
                if pressed {
                    DispatchQueue.main.async {
                        self?.delegate?.handleTapGesture(UITapGestureRecognizer())
                    }
                }
            }
            
            microGamepad.buttonMenu.valueChangedHandler = { [weak self] (button, value, pressed) in
                if pressed {
                    DispatchQueue.main.async {
                        self?.delegate?.handleMenuPress()
                    }
                }
            }
        }
        
        if let extendedGamepad = controller.extendedGamepad {
            extendedGamepad.buttonA.valueChangedHandler = { [weak self] (button, value, pressed) in
                if pressed {
                    DispatchQueue.main.async {
                        self?.delegate?.handleTapGesture(UITapGestureRecognizer())
                    }
                }
            }
            
            extendedGamepad.buttonMenu.valueChangedHandler = { [weak self] (button, value, pressed) in
                if pressed {
                    DispatchQueue.main.async {
                        self?.delegate?.handleMenuPress()
                    }
                }
            }
            
            if let playPauseButton = extendedGamepad.buttonOptions {
                playPauseButton.valueChangedHandler = { [weak self] (button, value, pressed) in
                    if pressed {
                        DispatchQueue.main.async {
                            self?.delegate?.handlePlayPause()
                        }
                    }
                }
            }
        }
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        delegate?.handlePanGesture(gesture)
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        if gesture.state == .ended {
            delegate?.handleTapGesture(gesture)
        }
    }
    
    override var canBecomeFocused: Bool {
        return true
    }
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            if press.type == .select {
                delegate?.handleTapGesture(UITapGestureRecognizer())
            } else if press.type == .playPause {
                delegate?.handlePlayPause()
            }
        }
        super.pressesEnded(presses, with: event)
    }
    
    deinit {
        teardownGameController()
    }
}

// MARK: - SwiftUI Integration Helper
struct CursorGestureModifier: ViewModifier {
    let cursorManager: CursorPositionManager
    let screenSize: CGSize
    let onTap: () -> Void
    let onMenuPress: () -> Void
    let onPlayPause: () -> Void
    let onScroll: ((ScrollDirection) -> Void)?
    
    func body(content: Content) -> some View {
        content
            .background(
                TVOSCursorGestureHandler(
                    cursorManager: cursorManager,
                    screenSize: screenSize,
                    onTap: onTap,
                    onMenuPress: onMenuPress,
                    onPlayPause: onPlayPause,
                    onScroll: onScroll
                )
            )
    }
}

extension View {
    func cursorGestureHandler(
        cursorManager: CursorPositionManager,
        screenSize: CGSize,
        onTap: @escaping () -> Void,
        onMenuPress: @escaping () -> Void = {},
        onPlayPause: @escaping () -> Void = {},
        onScroll: ((ScrollDirection) -> Void)? = nil
    ) -> some View {
        modifier(CursorGestureModifier(
            cursorManager: cursorManager,
            screenSize: screenSize,
            onTap: onTap,
            onMenuPress: onMenuPress,
            onPlayPause: onPlayPause,
            onScroll: onScroll
        ))
    }
}
