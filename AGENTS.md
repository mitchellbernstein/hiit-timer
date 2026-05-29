# HIIT Timer — Project Context

## Tech
- Swift 6.3, SwiftUI, iOS 26+
- MV architecture with @Observable models
- Liquid Glass (.glassEffect, GlassEffectContainer)
- MusicKit + ApplicationMusicPlayer
- CoreHaptics, AVFoundation

## Build
```bash
make build  # macOS verification
# For iOS: open in Xcode (no xcodeproj yet — SwiftPM package)
```

## Rules
- Always use @Observable (not ObservableObject)
- @MainActor on all @Observable classes
- Liquid Glass: .glassEffect() goes AFTER layout modifiers
- Large tap targets (≥44pt) — this is a workout app
- Use .buttonStyle(.plain) for custom glass buttons
- Omit stack spacing unless specific value required
