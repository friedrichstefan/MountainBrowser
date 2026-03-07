//
//  TVOSCursorGestureHandler.swift
//  AppleTVBrowser
//
//  Gesture Handler für tvOS Fernbedienung Cursor-Navigation
//

import SwiftUI
import GameController

struct TVOSCursorGestureHandler: UIViewRepresentable {
    @Binding var cursorPosition: CGPoint
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
        context.coordinator.updateCursorPosition($cursorPosition)
        context.coordinator.screenSize = screenSize
        context.coordinator.onTap = onTap
        context.coordinator.onMenuPress = onMenuPress
        context.coordinator.onPlayPause = onPlayPause
        context.coordinator.onScroll = onScroll
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            cursorPosition: $cursorPosition,
            screenSize: screenSize,
            onTap: onTap,
            onMenuPress: onMenuPress,
            onPlayPause: onPlayPause
        )
    }
    
    class Coordinator: NSObject, CursorGestureViewDelegate {
        @Binding var cursorPosition: CGPoint
        var screenSize: CGSize
        var onTap: () -> Void
        var onMenuPress: () -> Void
        var onPlayPause: () -> Void
        var onScroll: ((ScrollDirection) -> Void)?
        
        // Cursor-Geschwindigkeit
        private let sensitivity: CGFloat = 1.2
        private let acceleration: CGFloat = 1.2
        private let deadZone: CGFloat = 0.3
        
        // Scroll settings
        private let scrollEdgeThreshold: CGFloat = 100
        private let navigationBarHeight: CGFloat = 100
        private var scrollTimer: Timer?
        private var currentScrollSpeed: TimeInterval = 0.5
        private let minScrollInterval: TimeInterval = 0.25
        private let maxScrollInterval: TimeInterval = 0.6
        
        // Auto-Scroll am Rand
        private var isAutoScrolling = false
        private let autoScrollThreshold: CGFloat = 80
        private let swipeThreshold: CGFloat = 12.0
        
        // Variablen für Scroll-Beschleunigung
        private var lastScrollDirection: ScrollDirection?
        private var scrollVelocityAccumulator: CGFloat = 0
        private let scrollAccelerationFactor: CGFloat = 1.2
        
        // FIX: Flag um zu verhindern, dass Callbacks nach deinit feuern
        private var isInvalidated = false
        
        init(cursorPosition: Binding<CGPoint>, screenSize: CGSize, onTap: @escaping () -> Void, onMenuPress: @escaping () -> Void, onPlayPause: @escaping () -> Void) {
            self._cursorPosition = cursorPosition
            self.screenSize = screenSize
            self.onTap = onTap
            self.onMenuPress = onMenuPress
            self.onPlayPause = onPlayPause
        }
        
        func updateCursorPosition(_ binding: Binding<CGPoint>) {
            self._cursorPosition = binding
        }
        
        func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
            guard !isInvalidated else { return }
            
            let translation = gesture.translation(in: gesture.view)
            let velocity = gesture.velocity(in: gesture.view)
            
            let speed = sqrt(velocity.x * velocity.x + velocity.y * velocity.y)
            let accelerationFactor = max(1.0, min(acceleration, speed / 2000.0))
            
            var deltaX = translation.x * sensitivity * accelerationFactor
            var deltaY = translation.y * sensitivity * accelerationFactor
            
            if abs(deltaX) < deadZone { deltaX = 0 }
            if abs(deltaY) < deadZone { deltaY = 0 }
            
            // Auto-Scroll am Rand
            let currentY = cursorPosition.y
            let isNearTop = currentY <= autoScrollThreshold
            let isNearBottom = currentY >= (screenSize.height - autoScrollThreshold)
            
            if isNearTop && deltaY < -swipeThreshold {
                onScroll?(.up)
                deltaY = 0
            } else if isNearBottom && deltaY > swipeThreshold {
                onScroll?(.down)
                deltaY = 0
            }
            
            // Update cursor position with bounds checking
            let newPosition = CGPoint(
                x: clamp(cursorPosition.x + deltaX, min: 25, max: screenSize.width - 25),
                y: clamp(cursorPosition.y + deltaY, min: 25, max: screenSize.height - 25)
            )
            
            cursorPosition = newPosition
            
            // Reset gesture translation for continuous movement
            gesture.setTranslation(.zero, in: gesture.view)
            
            // Stoppe Scrolling wenn Gesture endet
            if gesture.state == .ended || gesture.state == .cancelled {
                stopScrolling()
            }
        }
        
        func handleTapGesture(_ gesture: UITapGestureRecognizer) {
            guard !isInvalidated else { return }
            
            // FIX: Immer onTap() aufrufen — der Cursor-Klick-Handler
            // in CursorModeWebView entscheidet selbst, was passiert.
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
        private func getScrollDirection() -> ScrollDirection? {
            if cursorPosition.y <= scrollEdgeThreshold {
                return .up
            } else if cursorPosition.y >= (screenSize.height - scrollEdgeThreshold) {
                return .down
            }
            return nil
        }
        
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
            
            scrollVelocityAccumulator += 0.005
            let newSpeed = max(minScrollInterval, currentScrollSpeed - scrollVelocityAccumulator * 0.01)
            
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
        
        private func clamp(_ value: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
            return Swift.max(min, Swift.min(max, value))
        }
        
        deinit {
            isInvalidated = true
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
        setupGameController()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGestures()
        setupGameController()
    }
    
    private func setupGestures() {
        // Pan gesture for cursor movement (Touchpad swipe)
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirect.rawValue)]
        addGestureRecognizer(panGesture)
        
        // Tap gesture for clicking (Touchpad press)
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
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - SwiftUI Integration Helper
struct CursorGestureModifier: ViewModifier {
    @Binding var cursorPosition: CGPoint
    let screenSize: CGSize
    let onTap: () -> Void
    let onMenuPress: () -> Void
    let onPlayPause: () -> Void
    let onScroll: ((ScrollDirection) -> Void)?
    
    func body(content: Content) -> some View {
        content
            .background(
                TVOSCursorGestureHandler(
                    cursorPosition: $cursorPosition,
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
        cursorPosition: Binding<CGPoint>,
        screenSize: CGSize,
        onTap: @escaping () -> Void,
        onMenuPress: @escaping () -> Void = {},
        onPlayPause: @escaping () -> Void = {},
        onScroll: ((ScrollDirection) -> Void)? = nil
    ) -> some View {
        modifier(CursorGestureModifier(
            cursorPosition: cursorPosition,
            screenSize: screenSize,
            onTap: onTap,
            onMenuPress: onMenuPress,
            onPlayPause: onPlayPause,
            onScroll: onScroll
        ))
    }
}
