import SwiftUI

struct IntervalProgressBar: View {
    let phases: [PhaseMarker]
    let currentIndex: Int
    let overallProgress: Double

    struct PhaseMarker: Identifiable {
        let id: Int
        let phase: TimerPhase
    }

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.1))
                        .frame(height: 4)

                    Capsule()
                        .fill(.white)
                        .frame(width: geometry.size.width * overallProgress, height: 4)
                        .animation(.smooth(duration: 0.5), value: overallProgress)

                    HStack(spacing: 0) {
                        ForEach(phases) { marker in
                            Circle()
                                .fill(marker.id <= currentIndex ? .white : .white.opacity(0.2))
                                .frame(width: 8, height: 8)
                            if marker.id < phases.count {
                                Spacer().frame(minWidth: 0)
                            }
                        }
                    }
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal, 32)
    }
}
