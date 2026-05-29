import Foundation
import SwiftUI

@MainActor
@Observable
final class TimerEngine {
    var preset: WorkoutPreset
    var phase: TimerPhase = .idle
    var remainingSeconds: Int = 0
    var currentRound: Int = 0
    var totalRounds: Int = 0
    var isRunning: Bool = false
    var isPaused: Bool = false
    var elapsedInPhase: Int = 0
    var phaseDuration: Int = 0

    private var timerTask: Task<Void, Never>?
    private var startDate: Date?

    var progress: Double {
        guard phaseDuration > 0 else { return 0 }
        return 1.0 - (Double(remainingSeconds) / Double(phaseDuration))
    }

    var overallProgress: Double {
        let total = preset.totalDurationSeconds
        guard total > 0 else { return 0 }
        let elapsed = elapsedTotalSeconds
        return min(Double(elapsed) / Double(total), 1.0)
    }

    var elapsedTotalSeconds: Int {
        guard let start = startDate else { return 0 }
        return Int(Date().timeIntervalSince(start))
    }

    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    init(preset: WorkoutPreset = .standardHIIT) {
        self.preset = preset
        reset()
    }

    func reset() {
        timerTask?.cancel()
        timerTask = nil
        phase = .idle
        isRunning = false
        isPaused = false
        remainingSeconds = 0
        currentRound = 0
        elapsedInPhase = 0
        phaseDuration = 0
        startDate = nil

        switch preset.type {
        case .intervals, .tabata:
            totalRounds = preset.rounds
        case .emom:
            totalRounds = preset.emomTotalMinutes
        case .amrap, .countdown:
            totalRounds = 1
        }
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        isPaused = false
        startDate = Date()

        if preset.warmupSeconds > 0 && (preset.type == .intervals || preset.type == .tabata) {
            advanceToWarmup()
        } else {
            advanceToNextPhase()
        }

        startTimerLoop()
    }

    func pause() {
        guard isRunning, !isPaused else { return }
        isPaused = true
        timerTask?.cancel()
        timerTask = nil
    }

    func resume() {
        guard isPaused else { return }
        isPaused = false
        startTimerLoop()
    }

    func skipPhase() {
        guard isRunning else { return }
        advanceToNextPhase()
    }

    func skipBack() {
        guard isRunning, elapsedInPhase > 0 else { return }
        remainingSeconds = phaseDuration
    }

    func stop() {
        timerTask?.cancel()
        timerTask = nil
        reset()
    }

    private func advanceToWarmup() {
        phase = .warmup
        remainingSeconds = preset.warmupSeconds
        phaseDuration = preset.warmupSeconds
        elapsedInPhase = 0
    }

    private func advanceToNextPhase() {
        switch preset.type {
        case .intervals:
            advanceIntervalPhase()
        case .tabata:
            advanceTabataPhase()
        case .emom:
            advanceEMOMPhase()
        case .amrap:
            advanceAMRAPPhase()
        case .countdown:
            advanceCountdownPhase()
        }
    }

    private func advanceIntervalPhase() {
        if phase == .warmup {
            phase = .work
            currentRound = 1
            remainingSeconds = preset.workSeconds
            phaseDuration = preset.workSeconds
        } else if phase == .work {
            phase = .rest
            remainingSeconds = preset.restSeconds
            phaseDuration = preset.restSeconds
        } else if phase == .rest {
            if currentRound >= preset.rounds {
                advanceToCooldown()
            } else {
                currentRound += 1
                phase = .work
                remainingSeconds = preset.workSeconds
                phaseDuration = preset.workSeconds
            }
        } else if phase == .cooldown {
            complete()
        }
        elapsedInPhase = 0
    }

    private func advanceTabataPhase() {
        if phase == .warmup {
            phase = .work
            currentRound = 1
            remainingSeconds = 20
            phaseDuration = 20
        } else if phase == .work {
            phase = .rest
            remainingSeconds = 10
            phaseDuration = 10
        } else if phase == .rest {
            if currentRound >= 8 {
                advanceToCooldown()
            } else {
                currentRound += 1
                phase = .work
                remainingSeconds = 20
                phaseDuration = 20
            }
        } else if phase == .cooldown {
            complete()
        }
        elapsedInPhase = 0
    }

    private func advanceEMOMPhase() {
        if currentRound == 0 {
            currentRound = 1
        } else if currentRound >= preset.emomTotalMinutes {
            complete()
            return
        } else {
            currentRound += 1
        }
        phase = .work
        remainingSeconds = preset.emomIntervalSeconds
        phaseDuration = preset.emomIntervalSeconds
        elapsedInPhase = 0
    }

    private func advanceAMRAPPhase() {
        phase = .work
        remainingSeconds = preset.amrapMinutes * 60
        phaseDuration = remainingSeconds
        currentRound = 1
        elapsedInPhase = 0
    }

    private func advanceCountdownPhase() {
        phase = .work
        remainingSeconds = preset.countdownSeconds
        phaseDuration = remainingSeconds
        currentRound = 1
        elapsedInPhase = 0
    }

    private func advanceToCooldown() {
        if preset.cooldownSeconds > 0 {
            phase = .cooldown
            remainingSeconds = preset.cooldownSeconds
            phaseDuration = preset.cooldownSeconds
            elapsedInPhase = 0
        } else {
            complete()
        }
    }

    private func complete() {
        phase = .complete
        remainingSeconds = 0
        isRunning = false
        isPaused = false
        timerTask?.cancel()
        timerTask = nil
    }

    private func startTimerLoop() {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { break }
                try? await Task.sleep(for: .seconds(1))
                await MainActor.run {
                    self.tick()
                }
            }
        }
    }

    private func tick() {
        guard isRunning, !isPaused else { return }
        remainingSeconds -= 1
        elapsedInPhase += 1

        if remainingSeconds <= 0 {
            advanceToNextPhase()
        }
    }
}
