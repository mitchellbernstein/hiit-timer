# Agent-friendly Xcode build for HIIT Timer
# Usage:
#   make build    — build for iOS Simulator
#   make run      — build, boot simulator, install & launch
#   make clean    — clean build folder

SCHEME := HIITTimer
PROJECT := HIITTimer.xcodeproj
DESTINATION := platform=iOS Simulator,name=iPhone 17
DERIVED := .build
SIM_UDID := $(shell xcrun simctl list devices available | grep "iPhone 17 (" | head -1 | sed -E 's/.*\\(([A-F0-9-]+)\\).*/\\1/')
BUNDLE_ID := com.mitchellbernstein.hiittimer

.PHONY: build run clean project

# Default: build
all: build

project:
	xcodegen generate

build: project
	set -o pipefail && xcodebuild build \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination '$(DESTINATION)' \
		-derivedDataPath $(DERIVED) 2>&1 | tail -5

run: build
	@echo "Booting simulator..."
	xcrun simctl boot $(SIM_UDID) 2>/dev/null || true
	xcrun simctl bootstatus $(SIM_UDID) -b
	@echo "Installing..."
	xcrun simctl install booted $(DERIVED)/Build/Products/Debug-iphonesimulator/$(SCHEME).app
	@echo "Launching..."
	xcrun simctl launch booted $(BUNDLE_ID)
	@echo "Done! App is running on simulator."

clean:
	rm -rf $(DERIVED)
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) clean 2>/dev/null || true
