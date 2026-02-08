# Repeat

Free, no-nonsense iOS daily habits tracker.

Repeat is built for quick daily check-ins with zero clutter: add habits, check them off, and see completion history in a clean visual format.

## Principles

- Free
- Offline-first
- No account required
- Fast daily flow
- No fluff

## Status

This project is currently in scaffold phase. The roadmap below defines the next implementation targets.

## Roadmap

- [ ] Mark habits as completed
- [ ] Add new habits
- [ ] Set habit emoji with an emoji selector
- [ ] Re-order habits
- [ ] Horizontal full-page swiper interface
- [ ] Scroll down (swipe up) to view a day-by-day habit completion visualization
- [ ] Visualization layout: each row represents one day
- [ ] Row fill represents percent of habits completed for that day (`x` = completed portion, blank = remaining/incomplete)
- [ ] Use full-width rows with fixed height
- [ ] Use only solid primary green fill for completion bars (no borders, shadows, or extra styling)
- [ ] Lock screen widgets
- [ ] Home widgets (check-off and visualization)
- [ ] iCloud sync (backup)

## Visualization concept

Each row is a day, and the filled portion shows completion percentage:

[xxxxx            ]  
[xxxxxxxxxxx]  
[                     ]  
[xxx               ]

## Run locally

1. Open `Repeat.xcodeproj` in Xcode.
2. Choose an iOS Simulator or connected device.
3. Press Run (`Cmd+R`).

## Quality checks

- `make lint` runs SwiftLint.
- `make lint-format` runs SwiftFormat in lint mode.
- `make format` applies SwiftFormat fixes.
- `make test` runs the test suite with `xcodebuild` using destination `platform=iOS Simulator,OS=26.2,name=iPhone 17 Pro`.

## Tech stack

- Swift
- SwiftUI
- SwiftData
- Xcode project: `Repeat.xcodeproj`
