import SwiftUI

struct WorkoutActiveView: View {
    let onDismiss: () -> Void

    @Environment(TimerEngine.self) private var timer
    @Environment(MusicService.self) private var music
    @Environment(HapticService.self) private var haptics
    @Environment(AudioFeedbackService.self) private var audio
    @Environment(HistoryStore.self) private var history

    @State private var previousPhase: TimerPhase = .idle
    @State private var showEndConfirmation = false

    var body: some View {
        ZStack {
            AlbumArtBackground(
                artwork: music.currentArtwork,
                phase: timer.phase,
                isRunning: timer.isRunning && !timer.isPaused
            )

            VStack(spacing: 0) {
                // Top bar — preset name + end button
                HStack {
                    Text(timer.preset.name)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))

                    Spacer()

                    Button {
                        if timer.isRunning && !timer.isPaused {
                            timer.pause()
                        }
                        showEndConfirmation = true
                    } label: {
                        Text("End")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .glassEffect(.regular, in: .capsule)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                Spacer()

                if timer.phase == .idle && !timer.isRunning {
                    // Pre-start countdown or ready state
                    readyToStart
                } else if timer.phase == .complete {
                    completeContent
                } else {
                    activeContent
                }

                Spacer()
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
                let record = WorkoutRecord(
                    presetName: timer.preset.name,
                    workoutType: timer.preset.type,
                    durationSeconds: timer.elapsedTotalSeconds,
                    completedAt: Date()
                )
                history.addRecord(record)
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
            Button("Cancel", role: .cancel) {
                if timer.isPaused {
                    timer.resume()
                }
            }
        } message: {
            Text("Your progress will be saved.")
        }
    }

    // MARK: - Pre-start

    private var readyToStart: some View {
        VStack(spacing: 32) {
            PlayPauseButton(
                isRunning: timer.isRunning,
                isPaused: timer.isPaused,
                action: {
                    if !timer.isRunning {
                        timer.start()
                    }
                }
            )
        }
    }

    // MARK: - Active timer

    private var activeContent: some View {
        VStack(spacing: 20) {
            LargeCountdownDisplay(
                time: timer.formattedTime,
                phase: timer.phase,
                currentRound: timer.currentRound,
                totalRounds: timer.totalRounds,
                progress: timer.progress,
                isRunning: timer.isRunning && !timer.isPaused
            )
            .padding(.top, 20)

            Spacer()

            // Controls
            VStack(spacing: 16) {
                HStack(spacing: 20) {
                    ControlButton(
                        icon: "backward.end.fill",
                        style: .skip,
                        action: { timer.skipBack() }
                    )

                    PlayPauseButton(
                        isRunning: timer.isRunning,
                        isPaused: timer.isPaused,
                        action: {
                            if timer.isPaused {
                                timer.resume()
                            } else {
                                timer.pause()
                            }
                        }
                    )

                    ControlButton(
                        icon: "forward.end.fill",
                        style: .skip,
                        action: { timer.skipPhase() }
                    )
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 16)

            // Music mini
            if let song = music.currentSong {
                HStack(spacing: 10) {
                    if let art = music.currentArtwork {
                        Image(uiImage: art)
                            .resizable()
                            .frame(width: 32, height: 32)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    Text(song.title)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
        }
    }

    // MARK: - Complete

    private var completeContent: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(.green)
                    .symbolEffect(.bounce, value: timer.phase == .complete)

                Text("Workout Complete")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)

                Text(timer.preset.name)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))

                Text(timer.elapsedTotalSeconds.formattedDuration)
                    .font(.system(.title3, design: .rounded, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .glassEffect(.regular, in: .capsule)
            }
            .padding(28)
            .glassEffect(.regular.tint(.green.opacity(0.2)), in: .rect(cornerRadius: 28))

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
}

private extension Int {
    var formattedDuration: String {
        let minutes = self / 60
        let seconds = self % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }
}
