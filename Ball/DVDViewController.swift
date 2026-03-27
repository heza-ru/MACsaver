import Cocoa
import SpriteKit

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
        window.backgroundColor = NSColor.clear
        window.isOpaque = false
        window.level = .screenSaver
        window.ignoresMouseEvents = true
        window.acceptsMouseMovedEvents = false
        window.isReleasedWhenClosed = false
        window.contentViewController = dvdViewController
        super.init(window: window)
        window.delegate = self
    }

    required init?(coder: NSCoder) { fatalError() }

    func windowDidChangeScreen(_ notification: Notification) {
        updateWindowSize()
    }

    func windowDidChangeScreenProfile(_ notification: Notification) {
        updateWindowSize()
    }

    private func updateWindowSize() {
        guard let screen = window?.screen else { return }
        window?.setFrame(screen.frame, display: true)
    }
}

// MARK: - DVDViewController

class DVDViewController: NSViewController {
    let scene = SKScene(size: .init(width: 100, height: 100))
    let sceneView = SKView()
    private var dvdNode: DVDNode?

    // Deferred start: true when startScreensaver() was called before layout
    private var pendingStart = false

    override func loadView() {
        view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(sceneView)
        sceneView.presentScene(scene)
        scene.backgroundColor = NSColor.clear
        sceneView.allowsTransparency = true
        sceneView.preferredFramesPerSecond = 120
        scene.physicsWorld.gravity = .zero
        scene.physicsWorld.contactDelegate = self
        scene.delegate = self
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        let bounds = view.bounds
        guard bounds.width > 0, bounds.height > 0 else { return }

        scene.size = bounds.size
        sceneView.frame = bounds

        // Rebuild edge walls every layout pass
        let body = SKPhysicsBody(edgeLoopFrom: bounds)
        body.friction = 0
        body.restitution = 1.0
        body.contactTestBitMask = 1
        scene.physicsBody = body

        // Start screensaver now that we have real bounds
        if pendingStart {
            pendingStart = false
            launchNode()
        }
    }

    func startScreensaver() {
        stop()
        if scene.size.width > 100 {
            launchNode()
        } else {
            pendingStart = true
        }
    }

    func stop() {
        pendingStart = false
        dvdNode?.removeFromParent()
        dvdNode = nil
    }

    private func launchNode() {
        dvdNode?.removeFromParent()

        let logoSize = CGSize(width: 300, height: 168)
        let node = DVDNode(size: logoSize)
        dvdNode = node
        scene.addChild(node)

        let halfW = logoSize.width / 2
        let halfH = logoSize.height / 2
        let safeW = scene.size.width - logoSize.width
        let safeH = scene.size.height - logoSize.height
        let x = halfW + CGFloat.random(in: 0...max(1, safeW))
        let y = halfH + CGFloat.random(in: 0...max(1, safeH))
        node.position = CGPoint(x: x, y: y)

        let speed: CGFloat = 220
        let angle = CGFloat.pi / 4 + CGFloat.random(in: -0.2...0.2)
        let dx = cos(angle) * speed * (Bool.random() ? 1 : -1)
        let dy = sin(angle) * speed * (Bool.random() ? 1 : -1)
        node.physicsBody?.velocity = CGVector(dx: dx, dy: dy)
    }
}

extension DVDViewController: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        dvdNode?.advanceColor()
    }
}

extension DVDViewController: SKSceneDelegate {
    func update(_ currentTime: TimeInterval, for scene: SKScene) {
        // Keep speed perfectly constant (restitution=1 can drift slightly)
        guard let body = dvdNode?.physicsBody else { return }
        let vel = body.velocity
        let currentSpeed = hypot(vel.dx, vel.dy)
        let targetSpeed: CGFloat = 220
        guard currentSpeed > 0 else { return }
        if abs(currentSpeed - targetSpeed) > 2 {
            body.velocity = CGVector(
                dx: vel.dx / currentSpeed * targetSpeed,
                dy: vel.dy / currentSpeed * targetSpeed
            )
        }
    }
}

// MARK: - DVDNode

class DVDNode: SKNode {
    private let logoSprite: SKSpriteNode
    private var currentHue: CGFloat = CGFloat.random(in: 0...1)

    init(size: CGSize) {
        if NSImage(named: "DVD_logo") != nil {
            logoSprite = SKSpriteNode(imageNamed: "DVD_logo")
        } else {
            logoSprite = SKSpriteNode(color: .white, size: size)
        }
        logoSprite.size = size
        super.init()
        addChild(logoSprite)

        let body = SKPhysicsBody(rectangleOf: size)
        body.isDynamic = true
        body.restitution = 1.0
        body.linearDamping = 0
        body.angularDamping = 0
        body.allowsRotation = false
        body.friction = 0
        body.mass = 1
        body.usesPreciseCollisionDetection = true
        body.contactTestBitMask = 1
        body.categoryBitMask = 1
        body.collisionBitMask = 0xFFFFFFFF
        physicsBody = body

        applyColor()
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    func advanceColor() {
        currentHue += 0.16
        if currentHue >= 1.0 { currentHue -= 1.0 }
        applyColor()
    }

    private func applyColor() {
        let color = NSColor(hue: currentHue, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        logoSprite.color = color
        logoSprite.colorBlendFactor = 0.85
    }
}
