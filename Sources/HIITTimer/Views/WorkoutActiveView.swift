import SwiftUI

struct WorkoutActiveView: View {
    let onDismiss: () -> Void

    @Environment(TimerEngine.self) private var timer
    @Environment(MusicService.self) private var music
    @Environment(HapticService.self) private var haptics
    @Environment(AudioFeedbackService.self) private var audio
    @Environment(HistoryStore.self) private var history

    @State private var previousPhase: TimerPhase = .idle
    @State private var showControls = false
    @State private var showEndConfirmation = false

    var body: some View {
        ZStack {
            // Album art background — very subtle
            if let art = music.currentArtwork {
                Image(uiImage: art)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .blur(radius: 40)
                    .opacity(0.25)
                    .ignoresSafeArea()
            }

            Color.black.opacity(0.85).ignoresSafeArea()

            // Main content
            VStack(spacing: 0) {
                if timer.phase == .complete {
                    completeView
                } else {
                    activeMetricsView

                    Spacer()

                    controlSheet
                }
            }
        }
        .onAppear {
            if !timer.isRunning && timer.phase == .idle {
                timer.start()
            }
        }
        .onChange(of: timer.phase) { _, newPhase in
            if newPhase != previousPhase && newPhase != .idle {
                haptics.phaseTransition(from: previousPhase, to: newPhase)
                audio.playPhaseTransition(to: newPhase)
            }
            if newPhase == .complete {
                history.addRecord(WorkoutRecord(
                    presetName: timer.preset.name,
                    workoutType: timer.preset.type,
                    durationSeconds: timer.elapsedTotalSeconds,
                    completedAt: Date()
                ))
            }
            previousPhase = newPhase
        }
        .onChange(of: timer.remainingSeconds) { _, seconds in
            if (2...3).contains(seconds) && timer.isRunning {
                haptics.tickWarning()
                audio.playCountdownTick()
            }
            if seconds == 1 && timer.isRunning {
                audio.playFinalCountdown()
            }
        }
        .confirmationDialog("End Workout?", isPresented: $showEndConfirmation) {
            Button("End Workout", role: .destructive) {
                timer.stop()
                onDismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your progress will be saved.")
        }
    }

    // MARK: - Active Metrics (above the bottom sheet)

    private var activeMetricsView: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 60)

            // Phase label
            Text(timer.phase.displayName.uppercased())
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(phaseColor)
                .tracking(3)

            // Large timer
            Text(timer.formattedTime)
                .font(.system(size: 88, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.yellow)
                .contentTransition(.numericText(countsDown: true))
                .animation(.snappy, value: timer.formattedTime)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.1))
                        .frame(height: 3)

                    Capsule()
                        .fill(phaseColor)
                        .frame(width: geo.size.width * timer.progress, height: 3)
                        .animation(.smooth(duration: 0.3), value: timer.progress)
                }
            }
            .frame(height: 3)
            .padding(.horizontal, 64)

            // Round counter
            if timer.totalRounds > 1 {
                HStack(spacing: 6) {
                    ForEach(1...timer.totalRounds, id: \.self) { round in
                        Circle()
                            .fill(round <= timer.currentRound ? phaseColor : .white.opacity(0.15))
                            .frame(width: 6, height: 6)
                    }
                }
            }

            // Overall progress
            Text("\(timer.currentRound) of \(timer.totalRounds)")
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
                .opacity(timer.totalRounds > 1 ? 1 : 0)

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Bottom Control Sheet

    private var controlSheet: some View {
        VStack(spacing: 14) {
            // Workout type icon + name
            HStack {
                Image(systemName: timer.preset.type.systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(phaseColor)

                Text(timer.preset.name)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))

                Spacer()

                // Music mini-indicator
                if let song = music.currentSong {
                    HStack(spacing: 4) {
                        Image(systemName: "music.note")
                            .font(.system(size: 10))
                        Text(song.title)
                            .lineLimit(1)
                    }
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
                }
            }

            // Main controls
            HStack(spacing: 24) {
                // Back
                Button {
                    timer.skipBack()
                } label: {
                    Image(systemName: "backward.end.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(width: 56, height: 56)
                }

                Spacer()

                // Play/Pause
                Button {
                    if timer.isPaused {
                        timer.resume()
                    } else {
                        timer.pause()
                    }
                } label: {
                    Image(systemName: timer.isRunning && !timer.isPaused ? "pause.fill" : "play.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 72, height: 72)
                        .background(.white.opacity(0.15), in: Circle())
                }

                Spacer()

                // Skip
                Button {
                    timer.skipPhase()
                } label: {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(width: 56, height: 56)
                }
            }

            // End workout
            Button {
                if timer.isRunning && !timer.isPaused {
                    timer.pause()
                }
                showEndConfirmation = true
            } label: {
                Label("End Workout", systemImage: "xmark")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 18)
        .padding(.bottom, 12)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(0.95)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Complete

    private var completeView: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(.green)

                Text("Workout Complete")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)

                Text(timer.preset.name)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))

                Text(timer.elapsedTotalSeconds.formattedDuration)
                    .font(.system(.title3, design: .rounded, weight: .medium))
                    .foregroundStyle(.yellow)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .glassEffect(.regular, in: .capsule)
            }
            .padding(32)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))

            Spacer()

            Button {
                onDismiss()
            } label: {
                Text("Done")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(.white, in: RoundedRectangle(cornerRadius: 20))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }

    private var phaseColor: Color {
        switch timer.phase {
        case .work: .yellow
        case .rest: .mint
        case .warmup: .blue
        case .cooldown: .indigo
        case .complete: .green
        case .idle: .white
        }
    }
}

private extension Int {
    var formattedDuration: String {
        let m = self / 60
        let s = self % 60
        return m > 0 ? "\(m)m \(s)s" : "\(s)s"
    }
}
