import Foundation

@MainActor
@Observable
final class PresetStore {
    private(set) var presets: [WorkoutPreset] = []
    private let storageKey = "hiit_timer_presets"

    init() {
        loadPresets()
        if presets.isEmpty {
            presets = WorkoutPreset.defaultPresets
            savePresets()
        }
    }

    func addPreset(_ preset: WorkoutPreset) {
        presets.append(preset)
        savePresets()
    }

    func updatePreset(_ preset: WorkoutPreset) {
        if let index = presets.firstIndex(where: { $0.id == preset.id }) {
            presets[index] = preset
            savePresets()
        }
    }

    func deletePreset(_ preset: WorkoutPreset) {
        presets.removeAll { $0.id == preset.id }
        savePresets()
    }

    func resetToDefaults() {
        presets = WorkoutPreset.defaultPresets
        savePresets()
    }

    private func loadPresets() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            presets = try JSONDecoder().decode([WorkoutPreset].self, from: data)
        } catch {
            presets = []
        }
    }

    private func savePresets() {
        guard let data = try? JSONEncoder().encode(presets) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
