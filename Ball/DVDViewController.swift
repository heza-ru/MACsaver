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
    let scene = SKScene(size: .init(width: 200, height: 200))
    let sceneView = SKView()
    private var dvdNode: DVDNode?

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
        scene.size = view.bounds.size
        sceneView.frame = view.bounds
        scene.physicsBody = SKPhysicsBody(edgeLoopFrom: view.bounds)
        scene.physicsBody?.contactTestBitMask = 1
    }

    func startScreensaver() {
        stop()

        let logoSize = CGSize(width: 300, height: 168)
        let node = DVDNode(size: logoSize)
        dvdNode = node
        scene.addChild(node)

        let marginX = logoSize.width / 2 + 20
        let marginY = logoSize.height / 2 + 20
        let x = CGFloat.random(in: marginX...(max(marginX + 1, scene.size.width - marginX)))
        let y = CGFloat.random(in: marginY...(max(marginY + 1, scene.size.height - marginY)))
        node.position = CGPoint(x: x, y: y)

        let speed: CGFloat = 220
        let baseAngle = CGFloat.pi / 4
        let jitter = CGFloat.random(in: -0.15...0.15)
        let angle = baseAngle + jitter
        let dx = cos(angle) * speed * (Bool.random() ? 1 : -1)
        let dy = sin(angle) * speed * (Bool.random() ? 1 : -1)
        node.physicsBody?.velocity = CGVector(dx: dx, dy: dy)
    }

    func stop() {
        dvdNode?.removeFromParent()
        dvdNode = nil
    }
}

extension DVDViewController: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        dvdNode?.advanceColor()
    }
}

extension DVDViewController: SKSceneDelegate {
    func update(_ currentTime: TimeInterval, for scene: SKScene) {
        guard let body = dvdNode?.physicsBody else { return }
        let vel = body.velocity
        let currentSpeed = hypot(vel.dx, vel.dy)
        let targetSpeed: CGFloat = 220
        if currentSpeed > 0 && abs(currentSpeed - targetSpeed) > 5 {
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
        body.usesPreciseCollisionDetection = true
        body.contactTestBitMask = 1
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
