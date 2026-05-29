import SwiftUI

@available(iOS 26.1, *)
@main
struct HIITTimerApp: App {
    @State private var timerEngine = TimerEngine()
    @State private var musicService = MusicService()
    @State private var hapticService = HapticService()
    @State private var audioFeedback = AudioFeedbackService()
    @State private var presetStore = PresetStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(timerEngine)
                .environment(musicService)
                .environment(hapticService)
                .environment(audioFeedback)
                .environment(presetStore)
                .preferredColorScheme(.dark)
        }
    }
}
