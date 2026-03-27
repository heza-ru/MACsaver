import AppKit
import SwiftUI

// MARK: - Window Controller

class ModePickerWindowController: NSObject {
    private(set) var isShowing = false
    var onSelect: ((AppMode) -> Void)?

    private var window: NSPanel?
    private var outsideClickMonitor: Any?

    func show(near dockRect: CGRect) {
        guard !isShowing else { return }
        isShowing = true

        let view = ModePickerView { [weak self] mode in
            self?.onSelect?(mode)
        }
        let hostVC = NSHostingController(rootView: view)

        let panelWidth: CGFloat = 500
        let panelHeight: CGFloat = 230

        var origin = CGPoint(x: 0, y: 0)
        if let screen = NSScreen.main {
            origin.x = screen.frame.midX - panelWidth / 2
            // Position above dock area
            origin.y = min(dockRect.maxY + 20, screen.frame.height * 0.4)
        }

        let panel = NSPanel(
            contentRect: CGRect(x: origin.x, y: origin.y, width: panelWidth, height: panelHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentViewController = hostVC
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.level = .floating
        panel.isMovable = false
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
        panel.orderFront(nil)
        self.window = panel

        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.dismiss()
        }
    }

    func dismiss() {
        guard isShowing else { return }
        isShowing = false
        window?.orderOut(nil)
        window = nil
        if let monitor = outsideClickMonitor {
            NSEvent.removeMonitor(monitor)
            outsideClickMonitor = nil
        }
    }
}

// MARK: - SwiftUI Views

struct ModePickerView: View {
    @State private var showFreeSubpicker = false
    var onSelect: (AppMode) -> Void

    var body: some View {
        ZStack {
            if showFreeSubpicker {
                FreeSubpickerView(
                    onSelect: onSelect,
                    onBack: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showFreeSubpicker = false
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            } else {
                MainPickerView(
                    onBall: { onSelect(.ball) },
                    onDVD: { onSelect(.dvd) },
                    onFree: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showFreeSubpicker = true
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .frame(width: 500, height: 230)
        .background(Color(nsColor: NSColor(white: 0.1, alpha: 0.97)))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.5), radius: 40, y: 10)
    }
}

struct MainPickerView: View {
    var onBall: () -> Void
    var onDVD: () -> Void
    var onFree: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Text("Choose a Mode")
                .font(.title3.bold())
                .foregroundColor(.white)

            HStack(spacing: 14) {
                ModeCard(icon: "🏀", title: "Ball", description: "Bouncing ball with\ncursor gravity", action: onBall)
                ModeCard(icon: "📀", title: "DVD", description: "Classic bouncing\nscreensaver", action: onDVD)
                ModeCard(icon: "🎮", title: "Free", description: "Play with ball\nor DVD logo", action: onFree)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
    }
}

struct FreeSubpickerView: View {
    var onSelect: (AppMode) -> Void
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                            .font(.subheadline.bold())
                        Text("Back")
                            .font(.subheadline)
                    }
                    .foregroundColor(.white.opacity(0.65))
                }
                .buttonStyle(.plain)

                Spacer()

                Text("Free Mode")
                    .font(.title3.bold())
                    .foregroundColor(.white)

                Spacer()
                    .frame(width: 56)
            }
            .padding(.horizontal, 28)

            HStack(spacing: 14) {
                ModeCard(icon: "🏀", title: "Ball", description: "Interactive ball,\nno gravity limits") {
                    onSelect(.freeBall)
                }
                ModeCard(icon: "📀", title: "DVD Logo", description: "Interactive logo,\nplay around") {
                    onSelect(.freeDVD)
                }
            }
        }
        .padding(.bottom, 22)
    }
}

struct ModeCard: View {
    let icon: String
    let title: String
    let description: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Text(icon)
                    .font(.system(size: 34))
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            .frame(width: 140, height: 126)
            .background(isHovered ? Color.white.opacity(0.14) : Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        isHovered ? Color.white.opacity(0.25) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .scaleEffect(isHovered ? 1.04 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isHovered)
    }
}
