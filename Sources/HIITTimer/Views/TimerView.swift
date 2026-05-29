import SwiftUI

struct TimerView: View {
    @Environment(TimerEngine.self) private var timer
    @Environment(MusicService.self) private var music
    @Environment(HapticService.self) private var haptics
    @Environment(AudioFeedbackService.self) private var audio

    @State private var previousPhase: TimerPhase = .idle
    @State private var showPresetPicker = false

    var body: some View {
        ZStack {
            AlbumArtBackground(
                artwork: music.currentArtwork,
                phase: timer.phase,
                isRunning: timer.isRunning && !timer.isPaused
            )

            VStack(spacing: 0) {
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

    // MARK: - Idle State

    private var idleContent: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Image(systemName: timer.preset.type.systemImage)
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(.white.opacity(0.8))
                    .symbolEffect(.bounce, value: timer.preset.type)

                Text(timer.preset.name)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)

                Text(timer.preset.type.description)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            Text(timer.preset.formattedTotalDuration)
                .font(.system(.title3, design: .rounded, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .glassEffect(.regular, in: .capsule)

            PlayPauseButton(
                isRunning: timer.isRunning,
                isPaused: timer.isPaused,
                action: { timer.start() }
            )

            HStack(spacing: 16) {
                ControlButton(
                    icon: "list.bullet",
                    label: "Presets",
                    style: .secondary,
                    action: { showPresetPicker = true }
                )

                ControlButton(
                    icon: "music.note",
                    label: "Music",
                    style: .secondary,
                    action: { /* handled by tab */ }
                )
            }
            .padding(.horizontal, 32)
        }
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
