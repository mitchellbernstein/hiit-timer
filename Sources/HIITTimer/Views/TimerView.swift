import SwiftUI

struct TimerView: View {
    @Environment(TimerEngine.self) private var timer
    @Environment(MusicService.self) private var music
    @Environment(HapticService.self) private var haptics
    @Environment(AudioFeedbackService.self) private var audio
    @Environment(HistoryStore.self) private var history

    @Binding var showPresets: Bool
    @Binding var showMusic: Bool

    @State private var previousPhase: TimerPhase = .idle

    var body: some View {
        ZStack {
            AlbumArtBackground(
                artwork: music.currentArtwork,
                phase: timer.phase,
                isRunning: timer.isRunning && !timer.isPaused
            )

            VStack(spacing: 0) {
                topBar
                Spacer()

                if timer.phase == .idle {
                    idleContent
                } else {
                    activeContent
                }

                Spacer()
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
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                showPresets = true
            } label: {
                Image(systemName: "list.bullet")
                    .font(.system(size: 16, weight: .semibold))
                    .glassEffect(.regular.interactive(), in: .circle)
            }
            .accessibilityLabel("Workout Presets")

            Spacer()

            if timer.phase != .idle {
                Text(timer.preset.name)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }

            Spacer()

            Button {
                showMusic = true
            } label: {
                Image(systemName: "music.note")
                    .font(.system(size: 16, weight: .semibold))
                    .glassEffect(.regular.interactive(), in: .circle)
            }
            .accessibilityLabel("Music")
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Idle State

    private var idleContent: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Current preset info
                VStack(spacing: 8) {
                    Image(systemName: timer.preset.type.systemImage)
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(.white.opacity(0.8))
                        .symbolEffect(.bounce, value: timer.preset.type)

                    Text(timer.preset.name)
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)

                    Text(timer.preset.type.description)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Duration badge
                Text(timer.preset.formattedTotalDuration)
                    .font(.system(.title3, design: .rounded, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .glassEffect(.regular, in: .capsule)

                // Big play button
                PlayPauseButton(
                    isRunning: timer.isRunning,
                    isPaused: timer.isPaused,
                    action: { timer.start() }
                )

                // Quick controls
                HStack(spacing: 14) {
                    ControlButton(
                        icon: "list.bullet",
                        label: "Presets",
                        style: .secondary,
                        action: { showPresets = true }
                    )

                    ControlButton(
                        icon: "music.note",
                        label: "Music",
                        style: .secondary,
                        action: { showMusic = true }
                    )
                }
                .padding(.horizontal, 32)

                // Analytics section (always visible)
                analyticsSection
            }
            .padding(.vertical, 16)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Analytics

    private var analyticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Progress")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 32)

            if history.totalWorkouts > 0 {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 10) {
                    statCard(value: "\(history.totalWorkouts)", label: "Workouts", icon: "flame.fill", color: .orange)
                    statCard(value: "\(history.totalMinutes)", label: "Minutes", icon: "clock.fill", color: .blue)
                    statCard(value: "\(history.currentStreak)", label: "Day Streak", icon: "calendar.badge.checkmark", color: .green)
                }
                .padding(.horizontal, 24)

                if !history.recentRecords.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.horizontal, 32)
                            .padding(.top, 4)

                        ForEach(history.recentRecords.prefix(3)) { record in
                            recentWorkoutRow(record)
                        }
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(.white.opacity(0.25))
                    Text("Complete your first workout\nto see stats")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.white.opacity(0.35))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .glassEffect(.regular, in: .rect(cornerRadius: 14))
                .padding(.horizontal, 24)
            }
        }
        .padding(.bottom, 20)
    }

    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(color)
                .frame(height: 24)

            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(.white)

            Text(label)
                .font(.system(.caption2, design: .rounded, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }

    private func recentWorkoutRow(_ record: WorkoutRecord) -> some View {
        HStack(spacing: 12) {
            Image(systemName: record.workoutType.systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))

            Text(record.presetName)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(.white)

            Spacer()

            Text(record.formattedDuration)
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .glassEffect(.regular, in: .capsule)

            Text(record.formattedDate)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 4)
    }

    // MARK: - Active State

    private var activeContent: some View {
        VStack(spacing: 20) {
            Spacer()

            LargeCountdownDisplay(
                time: timer.formattedTime,
                phase: timer.phase,
                currentRound: timer.currentRound,
                totalRounds: timer.totalRounds,
                progress: timer.progress,
                isRunning: timer.isRunning && !timer.isPaused
            )

            Spacer()

            if timer.phase != .complete {
                activeControls
            } else {
                completeControls
            }

            Spacer()
                .frame(height: 20)
        }
    }

    private var activeControls: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                ControlButton(
                    icon: "backward.end.fill",
                    label: "Back",
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
                    label: "Skip",
                    style: .skip,
                    action: { timer.skipPhase() }
                )
            }
            .padding(.horizontal, 20)

            ControlButton(
                icon: "stop.fill",
                label: "End Workout",
                style: .destructive,
                action: { timer.stop() }
            )
            .padding(.horizontal, 48)
        }
    }

    private var completeControls: some View {
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 52, weight: .light))
                    .foregroundStyle(.green)
                    .symbolEffect(.bounce, value: timer.phase == .complete)

                Text("Workout Complete")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)

                Text("Great work!")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 32)
            .glassEffect(.regular.tint(.green.opacity(0.3)), in: .rect(cornerRadius: 24))

            ControlButton(
                icon: "arrow.counterclockwise",
                label: "New Workout",
                style: .primary,
                action: { timer.reset() }
            )
            .padding(.horizontal, 48)
        }
    }
}
