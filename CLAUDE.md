# RummyTracker

iOS app for tracking Indian Rummy scores across multiple players and games.

## Project info

- **Platform:** iOS 26.5+, Swift 5, SwiftUI
- **Bundle ID:** com.SriramG.RummyScorer.RummyTracker
- **Version:** 1.0
- **GitHub:** https://github.com/sgummadala/RummyTracker

## Build

Open `RummyTracker.xcodeproj` in Xcode and run on a simulator or device.

```bash
xcodebuild -scheme RummyTracker -destination 'platform=iOS Simulator,name=iPhone 17' build
```

No external dependencies — pure SwiftUI, no CocoaPods or SPM packages.

## Architecture

Single-target SwiftUI app using the `@Observable` macro (Swift 6 / iOS 17+ observation framework). All state lives in `GameStore` and flows down via `.environment(store)`.

**Key Swift 6 settings in use:**
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — all code is implicitly `@MainActor`
- `SWIFT_APPROACHABLE_CONCURRENCY = YES` — use `@Observable`, not `ObservableObject`

## File map

| File | Role |
|------|------|
| `GameStore.swift` | `Game` + `Round` models (Codable) and `@Observable GameStore` with UserDefaults persistence |
| `RummyTrackerApp.swift` | App entry point; injects `GameStore` via `.environment(store)` |
| `ContentView.swift` | Root view; hosts `HomeView` |
| `HomeView.swift` | Game list, empty state, swipe-to-delete, navigation to `GameView` |
| `NewGameView.swift` | New game sheet — player names (2–6) and target score (101 or 201) |
| `GameView.swift` | Score table with per-round scores, cumulative subtotals, leader crown, totals row, Add Round / End Game actions |
| `AddRoundView.swift` | Round entry sheet — score per player, shows current totals, warns on invalid winner count |

## Data model

```
Game
  id: UUID
  createdAt: Date
  playerNames: [String]
  targetScore: Int          // 101 or 201
  rounds: [Round]
  isComplete: Bool

Round
  id: UUID
  scores: [String: Int]     // playerName → points lost (0 = round winner)
```

Persistence: `JSONEncoder` → `UserDefaults` key `rummy_games_v1`.

## Game rules (Indian Rummy)

- 2–6 players; each round one player wins (scores 0), others count unmelded card points.
- Game ends automatically when any player's cumulative score reaches or exceeds the target.
- Winner = player with the **lowest** total score when the game ends.

## Conventions

- Use `@Observable` — never `ObservableObject` / `@Published` / `@EnvironmentObject`.
- Inject store with `.environment(store)` and read with `@Environment(GameStore.self)`.
- New Swift files dropped in `RummyTracker/` are picked up automatically (project uses `PBXFileSystemSynchronizedRootGroup`).
- No comments unless the WHY is non-obvious.
