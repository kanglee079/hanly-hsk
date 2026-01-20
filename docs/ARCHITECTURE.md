# HanLy Architecture - Offline-First Design

## 📋 Overview

HanLy implements an **offline-first architecture** for vocabulary learning. The app prioritizes local data access for instant performance while syncing with the backend for user progress and authentication.

## 🎯 Design Principles

1. **Local-First**: All vocabulary data is stored locally in SQLite
2. **Instant Performance**: No network latency for browsing/searching vocab
3. **Background Sync**: User progress syncs to server non-blocking
4. **Minimal API Calls**: Backend only handles auth, progress sync, and data updates

---

## 📊 Data Flow

```
┌──────────────────────────────────────────────────────────────┐
│                         APP LAUNCH                            │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────┐  │
│  │   SQLite    │    │ GetStorage  │    │   API Client    │  │
│  │  (Vocabs)   │    │  (Prefs)    │    │   (Network)     │  │
│  └──────┬──────┘    └──────┬──────┘    └────────┬────────┘  │
│         │                   │                    │           │
│         ▼                   ▼                    ▼           │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              VocabLocalDataSource                     │   │
│  │  • getVocabs()     • searchVocabs()                  │   │
│  │  • getFavorites()  • updateProgress()                │   │
│  └──────────────────────────────────────────────────────┘   │
│         │                                                    │
│         ▼                                                    │
│  ┌──────────────────────────────────────────────────────┐   │
│  │               Controllers (GetX)                      │   │
│  │  ExploreController, TodayController, etc.            │   │
│  └──────────────────────────────────────────────────────┘   │
│         │                                                    │
│         ▼                                                    │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                 UI Widgets                            │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

---

## 💾 Local Database Schema

### `vocabs` Table
Stores ~5000 vocabulary items (shipped with app)

| Column | Type | Description |
|--------|------|-------------|
| id | TEXT (PK) | Unique vocab ID |
| word | TEXT | Chinese characters (Hanzi) |
| pinyin | TEXT | Pronunciation with tones |
| meaning_vi | TEXT | Vietnamese meaning |
| meaning_en | TEXT | English meaning |
| level | TEXT | HSK1-6 |
| order_in_level | INTEGER | Display order |
| topic | TEXT | Category/topic |
| word_type | TEXT | noun/verb/adj/etc |
| frequency_rank | INTEGER | Usage frequency |
| difficulty | INTEGER | 1-5 scale |
| audio_url | TEXT | TTS audio URL |
| examples | TEXT | JSON array of examples |
| collocations | TEXT | JSON array of collocations |
| stroke_count | INTEGER | Number of strokes |
| mnemonic | TEXT | Memory hint |

### `vocab_progress` Table
User's learning progress (local-first, synced to server)

| Column | Type | Description |
|--------|------|-------------|
| vocab_id | TEXT (PK) | Reference to vocab |
| state | TEXT | new/learning/review/mastered |
| ease_factor | REAL | SRS ease factor |
| interval_days | INTEGER | Current interval |
| due_date | TEXT | Next review date |
| is_favorite | INTEGER | Bookmarked |
| is_locked | INTEGER | Content locked until unlocked |
| synced | INTEGER | 0=pending, 1=synced |

### `settings` Table
App settings and metadata

| Column | Type | Description |
|--------|------|-------------|
| key | TEXT (PK) | Setting name |
| value | TEXT | Setting value |

---

## 🌐 API Endpoints (Minimal)

### REQUIRED (Online-only)
| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/auth/anonymous` | POST | Device-based auth |
| `/auth/register` | POST | Email registration |
| `/auth/login` | POST | Email login |
| `/auth/refresh` | POST | Token refresh |
| `/me` | GET | User profile |
| `/me/profile` | PUT | Update profile |
| `/me/avatar` | POST | Upload avatar |
| `/me/notifications` | GET/POST | Notification settings |
| `/me/advance-level` | POST | Advance to next HSK level |
| `/review/answer` | POST | Submit SRS answer |
| `/session/finish` | POST | Complete session |

