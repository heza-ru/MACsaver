import AppKit

enum Constants {
    static let radius: CGFloat = 100
}

class AppController {
    // MARK: - Init

    init() {
        ballViewController.delegate = self
        setupClickWindow()
    }

    // MARK: - Mode management

    private var currentMode: AppMode?
    private let modePicker = ModePickerWindowController()

    func dockIconClicked() {
        guard let screen = NSScreen.main else { return }

        if currentMode != nil {
            dismissCurrentMode(screen: screen)
            return
        }

        if modePicker.isShowing {
            modePicker.dismiss()
            return
        }

        modePicker.onSelect = { [weak self] mode in
            self?.modePicker.dismiss()
            self?.launch(mode: mode, screen: screen)
        }
        modePicker.show(near: screen.inferredRectOfHoveredDockIcon)
    }

    private func launch(mode: AppMode, screen: NSScreen) {
        currentMode = mode
        switch mode {
        case .ball:
            launchBall(screen: screen, cursorGravityEnabled: true, logoStyle: .ball)
        case .dvd:
            launchDVD()
        case .freeBall:
            launchBall(screen: screen, cursorGravityEnabled: false, logoStyle: .ball)
        case .freeDVD:
            launchBall(screen: screen, cursorGravityEnabled: false, logoStyle: .dvd)
        }
        showPutBackIcon = true
    }

    private func dismissCurrentMode(screen: NSScreen) {
        switch currentMode {
        case .ball, .freeBall, .freeDVD:
            dismissBall(screen: screen)
        case .dvd:
            dismissDVD()
        case nil:
            break
        }
        currentMode = nil
        showPutBackIcon = false
    }

    // MARK: - Ball / Free modes

    private func launchBall(screen: NSScreen, cursorGravityEnabled: Bool, logoStyle: Ball.LogoStyle) {
        _ = ballViewController.view
        ballViewController.cursorGravityEnabled = cursorGravityEnabled
        ballViewController.logoStyle = logoStyle
        ballViewController.animateBallFromRect(screen.inferredRectOfHoveredDockIcon)

        ballWindowController.window!.setIsVisible(true)
        clickWindow.setIsVisible(true)
        ballViewController.sceneView.isPaused = false
        updateClickWindowPosition()
    }

    private func dismissBall(screen: NSScreen) {
        ballViewController.animatePutBack(rect: screen.inferredRectOfHoveredDockIcon) {
            self.ballWindowController.window!.setIsVisible(false)
            self.clickWindow.setIsVisible(false)
            self.ballViewController.sceneView.isPaused = true
            self.ballViewController.cursorGravityEnabled = false
        }
    }

    // MARK: - DVD Screensaver mode

    private lazy var dvdWindowController: DVDWindowController = {
        let vc = DVDViewController()
        return DVDWindowController(dvdViewController: vc)
    }()

    private func launchDVD() {
        if let screen = NSScreen.main {
            dvdWindowController.window?.setFrame(screen.frame, display: false)
        }
        dvdWindowController.window?.setIsVisible(true)
        dvdWindowController.dvdViewController.startScreensaver()
    }

    private func dismissDVD() {
        dvdWindowController.dvdViewController.stop()
        dvdWindowController.window?.setIsVisible(false)
    }

    // MARK: - Click window setup

    private func setupClickWindow() {
        let catcher = MouseCatcherView()
        clickWindow.contentView = catcher
        catcher.frame = CGRect(x: 0, y: 0, width: Constants.radius * 2, height: Constants.radius * 2)
        catcher.wantsLayer = true
        catcher.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.01).cgColor
        catcher.layer?.cornerRadius = Constants.radius

        catcher.onMouseDown = { [weak self] in self?.ballViewController.onMouseDown() }
        catcher.onMouseDrag = { [weak self] in self?.ballViewController.onMouseDrag() }
        catcher.onMouseUp = { [weak self] in self?.ballViewController.onMouseUp() }
        catcher.onScroll = { [weak self] in self?.ballViewController.onScroll(event: $0) }
    }

    // MARK: - Windows

    fileprivate let ballWindowController = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "Main") as! BallWindowController
    fileprivate var ballViewController: BallViewController {
        ballWindowController.window!.contentViewController as! BallViewController
    }

    private lazy var clickWindow: NSWindow = {
        let clickWindow = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: Constants.radius * 2, height: Constants.radius * 2),
            styleMask: [],
            backing: .buffered,
            defer: false
        )
        clickWindow.isReleasedWhenClosed = false
        clickWindow.level = .screenSaver
        clickWindow.backgroundColor = NSColor.clear
        return clickWindow
    }()

    // MARK: - Dock icon

    private var showPutBackIcon = false {
        didSet {
            if showPutBackIcon {
                NSApp.dockTile.contentView = putBackDockView
            } else {
                NSApp.dockTile.contentView = nil
            }
            NSApp.dockTile.display()
        }
    }
    private let putBackDockView = NSImageView(image: NSImage(named: "PutBack")!)
}

extension AppController: BallViewControllerDelegate {
    func ballViewController(_ vc: BallViewController, ballDidMoveToPosition pos: CGRect) {
        updateClickWindowPosition()
    }

    fileprivate func updateClickWindowPosition() {
        guard currentMode != nil, var rect = ballViewController.targetMouseCatcherRect else { return }
        let rounding: CGFloat = 10
        rect.origin.x = round(rect.minX / rounding) * rounding
        rect.origin.y = round(rect.minY / rounding) * rounding
        guard let window = self.ballWindowController.window, let screen = window.screen else { return }
        rect = rect.byConstraining(withinBounds: screen.frame)
        clickWindow.setFrame(rect, display: false)
    }
}
