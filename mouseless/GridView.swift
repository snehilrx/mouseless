import AppKit

class GridView: NSView {

    var region: Region? {
        didSet { needsDisplay = true }
    }

    var showHelp: Bool = false {
        didSet { needsDisplay = true }
    }

    var isShiftPressed: Bool = false {
        didSet { needsDisplay = true }
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let region = region else { return }

        // Draw Status (Target Info)
        drawStatusHUD()

        // Draw Mode Indicator (Top Right)/**/
        drawModeIndicator()

        if isShiftPressed {
            // When Shift is pressed, show window snapping hints
            drawWindowHintsFixed()
        } else {
            // Standard Grid Drawing
            let color = NSColor.systemBlue

            // Check if we are in "Nudge Mode" (too small to subdivide)
            let threshold: CGFloat = 60.0
            let isTooSmall = region.width <= threshold || region.height <= threshold

            if isTooSmall {
                let border = NSBezierPath(rect: region.rect)
                border.lineWidth = 3.0
                NSColor.systemOrange.setStroke()
                border.stroke()
            } else {
                let cw = region.width / 2
                let ch = region.height / 2

                // Background Dimming (Outer area)
                NSColor.black.withAlphaComponent(0.25).setFill()
                let outerPath = NSBezierPath(rect: self.bounds)
                outerPath.append(NSBezierPath(rect: region.rect).reversed)
                outerPath.fill()

                let path = NSBezierPath()
                let vx = region.x + cw
                path.move(to: CGPoint(x: vx, y: region.y))
                path.line(to: CGPoint(x: vx, y: region.y + region.height))
                let hy = region.y + ch
                path.move(to: CGPoint(x: region.x, y: hy))
                path.line(to: CGPoint(x: region.x + region.width, y: hy))

                // Grid lines
                path.lineWidth = 1.0
                color.withAlphaComponent(0.8).setStroke()
                path.stroke()

                let border = NSBezierPath(rect: region.rect)
                border.lineWidth = 2.0
                color.setStroke()
                border.stroke()

                // Subtle center crosshair
                drawCrosshair(at: CGPoint(x: region.x + cw, y: region.y + ch), color: color)

                drawCellHints(in: region, cw: cw, ch: ch)
            }
        }

        if showHelp {
            drawHelpOverlay()
        }
    }

    private func drawCrosshair(at point: CGPoint, color: NSColor) {
        let size: CGFloat = 10
        let path = NSBezierPath()
        path.move(to: CGPoint(x: point.x - size, y: point.y))
        path.line(to: CGPoint(x: point.x + size, y: point.y))
        path.move(to: CGPoint(x: point.x, y: point.y - size))
        path.line(to: CGPoint(x: point.x, y: point.y + size))
        path.lineWidth = 1.5
        color.withAlphaComponent(0.5).setStroke()
        path.stroke()

        let dot = NSBezierPath(ovalIn: NSRect(x: point.x - 2, y: point.y - 2, width: 4, height: 4))
        color.setFill()
        dot.fill()
    }

