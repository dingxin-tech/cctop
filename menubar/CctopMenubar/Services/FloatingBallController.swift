import AppKit
import SwiftUI

@MainActor
class FloatingBallController {
    private static let collapsedWidth: CGFloat = 80
    private static let collapsedHeight: CGFloat = 26
    private static let expandedWidth: CGFloat = 240
    private static let expandedHeight: CGFloat = 72
    private static let collapseDelay: TimeInterval = 5.0
    private static let positionKey = "floatingBallPositionX"
    private static let animationDuration: TimeInterval = 0.3

    private var panel: FloatingBallPanel?
    private var hostingView: NSHostingView<FloatingBallView>?
    private(set) var lastCounts = StatusCounts.zero
    private(set) var currentToast: ToastEvent?
    private var collapseWork: DispatchWorkItem?

    var pillFrame: NSRect? {
        guard let panel, panel.isVisible else { return nil }
        return panel.frame
    }

    func show(on screen: NSScreen, counts: StatusCounts) {
        let xPos = loadPosition() ?? (screen.frame.midX - Self.collapsedWidth / 2)
        let yPos = screen.visibleFrame.maxY - Self.collapsedHeight
        let frame = NSRect(
            x: xPos, y: yPos,
            width: Self.collapsedWidth, height: Self.collapsedHeight
        )

        if let panel {
            if counts != lastCounts {
                updateRootView(counts: counts, toast: currentToast)
                lastCounts = counts
            }
            panel.setFrame(frame, display: true)
            if !panel.isVisible { panel.orderFrontRegardless() }
            return
        }

        let view = FloatingBallView(
            counts: counts, toast: nil,
            themeId: ThemeManager.shared.themeId
        )
        let hosting = NSHostingView(rootView: view)
        hosting.autoresizingMask = [.width, .height]

        let newPanel = FloatingBallPanel(
            contentRect: .zero, styleMask: [],
            backing: .buffered, defer: false
        )
        newPanel.contentView = hosting
        newPanel.ballDelegate = self
        newPanel.setFrame(frame, display: true)
        newPanel.orderFrontRegardless()

        self.panel = newPanel
        self.hostingView = hosting
        lastCounts = counts
    }

    func update(counts: StatusCounts) {
        lastCounts = counts
        updateRootView(counts: counts, toast: currentToast)
    }

    func showToast(_ event: ToastEvent) {
        collapseWork?.cancel()
        currentToast = event
        panel?.hasActiveToast = true

        updateRootView(counts: lastCounts, toast: event)
        animateToSize(expanded: true)

        let work = DispatchWorkItem { [weak self] in
            self?.collapseToast()
        }
        collapseWork = work
        DispatchQueue.main.asyncAfter(
            deadline: .now() + Self.collapseDelay, execute: work
        )
    }

    func collapseToast() {
        collapseWork?.cancel()
        collapseWork = nil
        currentToast = nil
        panel?.hasActiveToast = false

        updateRootView(counts: lastCounts, toast: nil)
        animateToSize(expanded: false)
    }

    func tearDown() {
        collapseWork?.cancel()
        panel?.orderOut(nil)
        panel?.contentView = nil
        panel = nil
        hostingView = nil
    }

    func repositionOnScreen(_ screen: NSScreen) {
        guard let panel else { return }
        let xPos = loadPosition() ?? (screen.frame.midX - Self.collapsedWidth / 2)
        let yPos = screen.visibleFrame.maxY - Self.collapsedHeight
        let clampedX = clampX(xPos, on: screen)
        let width = currentToast != nil ? Self.expandedWidth : Self.collapsedWidth
        let height = currentToast != nil ? Self.expandedHeight : Self.collapsedHeight
        panel.setFrame(
            NSRect(x: clampedX, y: yPos, width: width, height: height),
            display: true
        )
    }

    // MARK: - Position Persistence

    func handleDrag(to screenX: CGFloat) {
        savePosition(screenX)
    }

    private func savePosition(_ x: CGFloat) {
        UserDefaults.standard.set(Double(x), forKey: Self.positionKey)
    }

    private func loadPosition() -> CGFloat? {
        let value = UserDefaults.standard.double(forKey: Self.positionKey)
        return value == 0 ? nil : CGFloat(value)
    }

    private func clampX(_ x: CGFloat, on screen: NSScreen) -> CGFloat {
        let width = currentToast != nil ? Self.expandedWidth : Self.collapsedWidth
        let minX = screen.visibleFrame.minX
        let maxX = screen.visibleFrame.maxX - width
        return min(max(x, minX), maxX)
    }

    // MARK: - Private

    private func updateRootView(counts: StatusCounts, toast: ToastEvent?) {
        hostingView?.rootView = FloatingBallView(
            counts: counts, toast: toast,
            themeId: ThemeManager.shared.themeId
        )
    }

    private func animateToSize(expanded: Bool) {
        guard let panel else { return }
        let targetWidth = expanded ? Self.expandedWidth : Self.collapsedWidth
        let targetHeight = expanded ? Self.expandedHeight : Self.collapsedHeight
        let screen = panel.screen ?? NSScreen.main
        let yPos = screen.map { $0.visibleFrame.maxY - targetHeight }
            ?? panel.frame.origin.y

        let newFrame = NSRect(
            x: panel.frame.origin.x,
            y: yPos,
            width: targetWidth,
            height: targetHeight
        )

        NSAnimationContext.runAnimationGroup { context in
            context.duration = Self.animationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(newFrame, display: true)
        }
    }
}

// MARK: - FloatingBallPanelDelegate

extension FloatingBallController: FloatingBallPanelDelegate {
    func panelDidDrag(to screenX: CGFloat) {
        handleDrag(to: screenX)
    }

    func panelWasClicked(hasToast: Bool) {
        if hasToast {
            if let toast = currentToast {
                NotificationCenter.default.post(
                    name: .floatingBallToastClicked,
                    object: nil,
                    userInfo: ["sessionId": toast.sessionId]
                )
            }
            collapseToast()
        } else {
            NotificationCenter.default.post(
                name: .floatingBallClicked, object: nil
            )
        }
    }
}
