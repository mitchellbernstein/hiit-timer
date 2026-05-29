import Foundation
import AVFoundation

@MainActor
@Observable
final class AudioFeedbackService {
    private var audioPlayer: AVAudioPlayer?
    private var isEnabled: Bool = true
    private var duckMusic: Bool = true

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }

    func setDuckMusic(_ duck: Bool) {
        duckMusic = duck
    }

    func playPhaseTransition(to phase: TimerPhase) {
        guard isEnabled else { return }

        switch phase {
        case .work:
            playSystemSound(1324) // Short double-beep
        case .rest:
            playSystemSound(1323) // Single soft beep
        case .warmup:
            playSystemSound(1325)
        case .cooldown:
            playSystemSound(1326)
        case .complete:
            playCompletionFanfare()
        case .idle:
            break
        }
    }

    func playCountdownTick() {
        guard isEnabled else { return }
        playSystemSound(1104)
    }

    func playFinalCountdown() {
        guard isEnabled else { return }
        playSystemSound(1005)
    }

    private func playSystemSound(_ soundID: Int) {
        if duckMusic {
            try? AVAudioSession.sharedInstance().setActive(true)
        }
        AudioServicesPlaySystemSound(SystemSoundID(soundID))
    }

    private func playCompletionFanfare() {
        playSystemSound(1025)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.playSystemSound(1026)
        }
    }
}