### OPTIONAL (Cached/Rare)
| Endpoint | Method | Cache TTL | Purpose |
|----------|--------|-----------|---------|
| `/today` | GET | 5 min | Daily learning queue |
| `/collections` | GET | 24h | Collection list |
| `/dashboard` | GET | 5 min | Home screen data |

### REMOVED (Now Local)
| Old Endpoint | Replacement |
|--------------|-------------|
| `/vocabs` | `VocabLocalDataSource.getVocabs()` |
| `/vocabs/search` | `VocabLocalDataSource.searchVocabs()` |
| `/vocabs/:id` | `VocabLocalDataSource.getVocabById()` |
| `/vocabs/meta/topics` | `VocabLocalDataSource.getTopics()` |

---

## 🔄 Sync Strategy

### Progress Sync (Local → Server)
```dart
// ProgressSyncService runs every 5 minutes
1. Query unsynced entries (synced = 0)
2. Batch POST to /sync/progress
3. Mark as synced (synced = 1)
4. On conflict: server wins for SRS, client wins for favorites
```

### Dataset Updates (Server → Local)
```dart
// Check on app launch (max once per day)
1. GET /dataset/version
2. Compare with local settings.dataset_version
3. If newer: download delta or full bundle
4. Apply updates to local DB
```

---

## 🚀 Performance Optimizations

### 1. Request Deduplication
```dart
// RequestGuard prevents duplicate API calls
await RequestGuard.dedupe('collections', () => fetchCollections());
```

### 2. Memoization with TTL
```dart
// Cache results for specified duration
await RequestGuard.memoize('collections', fetchCollections, ttl: 24.hours);
```

### 3. Throttling
```dart
// Prevent rapid-fire requests
await RequestGuard.throttle('refresh', refreshData, minInterval: 5.seconds);
```

### 4. Polling Optimization
```
BEFORE: /today polled every 15 seconds (240 calls/hour)
AFTER:  /today polled every 5 minutes (12 calls/hour)
SAVINGS: 95% reduction in API calls
```

---

## 📦 Database Generation

### Generate SQLite from Backend
```bash
# Install http package
dart pub add http --dev

# Run generation script
dart run scripts/generate_vocab_db.dart

# Output: assets/database/hanly_vocab.db
```

### First Launch Flow
```dart
1. Check if DB exists in app documents
2. If not: copy from assets/database/
3. Open database
4. Log vocab count for verification
```

---

## 🔒 Content Locking

### Progressive Unlock System
```sql
-- First 20 words of HSK1 unlocked by default
-- Unlock next batch after mastering 80%+
SELECT COUNT(*) FROM vocab_progress 
WHERE is_locked = 0 AND state = 'mastered';
```

### Unlock Rules
| Level | Initial Unlock | Unlock Threshold |
|-------|----------------|------------------|
| HSK1 | 20 words | Master 16+ to unlock next 20 |
| HSK2+ | 0 words | Complete previous level |

---

## 📊 Metrics

### Before Optimization
- API calls at launch: ~15
- Poll interval: 15 seconds
- Search latency: 200-500ms (network)
- Offline support: None

### After Optimization
- API calls at launch: 3-5
- Poll interval: 5 minutes
- Search latency: <50ms (local)
- Offline support: Full vocab access

---

## 🔧 Maintenance

### Updating Vocabulary Data
1. Update vocab in backend database
2. Run `dart run scripts/generate_vocab_db.dart`
3. Commit new `assets/database/hanly_vocab.db`
4. Users get update on next app install/update

### Adding New Features
1. Prioritize local-first approach
2. Use RequestGuard for any API calls
3. Cache aggressively (collections, meta data)
4. Sync progress in background

---

## 📁 File Structure

```
lib/app/
├── data/
│   ├── local/
│   │   ├── database_service.dart      # SQLite management
│   │   └── vocab_local_datasource.dart # Vocab queries
│   ├── repositories/
│   │   └── ...                         # API repos (for sync only)
│   └── models/
│       └── vocab_model.dart            # Shared models
├── services/
│   ├── progress_sync_service.dart      # Background sync
│   └── realtime/
│       └── today_store.dart            # Optimized polling
└── core/
    └── utils/
        └── request_guard.dart          # Dedup/throttle/cache
```