    private func drawModeIndicator() {
        let modeText = isShiftPressed ? "SNAP MODE" : "GRID NAV"
        let modeColor = isShiftPressed ? NSColor.systemOrange : NSColor.systemBlue

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .black),
            .foregroundColor: NSColor.white
        ]

        let size = modeText.size(withAttributes: attrs)
        let rect = NSRect(x: self.bounds.width - size.width - 40, y: self.bounds.height - 60, width: size.width + 20, height: 24)

        modeColor.withAlphaComponent(0.9).setFill()
        NSBezierPath(roundedRect: rect, xRadius: 6, yRadius: 6).fill()

        modeText.draw(at: CGPoint(x: rect.midX - size.width/2, y: rect.midY - size.height/2), withAttributes: attrs)
    }

    private func drawStatusHUD() {
        let text: String
        let color: NSColor

        if let snap = WindowManager.shared.currentSnapshot {
            text = "Target: \(snap.appName ?? "Window")"
            color = NSColor.systemBlue
        } else {
            text = "Searching for windows..."
            color = NSColor.gray
        }

        let font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.white
        ]

        let size = text.size(withAttributes: attributes)
        let rect = NSRect(x: (self.bounds.width - size.width - 32) / 2, y: 60, width: size.width + 32, height: 36)

        NSColor.black.withAlphaComponent(0.7).setFill()
        let bgPath = NSBezierPath(roundedRect: rect, xRadius: 18, yRadius: 18)
        bgPath.fill()

        color.withAlphaComponent(0.5).setStroke()
        bgPath.lineWidth = 1.5
        bgPath.stroke()

        text.draw(at: CGPoint(x: rect.midX - size.width/2, y: rect.midY - size.height/2 - 1), withAttributes: attributes)
    }

    private func drawWindowHintsFixed() {
        let boxWidth: CGFloat = 220
        let hints: [(key: String, label: String)] = [
            ("W", "Maximize"), ("S", "Center"),
            ("A", "Left Half"), ("D", "Right Half"),
            ("Q/E", "Top Corners"), ("Z/X", "Bottom Corners")
        ]

        let boxHeight = CGFloat(hints.count) * 30 + 20
        let boxRect = NSRect(x: (self.bounds.width - boxWidth) / 2, y: (self.bounds.height - boxHeight) / 2, width: boxWidth, height: boxHeight)

        NSColor.black.withAlphaComponent(0.85).setFill()
        NSBezierPath(roundedRect: boxRect, xRadius: 12, yRadius: 12).fill()

        for (index, hint) in hints.enumerated() {
            let y = boxRect.maxY - 40 - CGFloat(index) * 30
            drawHintLine(key: hint.key, label: hint.label, at: CGPoint(x: boxRect.minX + 20, y: y))
        }
    }

    private func drawHintLine(key: String, label: String, at point: CGPoint) {
        let keyAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 13, weight: .bold), .foregroundColor: NSColor.systemOrange]
        let labelAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 13), .foregroundColor: NSColor.white]
        key.draw(at: point, withAttributes: keyAttrs)
        label.draw(at: CGPoint(x: point.x + 60, y: point.y), withAttributes: labelAttrs)
    }

    private func drawCellHints(in region: Region, cw: CGFloat, ch: CGFloat) {
        let hints = ["W", "D", "A", "S"]
        for i in 1...4 {
            let row = (i <= 2) ? 1 : 0
            let col = (i % 2 == 1) ? 0 : 1
            let x = region.x + CGFloat(col) * cw
            let y = region.y + CGFloat(row) * ch
            drawKeyHint(hints[i-1], at: CGPoint(x: x + 10, y: y + ch - 30))
        }
    }

    private func drawKeyHint(_ key: String, at point: CGPoint) {
        let attributes: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 13, weight: .semibold), .foregroundColor: NSColor.white]
        let size = key.size(withAttributes: attributes)
        let rect = NSRect(x: point.x, y: point.y, width: max(24, size.width + 16), height: 24)
        NSColor.black.withAlphaComponent(0.6).setFill()
        NSBezierPath(roundedRect: rect, xRadius: 6, yRadius: 6).fill()
        key.draw(at: CGPoint(x: rect.midX - size.width/2, y: rect.midY - size.height/2), withAttributes: attributes)
    }

    private func drawCorners(in rect: NSRect, color: NSColor) {
        let l: CGFloat = 20
        let w: CGFloat = 3
        color.setStroke()

        let corners = [
            [CGPoint(x: rect.minX, y: rect.maxY - l), CGPoint(x: rect.minX, y: rect.maxY), CGPoint(x: rect.minX + l, y: rect.maxY)],
            [CGPoint(x: rect.maxX - l, y: rect.maxY), CGPoint(x: rect.maxX, y: rect.maxY), CGPoint(x: rect.maxX, y: rect.maxY - l)],
            [CGPoint(x: rect.minX, y: rect.minY + l), CGPoint(x: rect.minX, y: rect.minY), CGPoint(x: rect.minX + l, y: rect.minY)],
            [CGPoint(x: rect.maxX - l, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY + l)]
        ]

        for points in corners {
            let path = NSBezierPath()
            path.move(to: points[0])
            path.line(to: points[1])
            path.line(to: points[2])
            path.lineWidth = w
            path.lineCapStyle = .round
            path.stroke()
        }
    }

    private func drawHelpOverlay() {
        let helpText = """
        GRID CONTROLS
        W A S D    : Subdivide / Navigate
        Space      : Left Click / End Drag
        X          : Toggle Text Selection (Drag)
        F / V      : Right / Double Click
        B          : Go Back (Bigger Grid)
        R          : Reset to Full Screen
        Tab        : Switch Monitor
        H          : Toggle Help
        Esc        : Close Grid

        SNAP MODE (Hold Shift)
        W / S      : Top / Bottom Half
        A / D      : Left / Right Half
        Q / E      : Top Corners
        Z / X      : Bottom Corners
        M          : Maximize Window
        C          : Center Window
        """

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.white
        ]

        let size = helpText.size(withAttributes: attributes)
        let rect = NSRect(x: (self.bounds.width - size.width - 40) / 2, y: (self.bounds.height - size.height - 40) / 2, width: size.width + 40, height: size.height + 40)

        NSColor.black.withAlphaComponent(0.95).setFill()
        NSBezierPath(roundedRect: rect, xRadius: 12, yRadius: 12).fill()

        NSColor.systemBlue.withAlphaComponent(0.5).setStroke()
        let border = NSBezierPath(roundedRect: rect, xRadius: 12, yRadius: 12)
        border.lineWidth = 1
        border.stroke()

        helpText.draw(in: rect.insetBy(dx: 20, dy: 20), withAttributes: attributes)
    }
}
