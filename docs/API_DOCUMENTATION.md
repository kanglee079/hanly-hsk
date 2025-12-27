# 📱 Hanzi Memory API - Frontend Integration Guide

**Base URL:** `https://hanzi-memory-api.onrender.com`  
**Local:** `http://localhost:3000`

---

## 📋 Mục lục

1. [Authentication](#1-authentication)
2. [User Profile & Onboarding](#2-user-profile--onboarding)
3. [User Stats & Achievements](#3-user-stats--achievements)
4. [Account Deletion (Soft Delete)](#4-account-deletion-soft-delete)
5. [Learning (SRS)](#5-learning-srs)
6. [Vocabulary](#6-vocabulary)
7. [Favorites & Decks](#7-favorites--decks)
8. [Collections](#8-collections)
9. [Game & Leaderboard](#9-game--leaderboard)
10. [Pronunciation](#10-pronunciation)
11. [Offline Manager](#11-offline-manager)

---

## Headers Chung

```dart
// Không cần auth
headers: {
  'Content-Type': 'application/json',
}

// Cần auth
headers: {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer $accessToken',
}
```

---

## 1. Authentication

### 1.1 Request Magic Link
```
POST /auth/request-link
```
**Body:**
```json
{
  "email": "user@example.com"
}
```
**Response:**
```json
{
  "success": true,
  "message": "Magic link sent"
}
```

### 1.2 Verify Magic Link
```
GET /auth/verify-link?token=xxx
```
**Response:**
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGc...",
    "refreshToken": "eyJhbGc...",
    "expiresIn": 900,
    "me": {
      "id": "675...",
      "email": "user@example.com",
      "status": "active",
      "createdAt": "2025-12-15T10:00:00.000Z"
    }
  }
}
```

### 1.3 Refresh Token
```
POST /auth/refresh
```
**Body:**
```json
{
  "refreshToken": "eyJhbGc..."
}
```
**Response:**
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGc...",
    "refreshToken": "eyJhbGc...",
    "expiresIn": 900
  }
}
```

### 1.4 Logout
```
POST /auth/logout
```
**Body:**
```json
{
  "refreshToken": "eyJhbGc..."
}
```

---

## 2. User Profile & Onboarding

### 2.1 Get Current User 🔒
```
GET /me
```
**Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "675...",
      "email": "user@example.com",
      "status": "active",
      "deletionScheduledAt": null,
      "createdAt": "2025-12-15T10:00:00.000Z"
    },
    "profile": {
      "displayName": "Minh Anh",
      "avatarUrl": "https://...",
      "onboardingCompleted": true,
      "isPremium": false,
      "premiumExpiresAt": null,
      "goalType": "hsk_exam",
      "currentLevel": "HSK3",
      "targetLevel": "HSK5",
      "dailyMinutesTarget": 15,
      "dailyNewLimit": 5,
      "reviewIntensity": "normal",
      "focusWeights": {
        "listening": 0.2,
        "hanzi": 0.6,
        "meaning": 0.2
      },
      "notificationsEnabled": true,
      "reminderTime": "20:00",
      "soundEnabled": true,
      "hapticsEnabled": true,
      "vietnameseSupport": true,
      "downloadedLevels": ["HSK1", "HSK2"],
      "timezone": "Asia/Ho_Chi_Minh"
    },
    "stats": {
      "totalWords": 150,
      "masteredWords": 30,
      "learningWords": 50,
      "reviewWords": 70,
      "totalSessions": 25,
      "totalMinutes": 300,
      "currentStreak": 7
    }
  }
}
```

### 2.2 Complete Onboarding 🔒
```
POST /me/onboarding
```
**Body:**
```json
{
  "displayName": "Minh Anh",
  "goalType": "hsk_exam",
  "currentLevel": "HSK3",
  "targetLevel": "HSK5",
  "dailyMinutesTarget": 15,
  "focusWeights": {
    "listening": 0.2,
    "hanzi": 0.6,
    "meaning": 0.2
  },
  "notificationsEnabled": true,
  "reminderTime": "20:00",
  "timezone": "Asia/Ho_Chi_Minh"
}
```

**Required fields:**
- `displayName` (1-50 chars)
- `goalType`: `"hsk_exam"` | `"conversation"` | `"both"`
- `currentLevel`: `"HSK1"` - `"HSK6"`
- `dailyMinutesTarget`: 5-120

**Optional fields:**
- `targetLevel` (default: currentLevel + 2)
- `focusWeights` (default: equal weights)
- `notificationsEnabled` (default: false)
- `reminderTime` (default: "20:00")
- `timezone` (default: "Asia/Ho_Chi_Minh")

**Response:**
```json
{
  "success": true,
  "data": {
    "displayName": "Minh Anh",
    "onboardingCompleted": true,
    "goalType": "hsk_exam",
    "currentLevel": "HSK3",
    "targetLevel": "HSK5",
    "dailyMinutesTarget": 15,
    "dailyNewLimit": 5,
    "focusWeights": {...},
    "notificationsEnabled": true,
    "reminderTime": "20:00"
  }
}
```

### 2.3 Update Profile 🔒
```
PUT /me/profile
```
**Body:** (all optional)
```json
{
  "displayName": "New Name",
  "avatarUrl": "https://...",
  "goalType": "both",
  "currentLevel": "HSK4",
  "targetLevel": "HSK6",
  "dailyMinutesTarget": 30,
  "dailyNewLimit": 10,
  "reviewIntensity": "heavy",
  "focusWeights": {
    "listening": 0.4,
    "hanzi": 0.3,
    "meaning": 0.3
  },
  "notificationsEnabled": true,
  "reminderTime": "21:00",
  "soundEnabled": false,
  "hapticsEnabled": true,
  "vietnameseSupport": true,
  "timezone": "Asia/Ho_Chi_Minh"
}
```

---

## 3. User Stats & Achievements

### 3.1 Get User Stats 🔒
```
GET /me/stats
```
**Response:**
```json
{
  "success": true,
  "data": {
    "vocabulary": {
      "total": 150,
      "new": 10,
      "learning": 50,
      "review": 60,
      "mastered": 30
    },
    "study": {
      "totalMinutes": 500,
      "totalHours": 8.3,
      "totalSessions": 30,
      "totalNewLearned": 100,
      "totalReviewed": 500,
      "avgAccuracy": 85,
      "currentStreak": 7,
      "maxStreak": 15
    },
    "games": {
      "speed30s": {
        "totalGames": 10,
        "bestScore": 120,
        "avgScore": 80,
        "avgAccuracy": 85
      },
      "listening": {...},
      "pronunciation": {...},
      "matching": {...}
    },
    "pronunciation": {
      "totalSessions": 15,
      "totalAttempts": 150,
      "totalPassed": 120,
      "avgAccuracy": 80
    },
    "monthlyProgress": [
      {
        "_id": "2025-12",
        "totalMinutes": 200,
        "totalSessions": 10,
        "newLearned": 50,
        "reviewed": 200
      }
    ]
  }
}
```

### 3.2 Get Achievements 🔒
```
GET /me/achievements
```
**Response:**
```json
{
  "success": true,
  "data": {
    "summary": {
      "unlocked": 5,
      "total": 20,
      "percentage": 25
    },
    "achievements": {
      "streak": [
        {
          "id": "streak_7",
          "name": "Tuần Hoàn Hảo",
          "description": "Học 7 ngày liên tiếp",
          "icon": "🔥",
          "target": 7,
          "type": "streak",
          "unlocked": true,
          "unlockedAt": "2025-12-10T10:00:00.000Z",
          "progress": 100
        }
      ],
      "words": [...],
      "game": [...],
      "time": [...],
      "pronunciation": [...]
    },
    "recent": [...]
  }
}
```

**Achievement Categories:**
- `streak` - Chuỗi ngày (3, 7, 30, 100 ngày)
- `words` - Từ đã học (50, 150, 500, 1000, 2500, 5000)
- `game` - Game achievements
- `time` - Thời gian học (1h, 10h, 50h)
- `pronunciation` - Phát âm

### 3.3 Get Learning Calendar 🔒
```
GET /me/calendar?months=3
```
**Response:**
```json
{
  "success": true,
  "data": {
    "calendar": {
      "2025-12-15": {
        "minutes": 15,
        "newCount": 10,
        "reviewCount": 25,
        "accuracy": 85,
        "studied": true
      },
      "2025-12-14": {...}
    },
    "startDate": "2025-09-15",
    "endDate": "2025-12-15"
  }
}
```

---

## 4. Account Deletion (Soft Delete)

### 4.1 Request Deletion 🔒
```
POST /me/request-deletion
```
**Body:**
```json
{
  "reason": "Không còn sử dụng"
}
```
**Response:**
```json
{
  "success": true,
  "data": {
    "message": "Tài khoản sẽ bị xóa vĩnh viễn sau 7 ngày",
    "deletionScheduledAt": "2025-12-23T10:00:00.000Z",
    "daysRemaining": 7
  }
}
```

### 4.2 Cancel Deletion 🔒
```
POST /me/cancel-deletion
```
**Response:**
```json
{
  "success": true,
  "message": "Yêu cầu xóa tài khoản đã được hủy"
}
```

### 4.3 Immediate Delete 🔒
```
DELETE /me
```
⚠️ **Warning:** Xóa ngay lập tức, không thể hoàn tác!

**User Status Values:**
| Status | Mô tả |
|--------|-------|
| `active` | Hoạt động bình thường |
| `pending_deletion` | Đang chờ xóa (7 ngày) |
| `suspended` | Bị đình chỉ |
| `deleted` | Đã xóa |

---

## 5. Learning (SRS)

### 5.1 Get Today Queue 🔒
```
GET /today
```
**Response:**
```json
{
  "success": true,
  "data": {
    "newQueue": [
      {
        "id": "675...",
        "word": "你好",
        "pinyin": "nǐ hǎo",
        "meaning_vi": "Xin chào",
        "meaning_en": "Hello",
        "level": "HSK1",
        "audio_url": "https://...",
        "images": ["https://..."],
        "examples": [...],
        "mnemonic": "...",
        "word_type": "greeting"
      }
    ],
    "reviewQueue": [
      {
        "id": "675...",
        "word": "再见",
        "pinyin": "zài jiàn",
        "meaning_vi": "Tạm biệt",
        "meaning_en": "Goodbye",
        "level": "HSK1",
        "progress": {
          "state": "review",
          "reps": 3,
          "intervalDays": 7,
          "dueDate": "2025-12-15",
          "lastResult": "good"
        }
      }
    ],
    "newCount": 10,
    "reviewCount": 15,
    "masteredCount": 50,
    "totalLearned": 100,
    "streak": 7,
    "streakRank": "top10",
    "totalUsers": 1000,
    "dailyGoalMinutes": 15,
    "completedMinutes": 10,
    "todayAccuracy": 85,
    "newLearned": 5,
    "reviewed": 12,
    "weeklyProgress": [
      {"date": "2025-12-09", "minutes": 15, "newCount": 10, "reviewCount": 20, "accuracy": 80},
      {"date": "2025-12-10", "minutes": 20, "newCount": 15, "reviewCount": 25, "accuracy": 85}
    ]
  }
}
```

### 5.2 Submit Answer 🔒
```
POST /review/answer
```
**Body:**
```json
{
  "vocabId": "675...",
  "rating": "good",
  "mode": "meaning",
  "timeSpent": 5000
}
```

**Rating values:** `"again"` | `"hard"` | `"good"` | `"easy"`

**Response:**
```json
{
  "success": true,
  "data": {
    "vocabId": "675...",
    "newState": "review",
    "newInterval": 4,
    "nextDueDate": "2025-12-19T00:00:00.000Z"
  }
}
```

### 5.3 Finish Session 🔒
```
POST /session/finish
```
**Body:**
```json
{
  "minutes": 15,
  "newCount": 10,
  "reviewCount": 25,
  "accuracy": 85,
  "dateKey": "2025-12-15"
}
```
**Response:**
```json
{
  "success": true,
  "data": {
    "session": {
      "minutes": 15,
      "newCount": 10,
      "reviewCount": 25,
      "accuracy": 85,
      "streak": 8
    },
    "newAchievements": ["streak_7"]
  }
}
```

---

## 6. Vocabulary

### 6.1 List Vocabs
```
GET /vocabs?level=HSK1&topic=greeting&page=1&limit=20&sort=difficulty_score
```
**Query Params:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| level | string | - | `HSK1` - `HSK6` |
| topic | string | - | Topic filter |
| word_type | string | - | noun, verb, etc. |
| diffMin | number | - | Min difficulty |
| diffMax | number | - | Max difficulty |
| sort | string | order_in_level | Sort field |
| order | string | asc | asc/desc |
| page | number | 1 | Page number |
| limit | number | 20 | Items per page (max 100) |

**Response:**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "_id": "675...",
        "word": "你好",
        "pinyin": "nǐ hǎo",
        "meaning_vi": "Xin chào",
        "meaning_en": "Hello",
        "level": "HSK1",
        "subLevel": 1,
        "topics": ["greeting"],
        "images": ["https://..."],
        "examples": [
          {
            "cn": "你好，我是小明。",
            "vi": "Xin chào, tôi là Tiểu Minh.",
            "pinyin": "Nǐ hǎo, wǒ shì Xiǎo Míng."
          }
        ],
        "audio_url": "https://...",
        "audio_slow_url": "https://...",
        "word_type": "greeting",
        "stroke_count": 5,
        "radical": "亻",
        "components": ["亻", "尔"],
        "mnemonic": "Person 亻 waving hello",
        "synonyms": ["您好"],
        "antonyms": ["再见"],
        "collocations": ["你好吗", "大家好"],
        "usage_notes": "Standard greeting",
        "grammar_notes": null,
        "cultural_notes": "Common in formal settings",
        "hsk_tips": "Must know for HSK1",
        "frequency_rank": 1,
        "difficulty_score": 1,
        "is_common": true,
        "hsk_official": true,
        "order_in_level": 1
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 150,
      "totalPages": 8
    }
  }
}
```

### 6.2 Search Vocabs
```
GET /vocabs/search?q=hello&limit=20
```
**Response:** Same as list

### 6.3 Get Vocab by ID
```
GET /vocabs/:id
```
**Response:**
```json
{
  "success": true,
  "data": {
    "_id": "675...",
    "word": "你好",
    ...
  }
}
```

### 6.4 Get Topics
```
GET /vocabs/meta/topics
```
**Response:**
```json
{
  "success": true,
  "data": ["greeting", "family", "food", "travel", ...]
}
```

### 6.5 Get Word Types
```
GET /vocabs/meta/types
```
**Response:**
```json
{
  "success": true,
  "data": ["noun", "verb", "adjective", "adverb", ...]
}
```

---

## 7. Favorites & Decks

### 7.1 Favorites 🔒

**Get Favorites:**
```
GET /favorites
```

**Add Favorite:**
```
POST /favorites/:vocabId
```

**Remove Favorite:**
```
DELETE /favorites/:vocabId
```

### 7.2 Decks 🔒

**List Decks:**
```
GET /decks
```
**Response:**
```json
{
  "success": true,
  "data": [
    {
      "_id": "675...",
      "name": "My Deck",
      "vocabIds": ["675...", "676..."],
      "vocabCount": 2,
      "createdAt": "2025-12-15T10:00:00.000Z"
    }
  ]
}
```

**Create Deck:**
```
POST /decks
Body: { "name": "My Deck" }
```

**Get Deck:**
```
GET /decks/:id
```

**Update Deck:**
```
PUT /decks/:id
Body: { "name": "New Name" }
```

**Delete Deck:**
```
DELETE /decks/:id
```

**Add Vocab to Deck:**
```
POST /decks/:id/add/:vocabId
```

**Remove Vocab from Deck:**
```
POST /decks/:id/remove/:vocabId
```

---

## 8. Collections

### 8.1 List Collections
```
GET /collections
```
**Response:**
```json
{
  "success": true,
  "data": [
    {
      "_id": "hsk1",
      "name": "HSK 1",
      "description": "150 từ cơ bản",
      "level": "HSK1",
      "vocabCount": 150,
      "imageUrl": "https://..."
    }
  ]
}
```

### 8.2 Get Collection
```
GET /collections/:id
```
**Response:** Includes full vocab list

---

## 9. Game & Leaderboard

### 9.1 Get Leaderboard
```
GET /game/leaderboard/:gameType?period=week&limit=100
```

**Path Params:**
- `gameType`: `speed30s` | `listening` | `pronunciation` | `matching`

**Query Params:**
- `period`: `today` | `week` | `month` | `all` (default: `all`)

**Response:**
```json
{
  "success": true,
  "data": {
    "leaderboard": [
      {
        "rank": 1,
        "userId": "675...",
        "displayName": "Mi***@gmail.com",
        "bestScore": 150,
        "bestAccuracy": 95,
        "totalGames": 25
      }
    ],
    "myRank": {
      "rank": 5,
      "bestScore": 100,
      "percentile": 80
    },
    "period": "week",
    "gameType": "speed30s"
  }
}
```

### 9.2 Submit Game 🔒
```
POST /game/submit
```
**Body:**
```json
{
  "gameType": "speed30s",
  "score": 75,
  "correctCount": 15,
  "totalCount": 20,
  "timeSpent": 30000,
  "level": "HSK1"
}
```
**Response:**
```json
{
  "success": true,
  "data": {
    "session": {
      "id": "675...",
      "score": 75,
      "correctCount": 15,
      "totalCount": 20,
      "accuracy": 75,
      "timeSpent": 30000
    },
    "rank": {
      "rank": 5,
      "bestScore": 75,
      "percentile": 60
    },
    "newAchievements": ["game_first", "game_score_50"]
  }
}
```

### 9.3 Get My Game Stats 🔒
```
GET /game/my-stats
```
**Response:**
```json
{
  "success": true,
  "data": {
    "speed30s": {
      "totalGames": 10,
      "bestScore": 120,
      "avgScore": 80,
      "recentGames": [
        {"score": 100, "accuracy": 85, "date": "2025-12-15T10:00:00.000Z"}
      ],
      "rank": {"rank": 3, "bestScore": 120, "percentile": 90}
    },
    "listening": {...},
    "pronunciation": {...},
    "matching": {...}
  }
}
```

---

## 10. Pronunciation

### 10.1 Get Words for Practice 🔒
```
GET /pronunciation/words?level=HSK1&count=10
```
**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "675...",
      "word": "你好",
      "pinyin": "nǐ hǎo",
      "meaning_vi": "Xin chào",
      "meaning_en": "Hello",
      "audio_url": "https://...",
      "audio_slow_url": "https://..."
    }
  ]
}
```

### 10.2 Evaluate Pronunciation 🔒
```
POST /pronunciation/evaluate
```
**Body:**
```json
{
  "vocabId": "675...",
  "spokenText": "ni hao"
}
```
OR
```json
{
  "vocabId": "675...",
  "manualScore": 85
}
```
**Response:**
```json
{
  "success": true,
  "data": {
    "vocabId": "675...",
    "word": "你好",
    "expectedPinyin": "nǐ hǎo",
    "score": 85,
    "passed": true,
    "feedback": "Tốt lắm! Phát âm gần như chuẩn.",
    "passThreshold": 70
  }
}
```

**Feedback levels:**
- ≥90: "Xuất sắc! Phát âm rất chuẩn!"
- 80-89: "Tốt lắm! Phát âm gần như chuẩn."
- 70-79: "Khá tốt! Vẫn cần luyện tập thêm." ✅ Pass
- 50-69: "Cần cải thiện. Hãy nghe lại audio và thử lại."
- <50: "Phát âm chưa đúng. Hãy nghe kỹ audio và luyện tập thêm."

### 10.3 Submit Session 🔒
```
POST /pronunciation/session
```
**Body:**
```json
{
  "attempts": [
    {
      "vocabId": "675...",
      "score": 85,
      "passed": true,
      "feedback": "Tốt!"
    }
  ],
  "level": "HSK1"
}
```
**Response:**
```json
{
  "success": true,
  "data": {
    "session": {
      "id": "675...",
      "passedCount": 8,
      "totalCount": 10,
      "accuracy": 80,
      "totalScore": 750
    },
    "newAchievements": ["pronunciation_first"]
  }
}
```

### 10.4 Get History 🔒
```
GET /pronunciation/history?limit=10
```
**Response:**
```json
{
  "success": true,
  "data": {
    "sessions": [
      {
        "id": "675...",
        "passedCount": 8,
        "totalCount": 10,
        "accuracy": 80,
        "level": "HSK1",
        "date": "2025-12-15T10:00:00.000Z"
      }
    ],
    "stats": {
      "totalSessions": 15,
      "totalAttempts": 150,
      "totalPassed": 120,
      "avgAccuracy": 80
    }
  }
}
```

---

## 11. Offline Manager

### 11.1 Get Bundles
```
GET /offline/bundles
```
**Response:**
```json
{
  "success": true,
  "data": {
    "bundles": [
      {
        "level": "HSK1",
        "name": "HSK 1 - Basic",
        "wordCount": 150,
        "estimatedSizeMB": 15,
        "isDownloaded": true
      },
      {
        "level": "HSK2",
        "name": "HSK 2 - Elementary",
        "wordCount": 300,
        "estimatedSizeMB": 22,
        "isDownloaded": false
      }
    ],
    "summary": {
      "downloadedCount": 1,
      "totalCount": 6,
      "downloadedSizeMB": 15,
      "availableSizeMB": 582
    }
  }
}
```

### 11.2 Get Bundle Data
```
GET /offline/bundle/:level
```
**Response:**
```json
{
  "success": true,
  "data": {
    "level": "HSK1",
    "wordCount": 150,
    "vocabs": [...]
  }
}
```

### 11.3 Get Topics
```
GET /offline/topics
```
**Response:**
```json
{
  "success": true,
  "data": {
    "topics": [
      {"name": "greeting", "wordCount": 50, "estimatedSizeMB": 5}
    ]
  }
}
```

### 11.4 Update Downloads 🔒
```
PUT /offline/downloads
```
**Body:**
```json
{
  "level": "HSK1",
  "action": "add"
}
```
OR
```json
{
  "level": "HSK1",
  "action": "remove"
}
```
**Response:**
```json
{
  "success": true,
  "data": {
    "downloadedLevels": ["HSK1", "HSK2"]
  }
}
```

---

## Error Handling

**Error Response Format:**
```json
{
  "success": false,
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Invalid or expired token"
  }
}
```

**HTTP Status Codes:**
| Code | Meaning |
|------|---------|
| 200 | Success |
| 400 | Bad Request (validation error) |
| 401 | Unauthorized (missing/invalid token) |
| 403 | Forbidden |
| 404 | Not Found |
| 429 | Too Many Requests (rate limit) |
| 500 | Internal Server Error |

---

## Rate Limits

| Endpoint | Limit |
|----------|-------|
| `/auth/request-link` | 5 requests per email per 15 minutes |
| General | 100 requests per minute per IP |

---

## 📱 Dart/Flutter Models

### UserModel
```dart
class UserModel {
  final String id;
  final String email;
  final String status; // active, pending_deletion, suspended, deleted
  final DateTime? deletionScheduledAt;
  final DateTime createdAt;
}
```

### ProfileModel
```dart
class ProfileModel {
  final String displayName;
  final String? avatarUrl;
  final bool onboardingCompleted;
  final bool isPremium;
  final DateTime? premiumExpiresAt;
  final String goalType; // hsk_exam, conversation, both
  final String currentLevel;
  final String targetLevel;
  final int dailyMinutesTarget;
  final int dailyNewLimit;
  final String reviewIntensity; // light, normal, heavy
  final FocusWeights focusWeights;
  final bool notificationsEnabled;
  final String reminderTime;
  final bool soundEnabled;
  final bool hapticsEnabled;
  final bool vietnameseSupport;
  final List<String> downloadedLevels;
  final String timezone;
}
```

### VocabModel
```dart
class VocabModel {
  final String id;
  final String word;
  final String pinyin;
  final String meaningVi;
  final String meaningEn;
  final String level;
  final int subLevel;
  final List<String> topics;
  final List<String> images;
  final List<Example> examples;
  final String? audioUrl;
  final String? audioSlowUrl;
  final String? wordType;
  final int? strokeCount;
  final String? radical;
  final List<String>? components;
  final String? mnemonic;
  final List<String>? synonyms;
  final List<String>? antonyms;
  final List<String>? collocations;
  final String? usageNotes;
  final String? grammarNotes;
  final String? culturalNotes;
  final String? hskTips;
  final int? frequencyRank;
  final double? difficultyScore;
  final bool isCommon;
  final bool hskOfficial;
  final int orderInLevel;
}
```

---

**🚀 API Production URL:** `https://hanzi-memory-api.onrender.com`

**📧 Support:** Contact backend team for issues

