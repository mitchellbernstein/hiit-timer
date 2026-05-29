import Foundation

struct WorkoutRecord: Identifiable, Codable, Equatable {
    var id = UUID()
    var presetName: String
    var workoutType: WorkoutType
    var durationSeconds: Int
    var completedAt: Date

    var formattedDuration: String {
        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }

    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: completedAt, relativeTo: Date())
    }
}

@MainActor
@Observable
final class HistoryStore {
    private(set) var records: [WorkoutRecord] = []
    private let storageKey = "hiit_timer_history"

    init() {
        load()
    }

    func addRecord(_ record: WorkoutRecord) {
        records.insert(record, at: 0)
        if records.count > 200 { records = Array(records.prefix(200)) }
        save()
    }

    var totalWorkouts: Int { records.count }

    var totalMinutes: Int { records.reduce(0) { $0 + $1.durationSeconds } / 60 }

    var weeklyWorkouts: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return records.filter { $0.completedAt >= weekAgo }.count
    }

    var currentStreak: Int {
        var streak = 0
        let calendar = Calendar.current
        var date = Date()

        while true {
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? date
            let hasWorkout = records.contains { $0.completedAt >= dayStart && $0.completedAt < dayEnd }

            if hasWorkout {
                streak += 1
                date = calendar.date(byAdding: .day, value: -1, to: date) ?? date
            } else if streak == 0 {
                date = calendar.date(byAdding: .day, value: -1, to: date) ?? date
            } else {
                break
            }
        }
        return streak
    }

    var recentRecords: [WorkoutRecord] {
        Array(records.prefix(10))
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        records = (try? JSONDecoder().decode([WorkoutRecord].self, from: data)) ?? []
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
