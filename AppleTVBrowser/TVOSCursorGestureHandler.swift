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
        
        // Cursor movement settings
        private let sensitivity: CGFloat = 3.0
        private let acceleration: CGFloat = 1.5
        private let deadZone: CGFloat = 0.1
        
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
            let translation = gesture.translation(in: gesture.view)
            let velocity = gesture.velocity(in: gesture.view)
            
            // Calculate movement with acceleration based on velocity
            let speed = sqrt(velocity.x * velocity.x + velocity.y * velocity.y)
            let accelerationFactor = max(1.0, min(acceleration, speed / 1000.0))
            
            // Apply dead zone
            var deltaX = translation.x * sensitivity * accelerationFactor
            var deltaY = translation.y * sensitivity * accelerationFactor
            
            if abs(deltaX) < deadZone { deltaX = 0 }
            if abs(deltaY) < deadZone { deltaY = 0 }
            
            // Update cursor position with bounds checking
            let newPosition = CGPoint(
                x: clamp(cursorPosition.x + deltaX, min: 25, max: screenSize.width - 25),
                y: clamp(cursorPosition.y + deltaY, min: 25, max: screenSize.height - 25)
            )
            
            cursorPosition = newPosition
            
            // Reset gesture translation for continuous movement
            gesture.setTranslation(.zero, in: gesture.view)
        }
        
        func handleTapGesture(_ gesture: UITapGestureRecognizer) {
            print("🔥 Coordinator handleTapGesture aufgerufen!")
            onTap()
        }
        
        func handleMenuPress() {
            onMenuPress()
        }
        
        func handlePlayPause() {
            onPlayPause()
        }
        
        private func clamp(_ value: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
            return Swift.max(min, Swift.min(max, value))
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
        print("🎮 Gesture setup wird initialisiert...")
        
        // Pan gesture for cursor movement (Touchpad swipe)
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirect.rawValue)]
        // maximumNumberOfTouches ist in tvOS nicht verfügbar
        addGestureRecognizer(panGesture)
        print("🎮 Pan Gesture hinzugefügt")
        
        // Tap gesture for clicking (Touchpad press)
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapGesture.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirect.rawValue)]
        // Entferne allowedPressTypes - kann Probleme verursachen
        // tapGesture.allowedPressTypes = [NSNumber(value: UIPress.PressType.select.rawValue)]
        addGestureRecognizer(tapGesture)
        print("🎮 Tap Gesture hinzugefügt")
        
        // Enable user interaction
        isUserInteractionEnabled = true
        print("🎮 User Interaction aktiviert")
        print("🎮 Gesture Setup abgeschlossen")
    }
    
    private func setupGameController() {
        // Listen for game controller connections
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
        
        // Setup if controller is already connected
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
        
        // Handle Siri Remote microGamepad
        if let microGamepad = controller.microGamepad {
            microGamepad.allowsRotation = true
            
            // Touchpad for cursor movement
            microGamepad.dpad.valueChangedHandler = { (dpad, xValue, yValue) in
                // This will be handled by pan gesture instead
            }
            
            // A button for click
            microGamepad.buttonA.valueChangedHandler = { [weak self] (button, value, pressed) in
                if pressed {
                    self?.delegate?.handleTapGesture(UITapGestureRecognizer())
                }
            }
            
            // Menu button
            microGamepad.buttonMenu.valueChangedHandler = { [weak self] (button, value, pressed) in
                if pressed {
                    self?.delegate?.handleMenuPress()
                }
            }
        }
        
        // Handle extended gamepad if available
        if let extendedGamepad = controller.extendedGamepad {
            extendedGamepad.buttonA.valueChangedHandler = { [weak self] (button, value, pressed) in
                if pressed {
                    self?.delegate?.handleTapGesture(UITapGestureRecognizer())
                }
            }
            
            extendedGamepad.buttonMenu.valueChangedHandler = { [weak self] (button, value, pressed) in
                if pressed {
                    self?.delegate?.handleMenuPress()
                }
            }
            
            // Play/Pause button für Extended Gamepad
            if let playPauseButton = extendedGamepad.buttonOptions {
                playPauseButton.valueChangedHandler = { [weak self] (button, value, pressed) in
                    if pressed {
                        self?.delegate?.handlePlayPause()
                    }
                }
            }
        }
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        print("🎮 Pan Gesture erkannt: \(gesture.state)")
        delegate?.handlePanGesture(gesture)
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        print("🔥 TAP GESTURE ERKANNT! State: \(gesture.state)")
        if gesture.state == .ended {
            print("🔥 Tap gesture beendet - delegate wird aufgerufen")
            delegate?.handleTapGesture(gesture)
        }
    }
    
    override var canBecomeFocused: Bool {
        print("🎯 canBecomeFocused aufgerufen: true")
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("🎮 touchesBegan: \(touches.count) touches")
        super.touchesBegan(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("🎮 touchesEnded: \(touches.count) touches")
        super.touchesEnded(touches, with: event)
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        print("🎮 pressesBegan: \(presses.count) presses")
        for press in presses {
            print("🎮 Press Type: \(press.type.rawValue)")
        }
        super.pressesBegan(presses, with: event)
    }
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        print("🎮 pressesEnded: \(presses.count) presses")
        for press in presses {
            print("🎮 Press Type: \(press.type.rawValue)")
            // Direkte Behandlung des Select-Buttons
            if press.type == .select {
                print("🔥 SELECT BUTTON GEDRÜCKT - direkter Tap!")
                delegate?.handleTapGesture(UITapGestureRecognizer())
            } else if press.type == .playPause {
                print("🔥 PLAY/PAUSE BUTTON GEDRÜCKT!")
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
    
    func body(content: Content) -> some View {
        content
            .background(
                TVOSCursorGestureHandler(
                    cursorPosition: $cursorPosition,
                    screenSize: screenSize,
                    onTap: onTap,
                    onMenuPress: onMenuPress,
                    onPlayPause: onPlayPause
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
        onPlayPause: @escaping () -> Void = {}
    ) -> some View {
        modifier(CursorGestureModifier(
            cursorPosition: cursorPosition,
            screenSize: screenSize,
            onTap: onTap,
            onMenuPress: onMenuPress,
            onPlayPause: onPlayPause
        ))
    }
}
