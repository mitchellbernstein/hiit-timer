import SwiftUI

struct ControlButton: View {
    enum Style {
        case primary
        case secondary
        case destructive
        case skip

        var tint: Color {
            switch self {
            case .primary: .white
            case .secondary: .white.opacity(0.8)
            case .destructive: .red
            case .skip: .white.opacity(0.6)
            }
        }

        var backgroundOpacity: Double {
            switch self {
            case .primary: 0.2
            case .secondary: 0.12
            case .destructive: 0.2
            case .skip: 0.08
            }
        }
    }

    let icon: String
    let label: String
    let style: Style
    let action: () -> Void

    init(icon: String, label: String = "", style: Style = .primary, action: @escaping () -> Void) {
        self.icon = icon
        self.label = label
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .semibold))
                    .frame(height: 32)

                if !label.isEmpty {
                    Text(label)
                        .font(.system(.caption, design: .rounded, weight: .medium))
                }
            }
            .foregroundStyle(style.tint)
            .frame(maxWidth: .infinity)
            .frame(height: 76)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label.isEmpty ? icon : label)
    }
}

struct PlayPauseButton: View {
    let isRunning: Bool
    let isPaused: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isRunning && !isPaused ? "pause.fill" : "play.fill")
                .font(.system(size: 36, weight: .bold))
                .frame(width: 88, height: 88)
                .foregroundStyle(.white)
                .glassEffect(.regular.interactive().tint(isRunning && !isPaused ? .orange : .green), in: .circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isRunning && !isPaused ? "Pause" : "Start")
    }
}
