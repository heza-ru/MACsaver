import Cocoa

// MARK: - DVDWindowController

class DVDWindowController: NSWindowController, NSWindowDelegate {
    let dvdViewController: DVDViewController

    init(dvdViewController: DVDViewController) {
        self.dvdViewController = dvdViewController
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [],
            backing: .buffered,
            defer: false
        )
        window.backgroundColor = NSColor.black
        window.isOpaque = true
        window.level = .screenSaver
        window.ignoresMouseEvents = true
        window.isReleasedWhenClosed = false
        window.contentViewController = dvdViewController
        super.init(window: window)
        window.delegate = self
    }

    required init?(coder: NSCoder) { fatalError() }

    func windowDidChangeScreen(_ notification: Notification) {
        guard let screen = window?.screen else { return }
        window?.setFrame(screen.frame, display: true)
    }
}

// MARK: - DVDViewController

class DVDViewController: NSViewController {
    private let logoView = NSImageView()
    private let logoSize = CGSize(width: 320, height: 180)

    private var pos = CGPoint.zero
    private var vel = CGPoint.zero
    private var currentHue: CGFloat = 0
    private var timer: Timer?
    private var lastTick: Date?
    private var pendingStart = false

    override func loadView() {
        let v = NSView()
        v.wantsLayer = true
        v.layer?.backgroundColor = NSColor.black.cgColor
        view = v
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        logoView.imageScaling = .scaleProportionallyUpOrDown
        logoView.wantsLayer = true

        // Load DVD logo; mark as template so contentTintColor applies
        if let img = NSImage(named: "DVD_logo") {
            let t = img.copy() as! NSImage
            t.isTemplate = true
            logoView.image = t
        } else {
            // Fallback: white "DVD" label
            logoView.image = makeFallbackImage()
        }

        view.addSubview(logoView)
        currentHue = CGFloat.random(in: 0...1)
        applyColor()
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        guard view.bounds.width > 0, pendingStart else { return }
        pendingStart = false
        beginAnimation()
    }

    // MARK: - Public

    func startScreensaver() {
        stopAnimation()
        currentHue = CGFloat.random(in: 0...1)
        applyColor()
        if view.bounds.width > 0 {
            beginAnimation()
        } else {
            pendingStart = true
        }
    }

    func stop() {
        pendingStart = false
        stopAnimation()
    }

    // MARK: - Animation

    private func beginAnimation() {
        let bounds = view.bounds
        let hw = logoSize.width / 2, hh = logoSize.height / 2

        pos = CGPoint(
            x: bounds.width  > logoSize.width  ? CGFloat.random(in: hw ..< bounds.width  - hw) : bounds.midX,
            y: bounds.height > logoSize.height ? CGFloat.random(in: hh ..< bounds.height - hh) : bounds.midY
        )

        // ~27° angle gives the satisfying DVD bounce pattern
        let speed: CGFloat = 220
        let angle: CGFloat = 0.47 + CGFloat.random(in: -0.15 ... 0.15)
        vel = CGPoint(
            x: cos(angle) * speed * (Bool.random() ? 1 : -1),
            y: sin(angle) * speed * (Bool.random() ? 1 : -1)
        )

        updateLogoFrame()
        lastTick = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1 / 60.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func stopAnimation() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard let last = lastTick else { return }
        let now = Date()
        let dt = min(CGFloat(now.timeIntervalSince(last)), 1 / 30.0)
        lastTick = now

        let bounds = view.bounds
        guard bounds.width > 0, bounds.height > 0 else { return }

        pos.x += vel.x * dt
        pos.y += vel.y * dt

        var bounced = false
        let hw = logoSize.width / 2, hh = logoSize.height / 2

        if pos.x < hw                   { pos.x = hw;                   vel.x =  abs(vel.x); bounced = true }
        if pos.x > bounds.width  - hw   { pos.x = bounds.width  - hw;   vel.x = -abs(vel.x); bounced = true }
        if pos.y < hh                   { pos.y = hh;                   vel.y =  abs(vel.y); bounced = true }
        if pos.y > bounds.height - hh   { pos.y = bounds.height - hh;   vel.y = -abs(vel.y); bounced = true }

        if bounced {
            currentHue = (currentHue + 0.16).truncatingRemainder(dividingBy: 1.0)
            applyColor()
        }

        updateLogoFrame()
    }

    private func updateLogoFrame() {
        logoView.frame = CGRect(
            x: pos.x - logoSize.width  / 2,
            y: pos.y - logoSize.height / 2,
            width:  logoSize.width,
            height: logoSize.height
        )
    }

    private func applyColor() {
        logoView.contentTintColor = NSColor(hue: currentHue, saturation: 1, brightness: 1, alpha: 1)
    }

    // Fallback when asset isn't in the bundle
    private func makeFallbackImage() -> NSImage {
        let img = NSImage(size: logoSize)
        img.lockFocus()
        NSColor.white.setFill()
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 80),
            .foregroundColor: NSColor.white
        ]
        let str = "DVD" as NSString
        let sz = str.size(withAttributes: attrs)
        str.draw(at: CGPoint(x: (logoSize.width - sz.width) / 2, y: (logoSize.height - sz.height) / 2),
                 withAttributes: attrs)
        img.unlockFocus()
        img.isTemplate = true
        return img
    }
}
