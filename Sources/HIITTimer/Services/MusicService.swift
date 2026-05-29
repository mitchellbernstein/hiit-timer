import Foundation
import SwiftUI
@preconcurrency import MusicKit

@MainActor
@Observable
final class MusicService {
    var isAuthorized = false
    var canPlayCatalog = false
    var currentSong: Song?
    var currentArtwork: UIImage?
    var isPlaying = false

    nonisolated(unsafe) private let player = ApplicationMusicPlayer.shared
    private var searchTask: Task<Void, Never>?

    func requestAuthorization() async {
        let status = await MusicAuthorization.request()
        isAuthorized = status == .authorized
        if isAuthorized {
            await checkSubscription()
        }
    }

    func checkSubscription() async {
        do {
            let subscription = try await MusicSubscription.current
            canPlayCatalog = subscription.canPlayCatalogContent
        } catch {
            canPlayCatalog = false
        }
    }

    func searchAndPlay(_ query: String) async {
        do {
            var request = MusicCatalogSearchRequest(term: query, types: [Song.self])
            request.limit = 1

            let response = try await request.response()
            guard let song = response.songs.first else { return }
            currentSong = song

            player.queue = [song]
            try await player.play()
            isPlaying = true

            await loadArtwork(for: song)
        } catch {
            currentSong = nil
            isPlaying = false
        }
    }

    func playWorkoutPlaylist() async {
        let queries = ["high intensity workout", "HIIT training", "gym motivation", "electronic workout"]
        for query in queries {
            if currentSong != nil { break }
            await searchAndPlay(query)
        }
    }

    func togglePlayPause() {
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            Task { @MainActor in
                try? await player.play()
                isPlaying = true
            }
        }
    }

    func skipToNext() {
        Task { @MainActor [player] in
            try? await player.skipToNextEntry()
            isPlaying = player.state.playbackStatus == .playing
        }
    }

    private func loadArtwork(for song: Song) async {
        guard let artwork = song.artwork,
              let url = artwork.url(width: 800, height: 800) else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            currentArtwork = UIImage(data: data)
        } catch {
            currentArtwork = nil
        }
    }

    var albumArtworkView: some View {
        Group {
            if let artwork = currentArtwork {
                Image(uiImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.clear
            }
        }
    }
}
