import AppKit

@MainActor protocol FloatingBallPanelDelegate: AnyObject {
    func panelDidDrag(to screenX: CGFloat)
    func panelWasClicked(hasToast: Bool)
}

class FloatingBallPanel: NSPanel {
    weak var ballDelegate: FloatingBallPanelDelegate?
    var hasActiveToast = false

    private static let dragThreshold: CGFloat = 3

    override init(
        contentRect: NSRect,
        styleMask: NSWindow.StyleMask,
        backing: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: backing,
            defer: flag
        )
        level = .statusBar
        collectionBehavior = [
            .fullScreenAuxiliary, .stationary,
            .canJoinAllSpaces, .ignoresCycle
        ]
        isMovable = false
        hasShadow = false
        isOpaque = false
        backgroundColor = .clear
        hidesOnDeactivate = false
        animationBehavior = .none
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    override func sendEvent(_ event: NSEvent) {
        if event.type == .leftMouseDown {
            handleClickOrDrag()
            return
        }
        super.sendEvent(event)
    }

    private func handleClickOrDrag() {
        let startMouseLocation = NSEvent.mouseLocation
        let startOriginX = frame.origin.x
        let lockedY = frame.origin.y
        var didDrag = false

        while true {
            guard let event = nextEvent(
                matching: [.leftMouseDragged, .leftMouseUp],
                until: .distantFuture,
                inMode: .eventTracking,
                dequeue: true
            ) else { continue }

            if event.type == .leftMouseUp { break }

            let current = NSEvent.mouseLocation
            let deltaX = current.x - startMouseLocation.x

            if abs(deltaX) > Self.dragThreshold {
                didDrag = true
            }

            if didDrag {
                let newX = startOriginX + deltaX
                // Clamp to screen bounds
                if let screen = self.screen ?? NSScreen.main {
                    let minX = screen.visibleFrame.minX
                    let maxX = screen.visibleFrame.maxX - frame.width
                    let clampedX = min(max(newX, minX), maxX)
                    setFrameOrigin(NSPoint(x: clampedX, y: lockedY))
                } else {
                    setFrameOrigin(NSPoint(x: newX, y: lockedY))
                }
            }
        }

        if didDrag {
            ballDelegate?.panelDidDrag(to: frame.origin.x)
        } else {
            ballDelegate?.panelWasClicked(hasToast: hasActiveToast)
        }
    }
}
