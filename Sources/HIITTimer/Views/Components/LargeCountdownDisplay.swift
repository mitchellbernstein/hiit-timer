import SwiftUI

struct LargeCountdownDisplay: View {
    let time: String
    let phase: TimerPhase
    let currentRound: Int
    let totalRounds: Int
    let progress: Double
    let isRunning: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 4) {
            phaseLabel
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                .glassEffect(.regular.tint(phaseTint), in: .capsule)

            Text(time)
                .font(.system(size: isRunning ? 96 : 72, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .contentTransition(.numericText(countsDown: true))
                .animation(.snappy, value: time)
                .padding(.vertical, 8)

            if totalRounds > 1 {
                roundIndicator
                    .padding(.vertical, 4)
            }

            progressBar
                .padding(.horizontal, 48)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
    }

    private var phaseLabel: some View {
        Text(phase.displayName.uppercased())
            .font(.system(.headline, design: .rounded, weight: .bold))
            .foregroundStyle(.white)
            .tracking(2)
    }

    private var roundIndicator: some View {
        Text("Round \(currentRound) of \(totalRounds)")
            .font(.system(.subheadline, design: .rounded, weight: .medium))
            .foregroundStyle(.white.opacity(0.7))
    }

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.15))
                    .frame(height: 6)

                Capsule()
                    .fill(.white)
                    .frame(width: geometry.size.width * progress, height: 6)
                    .animation(.smooth(duration: 0.3), value: progress)
            }
        }
        .frame(height: 6)
    }

    private var phaseTint: Color {
        switch phase {
        case .work: .orange
        case .rest: .mint
        case .warmup: .blue
        case .cooldown: .indigo
        case .complete: .green
        case .idle: .secondary
        }
    }
}
