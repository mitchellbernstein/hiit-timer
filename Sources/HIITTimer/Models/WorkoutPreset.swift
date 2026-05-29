import Foundation

struct WorkoutPreset: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var type: WorkoutType
    var workSeconds: Int
    var restSeconds: Int
    var rounds: Int
    var warmupSeconds: Int
    var cooldownSeconds: Int
    var emomIntervalSeconds: Int
    var emomTotalMinutes: Int
    var amrapMinutes: Int
    var countdownSeconds: Int
    var musicQuery: String

    init(
        name: String,
        type: WorkoutType = .intervals,
        workSeconds: Int = 40,
        restSeconds: Int = 20,
        rounds: Int = 8,
        warmupSeconds: Int = 30,
        cooldownSeconds: Int = 30,
        emomIntervalSeconds: Int = 60,
        emomTotalMinutes: Int = 12,
        amrapMinutes: Int = 10,
        countdownSeconds: Int = 300,
        musicQuery: String = ""
    ) {
        self.name = name
        self.type = type
        self.workSeconds = workSeconds
        self.restSeconds = restSeconds
        self.rounds = rounds
        self.warmupSeconds = warmupSeconds
        self.cooldownSeconds = cooldownSeconds
        self.emomIntervalSeconds = emomIntervalSeconds
        self.emomTotalMinutes = emomTotalMinutes
        self.amrapMinutes = amrapMinutes
        self.countdownSeconds = countdownSeconds
        self.musicQuery = musicQuery
    }

    var totalDurationSeconds: Int {
        switch type {
        case .intervals:
            return warmupSeconds + (workSeconds + restSeconds) * rounds + cooldownSeconds
        case .tabata:
            return warmupSeconds + 30 * 8 + cooldownSeconds
        case .emom:
            return emomIntervalSeconds * emomTotalMinutes
        case .amrap:
            return amrapMinutes * 60
        case .countdown:
            return countdownSeconds
        }
    }

    var formattedTotalDuration: String {
        let total = totalDurationSeconds
        let minutes = total / 60
        let seconds = total % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }
}

extension WorkoutPreset {
    static let standardHIIT = WorkoutPreset(
        name: "Standard HIIT",
        type: .intervals,
        workSeconds: 40, restSeconds: 20, rounds: 8,
        warmupSeconds: 30, cooldownSeconds: 30,
        musicQuery: "high intensity workout"
    )

    static let tabata = WorkoutPreset(
        name: "Tabata",
        type: .tabata,
        warmupSeconds: 30, cooldownSeconds: 30,
        musicQuery: "electronic workout"
    )

    static let beginnerHIIT = WorkoutPreset(
        name: "Beginner HIIT",
        type: .intervals,
        workSeconds: 30, restSeconds: 60, rounds: 6,
        warmupSeconds: 60, cooldownSeconds: 60,
        musicQuery: "pop running"
    )

    static let advancedHIIT = WorkoutPreset(
        name: "Advanced HIIT",
        type: .intervals,
        workSeconds: 45, restSeconds: 15, rounds: 12,
        warmupSeconds: 30, cooldownSeconds: 30,
        musicQuery: "gym motivation"
    )

    static let emom12 = WorkoutPreset(
        name: "EMOM 12",
        type: .emom, emomTotalMinutes: 12,
        musicQuery: "hip hop gym"
    )

    static let amrap10 = WorkoutPreset(
        name: "AMRAP 10",
        type: .amrap, amrapMinutes: 10,
        musicQuery: "rock training"
    )

    static let countdown5 = WorkoutPreset(
        name: "5 Min Countdown",
        type: .countdown, countdownSeconds: 300,
        musicQuery: "electronic workout"
    )

    static let defaultPresets: [WorkoutPreset] = [
        .standardHIIT, .tabata, .beginnerHIIT, .advancedHIIT,
        .emom12, .amrap10, .countdown5
    ]
}
