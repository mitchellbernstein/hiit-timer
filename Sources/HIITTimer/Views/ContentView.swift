import SwiftUI
import MusicKit

enum AppState {
    case browsing
    case setup(WorkoutPreset)
}

@available(iOS 26.1, *)
struct ContentView: View {
    @Environment(TimerEngine.self) private var timer
    @Environment(MusicService.self) private var music
    @Environment(PresetStore.self) private var presetStore
    @Environment(HistoryStore.self) private var history

    @State private var state: AppState = .browsing
    @State private var showActiveWorkout = false

    var body: some View {
        ZStack {
            switch state {
            case .browsing:
                WorkoutListView { preset in
                    timer.preset = preset
                    timer.reset()
                    state = .setup(preset)
                }

            case .setup(let preset):
                WorkoutSetupView(preset: preset) {
                    showActiveWorkout = true
                } onBack: {
                    state = .browsing
                }
            }

            if music.currentSong != nil && !showActiveWorkout {
                VStack {
                    Spacer()
                    FloatingPlayer()
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showActiveWorkout) {
            WorkoutActiveView {
                showActiveWorkout = false
                state = .browsing
            }
        }
    }
}

// MARK: - Floating Player

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

            Button { music.togglePlayPause() } label: {
                Image(systemName: music.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title3).foregroundStyle(.white)
            }
            Button { music.skipToNext() } label: {
                Image(systemName: "forward.fill")
                    .font(.title3).foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }
}

// MARK: - Workout List

struct WorkoutListView: View {
    @Environment(PresetStore.self) private var presetStore
    @Environment(HistoryStore.self) private var history
    let onSelect: (WorkoutPreset) -> Void

    @State private var showCreator = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .padding(.bottom, 20)

                    LazyVStack(spacing: 12) {
                        ForEach(presetStore.presets) { preset in
                            presetCard(preset)
                        }
                    }
                    .padding(.horizontal, 20)

                    analyticsSection
                        .padding(.top, 24)
                        .padding(.bottom, 40)
                }
            }
            .background(.black)
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreator = true
                    } label: {
                        Image(systemName: "plus")
                            .glassEffect(.regular.interactive(), in: .circle)
                    }
                }
            }
            .sheet(isPresented: $showCreator) {
                PresetEditorView { presetStore.addPreset($0) }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("HIIT Timer")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(.white)

            if history.totalWorkouts > 0 {
                HStack(spacing: 16) {
                    Label("\(history.totalWorkouts)", systemImage: "flame.fill")
                    Label("\(history.totalMinutes)m", systemImage: "clock.fill")
                    Label("\(history.currentStreak)d streak", systemImage: "calendar.badge.checkmark")
                }
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func presetCard(_ preset: WorkoutPreset) -> some View {
        Button {
            onSelect(preset)
        } label: {
            HStack(spacing: 16) {
                Image(systemName: preset.type.systemImage)
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 52, height: 52)
                    .glassEffect(.regular, in: .circle)

                VStack(alignment: .leading, spacing: 4) {
                    Text(preset.name)
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white)

                    HStack(spacing: 8) {
                        Text(preset.type.rawValue)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))

                        Text("·")
                            .foregroundStyle(.white.opacity(0.3))

                        Text(preset.formattedTotalDuration)
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    if !preset.musicQuery.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "music.note")
                                .font(.system(size: 9))
                            Text(preset.musicQuery)
                                .font(.system(.caption2, design: .rounded))
                        }
                        .foregroundStyle(.white.opacity(0.35))
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                presetStore.deletePreset(preset)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var analyticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if history.totalWorkouts > 0 {
                Text("Recent")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)

                ForEach(history.recentRecords.prefix(5)) { record in
                    HStack(spacing: 12) {
                        Image(systemName: record.workoutType.systemImage)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))

                        Text(record.presetName)
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(.white)

                        Spacer()

                        Text(record.formattedDuration)
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(.white.opacity(0.4))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .glassEffect(.regular, in: .capsule)

                        Text(record.formattedDate)
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(.white.opacity(0.25))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

// MARK: - Workout Setup

struct WorkoutSetupView: View {
    let preset: WorkoutPreset
    let onStart: () -> Void
    let onBack: () -> Void

    @Environment(MusicService.self) private var music
    @Environment(TimerEngine.self) private var timer
    @State private var searchText = ""
    @State private var isSearching = false

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Button {
                    onBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .glassEffect(.regular.interactive(), in: .circle)
                }

                Spacer()

                Text("Workout Setup")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                Color.clear.frame(width: 36, height: 36)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            Spacer()

            // Workout card
            VStack(spacing: 12) {
                Image(systemName: preset.type.systemImage)
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(.white.opacity(0.8))

                Text(preset.name)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)

                Text(preset.type.description)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)

                HStack(spacing: 16) {
                    Label("\(preset.formattedTotalDuration)", systemImage: "clock")
                    if preset.rounds > 0 {
                        Label("\(preset.rounds) rounds", systemImage: "repeat")
                    }
                }
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
            }
            .padding(24)
            .glassEffect(.regular, in: .rect(cornerRadius: 24))
            .padding(.horizontal, 24)

            Spacer()

            // Music section
            VStack(spacing: 14) {
                Text("Music")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))

                if let song = music.currentSong {
                    nowPlayingCard(song)
                } else if !preset.musicQuery.isEmpty && !isSearching {
                    VStack(spacing: 10) {
                        Text("Suggested: \"\(preset.musicQuery)\"")
                            .font(.system(.callout, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))

                        Button {
                            isSearching = true
                            Task {
                                await music.searchAndPlay(preset.musicQuery)
                                isSearching = false
                            }
                        } label: {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Load Music")
                            }
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .glassEffect(.regular.interactive(), in: .capsule)
                        }
                    }
                }

                // Search
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.white.opacity(0.4))
                    TextField("Search Apple Music...", text: $searchText)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.white)
                        .submitLabel(.search)
                        .onSubmit {
                            guard !searchText.isEmpty else { return }
                            isSearching = true
                            Task {
                                await music.searchAndPlay(searchText)
                                isSearching = false
                            }
                        }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .glassEffect(.regular, in: .rect(cornerRadius: 14))
            }
            .padding(.horizontal, 24)

            Spacer()

            // Start button
            Button {
                timer.preset = preset
                timer.reset()
                onStart()
            } label: {
                HStack {
                    if music.currentSong != nil {
                        Image(systemName: "music.note")
                        Text("Start with Music")
                    } else {
                        Text("Start Workout")
                    }
                    Image(systemName: "arrow.right")
                }
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(.white, in: RoundedRectangle(cornerRadius: 20))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .background(.black)
    }

    private func nowPlayingCard(_ song: Song) -> some View {
        HStack(spacing: 12) {
            if let art = music.currentArtwork {
                Image(uiImage: art)
                    .resizable()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.system(.callout, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(song.artistName)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Button {
                music.togglePlayPause()
            } label: {
                Image(systemName: music.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title3)
                    .glassEffect(.regular.interactive(), in: .circle)
            }
        }
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }
}
