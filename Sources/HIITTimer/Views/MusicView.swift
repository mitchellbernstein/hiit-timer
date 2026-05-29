import SwiftUI
import MusicKit

struct MusicView: View {
    @Environment(MusicService.self) private var musicService
    @State private var searchText = ""
    @State private var searchResults: MusicItemCollection<Song>?
    @State private var isSearching = false

    private let suggestions = [
        "high intensity workout",
        "electronic workout",
        "hip hop gym",
        "rock training",
        "pop running"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !musicService.isAuthorized {
                    notAuthorizedView
                } else if !musicService.canPlayCatalog {
                    noSubscriptionView
                } else {
                    musicContent
                }
            }
            .background(.black)
            .navigationTitle("Music")
            .task {
                await musicService.requestAuthorization()
            }
        }
    }

    private var notAuthorizedView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "music.note.list")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(.white.opacity(0.5))

            Text("Apple Music Access")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.white)

            Text("Allow access to play music during your workouts.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)

            Button("Grant Access") {
                Task { await musicService.requestAuthorization() }
            }
            .buttonStyle(.glass)

            Spacer()
        }
        .padding(32)
    }

    private var noSubscriptionView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "music.note.house")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(.white.opacity(0.5))

            Text("Apple Music Subscription")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.white)

            Text("An Apple Music subscription is needed to play music.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(32)
    }

    private var musicContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                nowPlayingSection

                quickStartSection

                suggestionsSection
            }
            .padding(16)
        }
        .searchable(text: $searchText, prompt: "Search Apple Music")
        .onSubmit(of: .search) {
            Task { await performSearch() }
        }
    }

    private var nowPlayingSection: some View {
        VStack(spacing: 0) {
            if let song = musicService.currentSong {
                HStack(spacing: 16) {
                    if let artwork = musicService.currentArtwork {
                        Image(uiImage: artwork)
                            .resizable()
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Now Playing")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))

                        Text(song.title)
                            .font(.system(.headline, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white)

                        Text(song.artistName)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    Spacer()

                    HStack(spacing: 12) {
                        Button {
                            musicService.togglePlayPause()
                        } label: {
                            Image(systemName: musicService.isPlaying ? "pause.fill" : "play.fill")
                                .font(.title3)
                                .glassEffect(.regular.interactive(), in: .circle)
                        }

                        Button {
                            musicService.skipToNext()
                        } label: {
                            Image(systemName: "forward.fill")
                                .font(.title3)
                                .glassEffect(.regular.interactive(), in: .circle)
                        }
                    }
                }
                .padding(16)
                .glassEffect(.regular, in: .rect(cornerRadius: 20))
            }
        }
    }

    private var quickStartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Start")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(.white)

            Button {
                Task { await musicService.playWorkoutPlaylist() }
            } label: {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("Workout Mix")
                        .font(.system(.body, design: .rounded, weight: .medium))
                    Spacer()
                    Image(systemName: "play.fill")
                        .font(.caption)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
    }

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Try Searching")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(.white)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button {
                        searchText = suggestion
                        Task { await performSearch() }
                    } label: {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .font(.caption)
                            Text(suggestion)
                                .font(.system(.caption, design: .rounded, weight: .medium))
                                .lineLimit(1)
                        }
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassEffect(.regular.interactive(), in: .capsule)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func performSearch() async {
        guard !searchText.isEmpty else { return }
        isSearching = true
        defer { isSearching = false }
        await musicService.searchAndPlay(searchText)
    }
}
