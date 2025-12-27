# HanLy – Real-time Streaming Architecture (Frontend-only)

## Goals (what “streaming” means in this app)
- **No pull-to-refresh**: user never needs to manually reload to see updates.
- **Push updates to UI**: data changes propagate automatically and smoothly.
- **Partial rebuilds**: only the widgets that depend on changed fields rebuild.
- **Calm micro-animations**: number/progress/list changes animate subtly (150–300ms).
- **Memory safe**: no leaked timers/streams; pause in background; resume in foreground.

## Constraints (hard rules)
- **Frontend only** (no backend edits).
- **GetX** for state, **GetStorage** for local persistence.
- **Dio** only for networking (auth + refresh interceptors already exist).

## Audit highlights (current problems)
- **Manual refresh everywhere**: multiple screens use `RefreshIndicator`, and `ShellController` refreshes when tapping the same tab again.
- **No single source of truth**:
  - `/today` is fetched independently in `TodayController`, `MeController`, `ProgressController`, etc.
  - This creates drift: streak/progress can be inconsistent between tabs.
- **Stale UI after actions**:
  - Many screens rely on “refresh after navigating back”.
  - Session completion triggers ad-hoc refresh logic rather than a unified pipeline.
- **Limited diffing**:
  - Data is often reassigned, which can trigger larger rebuilds than necessary.

## Chosen real-time strategy (FE-only, best fit)
### 1) Smart background polling + diff-based updates (primary)
- Poll key endpoints on a schedule **only while logged-in + foreground + online**.
- Use **diff fingerprints** (e.g., `jsonEncode(model.toJson())`) to update Rx only when payload changes.
- Result: UI feels “live” without backend WS/SSE.

### 2) Event-driven sync for user actions (secondary)
- When user performs actions (finish session, toggle favorite, update profile), we:
  - update local Rx optimistically where safe
  - trigger **targeted syncNow()** for affected resources

### 3) Local tickers for time-based UI
- Some UI changes are time-based (e.g., streak “time until lose”).
- Use a light local ticker (e.g., 30–60s) to update derived countdown text without hitting backend.

## Mandatory data flow (enforced)
Backend → Dio (ApiClient) → Repository → **Realtime Store (Rx)** → Controller → UI (Obx)

- ❌ No API calls inside Widgets
- ✅ Controllers orchestrate navigation and user intent
- ✅ Stores own state + syncing (single source of truth)

## Core building blocks to implement
### `RealtimeResource<T>`
Generic resource wrapper:
- Holds `Rxn<T> data`, `isBootstrapping`, `isSyncing`, `lastError`
- Has `syncNow()` that:
  - fetches from repository
  - compares fingerprint
  - updates Rx only when changed
- Runs on a periodic timer (interval varies by resource priority)

### `RealtimeSyncService` (GetxService)
Central scheduler:
- Starts/stops resources based on:
  - auth state (logged in/out)
  - app lifecycle (foreground/background)
  - connectivity (online/offline)
- Exposes `syncNowAll()` and `syncNow(keys…)` for targeted refresh after actions.

### Domain stores (single source of truth)
Initial priority:
- `TodayStore` (GET `/today`, plus local ticker for streak countdown)
- `StudyModesStore` (GET `/study-modes`, optional)
- `UserStore` (GET `/me`, or reuse `AuthSessionService` with periodic refresh)

Next:
- `FavoritesStore` (GET `/favorites`)
- `DecksStore` (GET `/decks`)
- `StatsStore` (GET `/me/stats`, `/me/calendar`, etc.)
- `LeaderboardStore` (poll only while leaderboard screen active)

## Migration plan (step-by-step)
1) Implement realtime core (`RealtimeResource`, `RealtimeSyncService`) + register services in `main.dart`.
2) Create `TodayStore` and refactor:
   - `TodayController`, `MeController`, `ProgressController` to read from **TodayStore** (stop fetching `/today` themselves).
3) Remove `RefreshIndicator` usage across screens; replace with auto-sync (and optional passive “syncing” indicator if needed).
4) Wire session completion (Practice/Session flows) to trigger `syncNow()` for Today/User/Stats.
5) Add calm animations for changing numbers/progress and lists.
6) Add tests for diffing + sync lifecycle and regressions for learning flow.


