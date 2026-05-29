import SwiftUI

struct AlbumArtBackground: View {
    let artwork: UIImage?
    let phase: TimerPhase
    let isRunning: Bool

    @State private var animateGradient = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let artwork {
                    Image(uiImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                }

                overlayGradient
                    .frame(width: geometry.size.width, height: geometry.size.height)

                if isRunning {
                    softBlurEffect
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
        }
        .ignoresSafeArea()
    }

    private var overlayGradient: some View {
        LinearGradient(
            colors: [
                phaseBackgroundColor.opacity(0.6),
                phaseBackgroundColor.opacity(0.4),
                .black.opacity(0.7)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var softBlurEffect: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .opacity(0.3)
    }

    private var phaseBackgroundColor: Color {
        switch phase {
        case .work: .orange
        case .rest: .teal
        case .warmup: .blue
        case .cooldown: .indigo
        case .complete: .green
        case .idle: .black
        }
    }
}
