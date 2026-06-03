import SwiftUI

struct FloatingBallView: View {
    let counts: StatusCounts
    let toast: ToastEvent?
    var themeId: String = ""

    private var isExpanded: Bool { toast != nil }

    var body: some View {
        VStack(spacing: 0) {
            pillBar
            if let toast {
                toastContent(toast)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .id(themeId)
        .background(
            RoundedRectangle(cornerRadius: isExpanded ? 14 : 12)
                .fill(Color.panelBackground.opacity(0.92))
                .shadow(color: .black.opacity(0.35), radius: 8, y: 3)
        )
        .clipShape(RoundedRectangle(cornerRadius: isExpanded ? 14 : 12))
        .overlay(
            RoundedRectangle(cornerRadius: isExpanded ? 14 : 12)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: isExpanded)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    private var pillBar: some View {
        HStack(spacing: 5) {
            FloatingBallGridIcon(highlighted: counts.needsAction > 0)
                .frame(width: 11, height: 11)

            if counts.total > 0 {
                FloatingBallStatusBar(counts: counts)
                    .frame(width: 38, height: 4)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
    }

    private func toastContent(_ toast: ToastEvent) -> some View {
        HStack(spacing: 7) {
            Circle()
                .fill(toast.status.color)
                .frame(width: 8, height: 8)
                .shadow(color: toast.status.color.opacity(0.5), radius: 3)

            VStack(alignment: .leading, spacing: 1) {
                Text(toast.projectName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(toast.message)
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.65))
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 8)
        .padding(.top, 2)
        .frame(maxWidth: 220)
    }

    private var accessibilityDescription: String {
        if let toast {
            return "\(toast.projectName): \(toast.message)"
        }
        return counts.accessibilityLabel
    }
}

// MARK: - Shared Components

struct FloatingBallGridIcon: View {
    let highlighted: Bool

    private var tint: Color {
        highlighted ? StatusColors.accent.color : .white
    }

    var body: some View {
        VStack(spacing: 1) {
            HStack(spacing: 1) {
                RoundedRectangle(cornerRadius: 0.5)
                    .fill(tint.opacity(0.85))
                RoundedRectangle(cornerRadius: 0.5)
                    .fill(tint.opacity(0.85))
            }
            HStack(spacing: 1) {
                RoundedRectangle(cornerRadius: 0.5)
                    .fill(tint.opacity(0.50))
                RoundedRectangle(cornerRadius: 0.5)
                    .fill(tint.opacity(0.45))
            }
        }
    }
}

struct FloatingBallStatusBar: View {
    let counts: StatusCounts

    var body: some View {
        GeometryReader { geo in
            let segments = counts.barSegments(forWidth: Double(geo.size.width))
            HStack(spacing: 0) {
                ForEach(
                    Array(segments.enumerated()), id: \.offset
                ) { index, seg in
                    if index == segments.count - 1 {
                        seg.color.color
                    } else {
                        seg.color.color.frame(width: geo.size.width * seg.proportion)
                    }
                }
            }
        }
        .clipShape(Capsule())
    }
}

// MARK: - Previews

#Preview("Collapsed - Mixed") {
    FloatingBallView(
        counts: StatusCounts(permission: 1, attention: 1, working: 2, idle: 1),
        toast: nil
    )
    .padding(40)
    .background(Color.gray.opacity(0.3))
}

#Preview("Collapsed - All working") {
    FloatingBallView(
        counts: StatusCounts(permission: 0, attention: 0, working: 4, idle: 0),
        toast: nil
    )
    .padding(40)
    .background(Color.gray.opacity(0.3))
}

#Preview("Collapsed - No sessions") {
    FloatingBallView(
        counts: StatusCounts(permission: 0, attention: 0, working: 0, idle: 0),
        toast: nil
    )
    .padding(40)
    .background(Color.gray.opacity(0.3))
}

#Preview("Expanded - Permission") {
    FloatingBallView(
        counts: StatusCounts(permission: 1, attention: 0, working: 2, idle: 0),
        toast: ToastEvent(
            sessionId: "123",
            projectName: "cctop",
            message: "Permission needed: Bash",
            status: .waitingPermission
        )
    )
    .padding(40)
    .background(Color.gray.opacity(0.3))
}

#Preview("Expanded - Waiting input") {
    FloatingBallView(
        counts: StatusCounts(permission: 0, attention: 1, working: 1, idle: 0),
        toast: ToastEvent(
            sessionId: "456",
            projectName: "my-project",
            message: "Waiting: \"fix the login bug in auth...\"",
            status: .waitingInput
        )
    )
    .padding(40)
    .background(Color.gray.opacity(0.3))
}
