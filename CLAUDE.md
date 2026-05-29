# HIIT Timer

To build, verify via SwiftPM:

```
make build
```

For iOS simulator / device, open in Xcode and select the HIITTimer scheme. The project is a Swift Package — Xcode resolves dependencies automatically.

### iOS Simulator build (if xcodeproj exists):
```
xcodebuild -project HIITTimer.xcodeproj -scheme HIITTimer -destination 'platform=iOS Simulator,name=iPhone 17' build
```
