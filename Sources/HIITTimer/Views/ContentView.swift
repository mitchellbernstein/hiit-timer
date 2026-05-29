import SwiftUI

enum AppTab: String, CaseIterable {
    case timer = "Timer"
    case presets = "Presets"
    case music = "Music"

    var systemImage: String {
        switch self {
        case .timer: "stopwatch"
        case .presets: "list.bullet"
        case .music: "music.note"
        }
    }
}

@available(iOS 26.1, *)
struct ContentView: View {
    @Environment(MusicService.self) private var music
    @Environment(TimerEngine.self) private var timer

    @State private var selectedTab: AppTab = .timer
    @State private var showAccessory: Bool = false

    var body: some View {
        TabView(selection: $selectedTab) {
            TimerView()
                .tabItem {
                    Label(AppTab.timer.rawValue, systemImage: AppTab.timer.systemImage)
                }
                .tag(AppTab.timer)

            PresetsView()
                .tabItem {
                    Label(AppTab.presets.rawValue, systemImage: AppTab.presets.systemImage)
                }
                .tag(AppTab.presets)

            MusicView()
                .tabItem {
                    Label(AppTab.music.rawValue, systemImage: AppTab.music.systemImage)
                }
                .tag(AppTab.music)
        }
        .tint(.white)
        .tabViewBottomAccessory(isEnabled: music.currentSong != nil) {
            FloatingPlayer()
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
    }
}

@available(iOS 26.1, *)
struct FloatingPlayer: View {
    @Environment(MusicService.self) private var music
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement

    var body: some View {
        HStack(spacing: 14) {
            if let artwork = music.currentArtwork {
                Image(uiImage: artwork)
                    .resizable()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.white.opacity(0.1))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.4))
                    )
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(music.currentSong?.title ?? "Not Playing")
                    .font(.system(.callout, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(music.currentSong?.artistName ?? "Tap to browse")
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
    }
}
