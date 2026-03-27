import SpriteKit

class Ball: SKNode {
    enum LogoStyle {
        case ball
        case dvd
    }

    let id: String

    private let imgOffsetContainer = SKNode()
    /**/ private let imgRotationContainer = SKNode()
    /****/ private let img: SKSpriteNode

    let radius: CGFloat
    private let logoStyle: LogoStyle
    private var dvdHue: CGFloat = CGFloat.random(in: 0...1)

//    let view: NSHostingView<BallView<Circle>>
    private let shadowSprite = SKSpriteNode(imageNamed: "ContactShadow")
    private let shadowContainer = SKNode() // For fading in/out

    private let squish = MomentumValue(initialValue: 1, scale: 1000, params: .init(response: 0.3, dampingRatio: 0.5))
    private let dragScale = MomentumValue(initialValue: 1, scale: 1000, params: .init(response: 0.2, dampingRatio: 0.8))

    var beingDragged = false {
        didSet(old) {
            if beingDragged != old {
                dragScale.animate(toValue: beingDragged ? 1.05 : 1, velocity: dragScale.velocity, completion: nil)
            }
        }
    }

    init(radius: CGFloat, pos: CGPoint, id: String, logoStyle: LogoStyle = .ball) {
        self.id = id
        self.radius = radius
        self.logoStyle = logoStyle
        switch logoStyle {
        case .ball:
            img = SKSpriteNode(imageNamed: "Ball")
        case .dvd:
            img = NSImage(named: "DVD_logo") != nil
                ? SKSpriteNode(imageNamed: "DVD_logo")
                : SKSpriteNode(color: .white, size: CGSize(width: radius * 3, height: radius * 1.7))
        }
        super.init()
        self.position = pos

        let body = SKPhysicsBody(circleOfRadius: radius)
        body.isDynamic = true
        body.restitution = 0.6
        body.friction = 0
        body.allowsRotation = false
        body.usesPreciseCollisionDetection = true
        body.contactTestBitMask = 1
        self.physicsBody = body

        addChild(shadowContainer)
        shadowContainer.addChild(shadowSprite)
        let shadowWidth: CGFloat = radius * 4
        shadowSprite.size = CGSize(width: shadowWidth, height: 0.564 * shadowWidth)
        shadowSprite.alpha = 0
        shadowContainer.alpha = 0

        addChild(imgOffsetContainer)
        imgOffsetContainer.addChild(imgRotationContainer)

        switch logoStyle {
        case .ball:
            img.size = CGSize(width: radius * 2, height: radius * 2)
        case .dvd:
            img.size = CGSize(width: radius * 3, height: radius * 1.7)
            applyDVDColor()
        }
        imgRotationContainer.addChild(img)
//        img.alpha = 0.01
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var rect: CGRect {
        CGRect(origin: .init(x: position.x - radius, y: position.y - radius), size: .init(width: radius * 2, height: radius * 2))
    }

    func animateShadow(visible: Bool, duration: TimeInterval) {
        if visible {
            shadowContainer.run(SKAction.fadeIn(withDuration: duration))
        } else {
            shadowContainer.run(SKAction.fadeOut(withDuration: duration))
        }
    }

    func update() {
        shadowSprite.position = CGPoint(x: 0, y: radius * 0.3 - position.y)
        let distFromBottom = position.y - radius
        shadowSprite.alpha = remap(x: distFromBottom, domainStart: 0, domainEnd: 200, rangeStart: 1, rangeEnd: 0)
        imgRotationContainer.xScale = squish.value

        let yDelta = -(1 - imgRotationContainer.xScale) * radius / 2
        imgOffsetContainer.position = .init(x: 0, y: yDelta)

        img.setScale(dragScale.value)
    }

    func didCollide(strength: Double, normal: CGVector) {
        let angle = atan2(normal.dy, normal.dx)
        imgRotationContainer.zRotation = angle
        img.zRotation = -angle

        if logoStyle == .dvd {
            dvdHue += 0.16
            if dvdHue >= 1.0 { dvdHue -= 1.0 }
            applyDVDColor()
        }
    }

    private func applyDVDColor() {
        let color = NSColor(hue: dvdHue, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        img.color = color
        img.colorBlendFactor = 0.85
    }
}
