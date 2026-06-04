# RummyTracker

iOS app for tracking Indian Rummy scores across multiple players and games.

## Project info

- **Platform:** iOS 26.5+, Swift 5, SwiftUI
- **Bundle ID:** com.SriramG.RummyScorer.RummyTracker
- **Version:** 1.0
- **GitHub:** https://github.com/sgummadala/RummyTracker

## Build

Open `RummyTracker.xcodeproj` in Xcode and run on a simulator or device. No code signing required — all configurations use `CODE_SIGNING_REQUIRED = NO`.

```bash
xcodebuild -scheme RummyTracker -destination 'platform=iOS Simulator,name=iPhone 17' build
```

No external dependencies — pure SwiftUI, no CocoaPods or SPM packages.

## Architecture

Single-target SwiftUI app using the `@Observable` macro (Swift 6 / iOS 17+ observation framework). Two environment objects flow through the entire app:

- `GameStore` — all game data + persistence
- `ThemeManager` — selected color theme + persistence

**Key Swift 6 settings in use:**
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — all code is implicitly `@MainActor`
- `SWIFT_APPROACHABLE_CONCURRENCY = YES` — use `@Observable`, not `ObservableObject`

Both classes are injected at app launch:
```swift
ContentView()
    .environment(store)
    .environment(themeManager)
```

## File map

| File | Role |
|------|------|
| `GameStore.swift` | `Game`, `Round`, `GameRules` models + `@Observable GameStore` with UserDefaults persistence |
| `Theme.swift` | `ThemeDefinition` (all color tokens per theme) + `@Observable ThemeManager` + 5 preset themes + `Layout` constants |
| `RummyTrackerApp.swift` | App entry; creates `GameStore` + `ThemeManager`, injects both via `.environment()` |
| `ContentView.swift` | Root view; renders `HomeView` |
| `HomeView.swift` | Home screen with 3 action buttons, Past Games sheet, palette icon for theme picker |
| `NewGameView.swift` | `NewGameFlow` coordinator sheet: manages navigation path from Add Players → Set Rules → starts game, then navigates to `GameView` via `@Binding var navigateToGameId` |
| `AddPlayersView.swift` | Player setup: text input, vertical Recent Players list, vertical added-players list with toggle (In/Out) + swipe/tap delete |
| `GameRulesView.swift` | Configurable rules: Drop, Mid Drop, Full Score, Game Score inputs |
| `GameView.swift` | Score table (rows = rounds, columns = players), sticky header via `LazyVStack pinnedViews`, `GeometryReader` for dynamic column widths, two FABs |
| `AddRoundView.swift` | Round entry sheet: Won / Drop / Mid / Full / Count buttons per player; editing an existing round pre-populates |
| `ThemePickerView.swift` | 2-column grid of theme cards with gradient swatch + mini table preview; accessible from home toolbar |

## Data model

```
GameRules (Codable)
  drop: Int        // default 25
  midDrop: Int     // default 50
  fullScore: Int   // default 80
  gameScore: Int   // default 250 — outThreshold = gameScore + 1

Game (Codable, Identifiable, Hashable)
  id: UUID
  createdAt: Date
  playerNames: [String]
  rules: GameRules
  rounds: [Round]
  isComplete: Bool

Round (Codable, Identifiable)
  id: UUID
  scores: [String: Int]   // playerName → points (0 = round winner)
```

Persistence keys (UserDefaults):
- `rummy_games_v1` — `[Game]` JSON
- `rummy_saved_players` — `[String]` player name history
- `selected_theme` — `String` theme ID

## Game rules (Indian Rummy)

- 2–7 players. Each round one player wins (0 pts); others score their unmelded card count.
- Score types: Won (0) · Drop (25) · Mid Drop (50) · Full Score (80) · Count (custom).
- Game ends automatically when any player's total reaches `gameScore + 1`.
- Winner = player with the **lowest** total.
- All four rule values are configurable per game via `GameRules`.

## Theming

5 built-in themes, user-selectable from the palette icon on the home screen:

| ID | Name | Feel |
|----|------|------|
| `classic` | Classic | Blue → purple → salmon |
| `royal_dark` | Royal Dark | Dark navy with gold |
| `emerald` | Emerald | Forest green card-table |
| `midnight_ocean` | Midnight Ocean | Deep navy-blue with cyan |
| `crimson` | Crimson Night | Dark charcoal with orange-red |

Each `ThemeDefinition` exposes: `gradient`, `tableNavy`, `tableGreen`, `tableGreenLight`, `buttonDark`, `gold`.

In views, access via:
```swift
@Environment(ThemeManager.self) private var tm
private var t: ThemeDefinition { tm.theme }
// Use t.gradient, t.tableGreen, t.gold, etc.
```

## Score table layout

- Rows = rounds, columns = players (matches reference app style).
- Column widths computed dynamically: `playerWidth = (screenWidth - 46) / playerCount` — all 7 players fit without horizontal scroll.
- Sticky header via `LazyVStack(pinnedViews: .sectionHeaders)`.
- Tap any round row to edit it (opens `AddRoundView` pre-populated).

## Conventions

- Use `@Observable` — never `ObservableObject` / `@Published` / `@EnvironmentObject`.
- Inject via `.environment(x)`, read via `@Environment(X.self)`.
- New Swift files in `RummyTracker/` are auto-included (`PBXFileSystemSynchronizedRootGroup`).
- Gradient backgrounds: always wrap with `ZStack { t.gradient.ignoresSafeArea(); NavigationStack { ... } }` — putting the gradient inside the `NavigationStack` collapses `ScrollView` height.
- No comments unless the WHY is non-obvious.
