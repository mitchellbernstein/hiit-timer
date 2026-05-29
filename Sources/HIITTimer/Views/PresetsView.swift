import SwiftUI

struct PresetsSheet: View {
    @Environment(PresetStore.self) private var presetStore
    @Environment(TimerEngine.self) private var timer
    @Environment(\.dismiss) private var dismiss
    @State private var showCreator = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(presetStore.presets) { preset in
                        presetRow(preset)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(.black)
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreator = true
                    } label: {
                        Image(systemName: "plus")
                            .glassEffect(.regular.interactive(), in: .circle)
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showCreator) {
                PresetEditorView { newPreset in
                    presetStore.addPreset(newPreset)
                }
            }
        }
    }

    private func presetRow(_ preset: WorkoutPreset) -> some View {
        Button {
            timer.preset = preset
            timer.reset()
            dismiss()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: preset.type.systemImage)
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 42, height: 42)
                    .glassEffect(.regular, in: .circle)

                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.name)
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white)

                    Text(preset.type.rawValue)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                Text(preset.formattedTotalDuration)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .glassEffect(.regular, in: .capsule)

                if timer.preset.id == preset.id {
                    Image(systemName: "checkmark")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.green)
                        .padding(6)
                        .glassEffect(.regular.tint(.green.opacity(0.3)), in: .circle)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
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
}

struct MusicSheet: View {
    @Environment(MusicService.self) private var musicService
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
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
            Task { await musicService.searchAndPlay(searchText) }
        }
    }

    private var nowPlayingSection: some View {
        VStack(spacing: 0) {
            if let song = musicService.currentSong {
                HStack(spacing: 14) {
                    if let artwork = musicService.currentArtwork {
                        Image(uiImage: artwork)
                            .resizable()
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
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
                    HStack(spacing: 10) {
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
                .padding(14)
                .glassEffect(.regular, in: .rect(cornerRadius: 18))
            }
        }
    }

    private var quickStartSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Start")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
            Button {
                Task { await musicService.playWorkoutPlaylist() }
            } label: {
                HStack {
                    Image(systemName: "flame.fill").foregroundStyle(.orange)
                    Text("Workout Mix")
                        .font(.system(.body, design: .rounded, weight: .medium))
                    Spacer()
                    Image(systemName: "play.fill").font(.caption)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Try Searching")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(suggestions, id: \.self) { s in
                    Button {
                        searchText = s
                        Task { await musicService.searchAndPlay(s) }
                    } label: {
                        HStack {
                            Image(systemName: "magnifyingglass").font(.caption2)
                            Text(s).font(.system(.caption, design: .rounded, weight: .medium)).lineLimit(1)
                        }
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassEffect(.regular.interactive(), in: .capsule)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Preset Editor

struct PresetEditorView: View {
    let onSave: (WorkoutPreset) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var type: WorkoutType = .intervals
    @State private var workSeconds = 40
    @State private var restSeconds = 20
    @State private var rounds = 8
    @State private var warmupSeconds = 30
    @State private var cooldownSeconds = 30
    @State private var emomMinutes = 12
    @State private var amrapMinutes = 10

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") { TextField("Workout Name", text: $name) }
                Section("Type") {
                    Picker("Mode", selection: $type) {
                        ForEach(WorkoutType.allCases) { t in
                            Label(t.rawValue, systemImage: t.systemImage).tag(t)
                        }
                    }
                }
                Section("Timing") {
                    switch type {
                    case .intervals:
                        Stepper("Work: \(workSeconds)s", value: $workSeconds, in: 5...120, step: 5)
                        Stepper("Rest: \(restSeconds)s", value: $restSeconds, in: 5...120, step: 5)
                        Stepper("Rounds: \(rounds)", value: $rounds, in: 1...30)
                        Stepper("Warmup: \(warmupSeconds)s", value: $warmupSeconds, in: 0...120, step: 5)
                        Stepper("Cooldown: \(cooldownSeconds)s", value: $cooldownSeconds, in: 0...120, step: 5)
                    case .tabata:
                        Text("Fixed: 20s work / 10s rest × 8 rounds").foregroundStyle(.secondary)
                        Stepper("Warmup: \(warmupSeconds)s", value: $warmupSeconds, in: 0...120, step: 5)
                        Stepper("Cooldown: \(cooldownSeconds)s", value: $cooldownSeconds, in: 0...120, step: 5)
                    case .emom:
                        Stepper("Total: \(emomMinutes) min", value: $emomMinutes, in: 1...60)
                    case .amrap, .countdown:
                        Stepper("Duration: \(amrapMinutes) min", value: $amrapMinutes, in: 1...60)
                    }
                }
            }
            .navigationTitle("New Preset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let p = WorkoutPreset(
                            name: name.isEmpty ? "Custom \(type.rawValue)" : name,
                            type: type, workSeconds: workSeconds, restSeconds: restSeconds,
                            rounds: rounds, warmupSeconds: warmupSeconds, cooldownSeconds: cooldownSeconds,
                            emomTotalMinutes: emomMinutes, amrapMinutes: amrapMinutes,
                            countdownSeconds: amrapMinutes * 60
                        )
                        onSave(p)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
