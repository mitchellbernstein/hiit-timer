import SwiftUI

struct PresetsView: View {
    @Environment(PresetStore.self) private var presetStore
    @Environment(TimerEngine.self) private var timer
    @State private var showCreator = false
    @State private var editingPreset: WorkoutPreset?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(presetStore.presets) { preset in
                        presetRow(preset)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(.black)
            .navigationTitle("Presets")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreator = true
                    } label: {
                        Image(systemName: "plus")
                            .glassEffect(.regular.interactive(), in: .circle)
                    }
                }
            }
            .sheet(isPresented: $showCreator) {
                PresetEditorView { newPreset in
                    presetStore.addPreset(newPreset)
                }
            }
        }
    }

    private func presetRow(_ preset: WorkoutPreset) -> some View {
        Button {
            timer.preset = preset
            timer.reset()
        } label: {
            HStack(spacing: 16) {
                Image(systemName: preset.type.systemImage)
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 44, height: 44)
                    .glassEffect(.regular, in: .circle)

                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.name)
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white)

                    Text(preset.type.rawValue)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                Text(preset.formattedTotalDuration)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .glassEffect(.regular, in: .capsule)

                if timer.preset.id == preset.id {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.green)
                        .padding(8)
                        .glassEffect(.regular.tint(.green.opacity(0.3)), in: .circle)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                presetStore.deletePreset(preset)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct PresetEditorView: View {
    let onSave: (WorkoutPreset) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var type: WorkoutType = .intervals
    @State private var workSeconds = 40
    @State private var restSeconds = 20
    @State private var rounds = 8
    @State private var warmupSeconds = 30
    @State private var cooldownSeconds = 30
    @State private var emomMinutes = 12
    @State private var amrapMinutes = 10

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Workout Name", text: $name)
                }

                Section("Type") {
                    Picker("Mode", selection: $type) {
                        ForEach(WorkoutType.allCases) { type in
                            Label(type.rawValue, systemImage: type.systemImage)
                                .tag(type)
                        }
                    }
                }

                Section("Timing") {
                    switch type {
                    case .intervals:
                        Stepper("Work: \(workSeconds)s", value: $workSeconds, in: 5...120, step: 5)
                        Stepper("Rest: \(restSeconds)s", value: $restSeconds, in: 5...120, step: 5)
                        Stepper("Rounds: \(rounds)", value: $rounds, in: 1...30)
                        Stepper("Warmup: \(warmupSeconds)s", value: $warmupSeconds, in: 0...120, step: 5)
                        Stepper("Cooldown: \(cooldownSeconds)s", value: $cooldownSeconds, in: 0...120, step: 5)
                    case .tabata:
                        Text("Fixed: 20s work / 10s rest × 8 rounds")
                            .foregroundStyle(.secondary)
                        Stepper("Warmup: \(warmupSeconds)s", value: $warmupSeconds, in: 0...120, step: 5)
                        Stepper("Cooldown: \(cooldownSeconds)s", value: $cooldownSeconds, in: 0...120, step: 5)
                    case .emom:
                        Stepper("Interval: 60s", value: .constant(60), in: 30...120, step: 5)
                            .disabled(true)
                        Stepper("Total: \(emomMinutes) min", value: $emomMinutes, in: 1...60)
                    case .amrap:
                        Stepper("Duration: \(amrapMinutes) min", value: $amrapMinutes, in: 1...60)
                    case .countdown:
                        Stepper("Duration: \(amrapMinutes) min", value: $amrapMinutes, in: 1...60)
                    }
                }
            }
            .navigationTitle("New Preset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newPreset = WorkoutPreset(
                            name: name.isEmpty ? "Custom \(type.rawValue)" : name,
                            type: type,
                            workSeconds: workSeconds,
                            restSeconds: restSeconds,
                            rounds: rounds,
                            warmupSeconds: warmupSeconds,
                            cooldownSeconds: cooldownSeconds,
                            emomTotalMinutes: emomMinutes,
                            amrapMinutes: amrapMinutes,
                            countdownSeconds: amrapMinutes * 60
                        )
                        onSave(newPreset)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
