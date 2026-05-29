import SwiftUI

@available(iOS 26.1, *)
struct ContentView: View {
    @Environment(MusicService.self) private var music
    @Environment(TimerEngine.self) private var timer

    @State private var showPresets = false
    @State private var showMusic = false

    var body: some View {
        ZStack {
            TimerView(
                showPresets: $showPresets,
                showMusic: $showMusic
            )

            if music.currentSong != nil {
                VStack {
                    Spacer()
                    FloatingPlayer()
                        .padding(.horizontal, 16)
                        .padding(.bottom, 4)
                }
            }
        }
        .sheet(isPresented: $showPresets) {
            PresetsSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showMusic) {
            MusicSheet()
                .presentationDetents([.large])
        }
    }
}

@available(iOS 26.1, *)
struct FloatingPlayer: View {
    @Environment(MusicService.self) private var music

    var body: some View {
        HStack(spacing: 12) {
            if let artwork = music.currentArtwork {
                Image(uiImage: artwork)
                    .resizable()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.white.opacity(0.1))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                    )
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(music.currentSong?.title ?? "Not Playing")
                    .font(.system(.callout, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(music.currentSong?.artistName ?? "")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
            }

            Spacer()

            Button {
                music.togglePlayPause()
            } label: {
                Image(systemName: music.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
            }

            Button {
                music.skipToNext()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }
}
