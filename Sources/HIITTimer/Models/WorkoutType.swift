import Foundation

enum WorkoutType: String, Codable, CaseIterable, Identifiable {
    case intervals = "Intervals"
    case tabata = "Tabata"
    case emom = "EMOM"
    case amrap = "AMRAP"
    case countdown = "Countdown"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .intervals: "arrow.triangle.turn.up.right.diamond.fill"
        case .tabata: "bolt.fill"
        case .emom: "clock.arrow.2.circlepath"
        case .amrap: "infinity"
        case .countdown: "timer"
        }
    }

    var description: String {
        switch self {
        case .intervals: "Alternating work and rest periods"
        case .tabata: "20s work / 10s rest × 8 rounds"
        case .emom: "Every minute on the minute"
        case .amrap: "As many rounds as possible"
        case .countdown: "Single countdown timer"
        }
    }

    var defaultRounds: Int {
        switch self {
        case .intervals: 8
        case .tabata: 8
        case .emom: 12
        case .amrap: 0
        case .countdown: 1
        }
    }
}
