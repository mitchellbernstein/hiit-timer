import Foundation

enum TimerPhase: String, Codable {
    case idle
    case warmup
    case work
    case rest
    case cooldown
    case complete

    var displayName: String {
        switch self {
        case .idle: "Ready"
        case .warmup: "Warm Up"
        case .work: "Work"
        case .rest: "Rest"
        case .cooldown: "Cool Down"
        case .complete: "Done"
        }
    }

    var color: String {
        switch self {
        case .idle: "phaseIdle"
        case .warmup: "phaseWarmup"
        case .work: "phaseWork"
        case .rest: "phaseRest"
        case .cooldown: "phaseCooldown"
        case .complete: "phaseComplete"
        }
    }
}
