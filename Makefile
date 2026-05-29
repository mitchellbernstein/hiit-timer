# Agent-friendly Xcode build for HIIT Timer
# Usage:
#   make build    — build only
#   make test     — run tests
#   make clean    — clean build folder

SCHEME := HIITTimer
DESTINATION := platform=iOS Simulator,name=iPhone 17

.PHONY: build test clean

build:
	swift build 2>&1 | xcbeautify

test:
	swift test 2>&1 | xcbeautify

clean:
	swift package clean
	rm -rf .build
