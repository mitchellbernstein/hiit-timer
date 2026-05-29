# HIIT Timer

A beautiful, elegant High-Intensity Interval Training timer for iOS 26+ with Liquid Glass design, Apple Music integration, and large touch-friendly controls optimized for workout use.

## Features

- **5 Workout Modes**: Intervals, Tabata (20/10), EMOM, AMRAP, Countdown
- **Liquid Glass UI**: iOS 26 Liquid Glass throughout with progressive blurs
- **Apple Music Integration**: Search and play workout music with album artwork behind the timer
- **Large Buttons**: Optimized for sweaty, tired fingers during workouts
- **Multi-Sensory Feedback**: Haptic patterns, audio cues, and phase color changes
- **Floating Player**: Mini music player in the tab bar accessory
- **Presets**: Save and reuse your favorite workouts
- **Dark Mode**: Always-dark interface for gym and low-light environments
- **Background Audio**: Timer runs in background with music

## Workout Modes

| Mode | Description | Default |
|------|-------------|---------|
| **Intervals** | Alternating work/rest periods with configurable ratios | 40s work/20s rest × 8 |
| **Tabata** | Classic 20s work/10s rest × 8 rounds | Fixed protocol |
| **EMOM** | Every Minute on the Minute | 12 minutes |
| **AMRAP** | As Many Rounds As Possible | 10 minutes |
| **Countdown** | Simple countdown timer | 5 minutes |

## Tech Stack

- Swift 6.3, SwiftUI, iOS 26+
- Liquid Glass (.glassEffect, GlassEffectContainer)
- MusicKit + ApplicationMusicPlayer
- CoreHaptics for haptic feedback
- AVFoundation for audio cues
- @Observable MV architecture

## Build

```bash
# Build for iOS Simulator
swift build --sdk $(xcrun --show-sdk-path --sdk iphonesimulator) --triple arm64-apple-ios-simulator

# Or use Makefile
make build
```

Open in Xcode to run on simulator or device.

## Project Structure

```
Sources/HIITTimer/
├── HIITTimerApp.swift          # App entry point
├── Models/
│   ├── WorkoutType.swift       # Interval, Tabata, EMOM, AMRAP, Countdown
│   ├── TimerPhase.swift        # Warmup, Work, Rest, Cooldown, Complete
│   ├── WorkoutPreset.swift     # Saved workout configurations
│   └── TimerEngine.swift       # Core timer @Observable engine
├── Services/
│   ├── HapticService.swift     # CoreHaptics feedback
│   ├── AudioFeedbackService.swift  # AVFoundation sounds
│   ├── MusicService.swift      # MusicKit / Apple Music
│   └── PresetStore.swift       # UserDefaults persistence
├── Views/
│   ├── ContentView.swift       # Tab view with floating player
│   ├── TimerView.swift         # Main workout timer
│   ├── PresetsView.swift       # Workout preset management
│   ├── MusicView.swift         # Music search and playback
│   └── Components/
│       ├── LargeCountdownDisplay.swift  # Full-screen countdown
│       ├── ControlButton.swift          # Large glass buttons
│       ├── AlbumArtBackground.swift     # Artwork behind timer
│       └── IntervalProgressBar.swift    # Visual progress
```

## Setup

1. Enable MusicKit App Service in Apple Developer portal for your bundle ID
2. Add `NSAppleMusicUsageDescription` to Info.plist
3. Enable Background Audio capability for background playback
