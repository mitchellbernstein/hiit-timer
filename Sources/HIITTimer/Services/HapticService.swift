import SwiftUI
import CoreHaptics

@MainActor
@Observable
final class HapticService {
    private var engine: CHHapticEngine?
    private var supportsHaptics = false

    init() {
        setupEngine()
    }

    private func setupEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        supportsHaptics = true
        do {
            engine = try CHHapticEngine()
            try engine?.start()
            engine?.resetHandler = { [weak self] in
                try? self?.engine?.start()
            }
        } catch {
            supportsHaptics = false
        }
    }

    func phaseTransition(from: TimerPhase, to: TimerPhase) {
        guard supportsHaptics, let engine else { return }

        switch to {
        case .work:
            playWorkStart(engine: engine)
        case .rest:
            playRestStart(engine: engine)
        case .warmup:
            playSoftTap(engine: engine)
        case .cooldown:
            playSoftTap(engine: engine)
        case .complete:
            playWorkoutComplete(engine: engine)
        case .idle:
            break
        }
    }

    func tickWarning() {
        guard supportsHaptics, let engine else { return }
        playTick(engine: engine)
    }

    private func playWorkStart(engine: CHHapticEngine) {
        do {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [intensity, sharpness],
                relativeTime: 0,
                duration: 0.15
            )
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {}
    }

    private func playRestStart(engine: CHHapticEngine) {
        do {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [intensity, sharpness],
                relativeTime: 0,
                duration: 0.1
            )
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {}
    }

    private func playSoftTap(engine: CHHapticEngine) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func playWorkoutComplete(engine: CHHapticEngine) {
        do {
            let events: [CHHapticEvent] = [
                makeEvent(relativeTime: 0, intensity: 0.8, sharpness: 0.5, duration: 0.1),
                makeEvent(relativeTime: 0.15, intensity: 1.0, sharpness: 1.0, duration: 0.15),
                makeEvent(relativeTime: 0.35, intensity: 1.0, sharpness: 1.0, duration: 0.2)
            ]
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {}
    }

    private func playTick(engine: CHHapticEngine) {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    private func makeEvent(relativeTime: TimeInterval, intensity: Float, sharpness: Float, duration: TimeInterval) -> CHHapticEvent {
        CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: relativeTime,
            duration: duration
        )
    }
}
