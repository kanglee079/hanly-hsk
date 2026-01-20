# HanLy API Reference

**Base URL**: `https://hanzi-memory-api.onrender.com`  
**Version**: 3.0  
**Updated**: 2026-01-18

---

## Quick Start

### Anonymous-First Flow
1. App startup → `POST /auth/anonymous` (get device-based account)
2. User can use all features without registration
3. When ready to backup/sync → `POST /auth/register` with `anonymousUserId` to auto-merge data

### Authentication
All protected endpoints (🔒) require: `Authorization: Bearer <accessToken>`

---

## 🔐 Authentication (`/auth`)

### POST `/auth/anonymous`
Create or get anonymous user by device ID.

**Request:**
```json
{
  "deviceId": "UUID-minimum-10-chars",
  "deviceInfo": {
    "platform": "ios",
    "osVersion": "17.0",
    "appVersion": "1.0.0",
    "model": "iPhone 15 Pro"
  }
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "userId": "anon_abc123",
    "accessToken": "eyJhbGc...",
    "refreshToken": "eyJhbGc...",
    "isAnonymous": true,
    "isNewUser": true,
    "createdAt": "2026-01-18T00:00:00Z"
  }
}
```

---

### POST `/auth/register`
Register with email + password. Optionally merge anonymous user data.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "123456",
  "anonymousUserId": "anon_abc123"
}
```
> **Note**: Password requires minimum 6 characters only. No confirmPassword needed.

**Response (201):**
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbG...",
    "refreshToken": "7c8e9a...",
    "expiresIn": 900,
    "user": { "id": "651a...", "email": "user@example.com", "twoFactorEnabled": false },
    "merged": true,
    "mergeResult": {
      "vocabsLearned": 156,
      "streakDays": 5,
      "message": "Đã merge 156 từ vựng và 10 phiên học"
    }
  },
  "message": "Đăng ký thành công. Đã merge 156 từ vựng và 10 phiên học"
}
```

---

### POST `/auth/login`
Login with email + password.

**Request:**
```json
{ "email": "user@example.com", "password": "123456" }
```

**Response (standard):**
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbG...",
    "refreshToken": "7c8e9a...",
    "expiresIn": 900,
    "user": { "id": "651a...", "email": "user@example.com", "twoFactorEnabled": false }
  }
}
```

**Response (2FA enabled):**
```json
{
  "success": true,
  "data": {
    "requires2FA": true,
    "userId": "651a...",
    "message": "Mã xác thực đã được gửi đến email của bạn"
  }
}
```

---

### POST `/auth/verify-2fa`
Complete login with 2FA code.

**Request:** `{ "userId": "651a...", "code": "123456" }`

---

### POST `/auth/refresh`
Refresh access token.

**Request:** `{ "refreshToken": "7c8e9a..." }`

**Response:**
```json
{
  "success": true,
  "data": {
    "accessToken": "new_token...",
    "refreshToken": "new_refresh...",
    "expiresIn": 900
  }
}
```

---

### POST `/auth/logout`
Revoke refresh token.

**Request:** `{ "refreshToken": "7c8e9a..." }`

---

### GET `/auth/status` 🔒
Get current auth status.

**Response:**
```json
{
  "success": true,
  "data": {
    "userId": "...",
    "isAnonymous": true,
    "hasEmail": false,
    "email": null,
    "displayName": "Người học #1234"
  }
}
```

---

### POST `/auth/link-account` 🔒
Link email to anonymous account (sends verification email).

**Request:** `{ "email": "user@example.com" }`

---

### POST `/auth/verify-link-account`
Verify and complete account linking.

**Request:** `{ "linkId": "link_xyz789", "token": "abc123..." }`

---

### POST `/auth/change-password` 🔒
Change password.

**Request:**
```json
{
  "currentPassword": "old123",
  "newPassword": "new123"
}
```
> **Note**: No confirmNewPassword needed. Minimum 6 characters.

---

### POST `/auth/enable-2fa` 🔒
Enable two-factor authentication.

### POST `/auth/disable-2fa` 🔒
Disable 2FA (requires password).

**Request:** `{ "password": "current-password" }`

---

## 👤 User Profile (`/me`) 🔒

### GET `/me`
Get current user profile, settings, and stats.

**Response:**
```json
{
  "success": true,
  "data": {
    "user": { "id": "...", "email": "...", "status": "active" },
    "profile": {
      "displayName": "User Name",
      "avatarUrl": "",
      "onboardingCompleted": true,
      "isPremium": false,
      "currentLevel": "HSK1",
      "targetLevel": "HSK3",
      "dailyMinutesTarget": 15,
      "dailyNewLimit": 10,
      "reviewIntensity": "normal"
    },
    "stats": {
      "totalWords": 150,
      "masteredWords": 50,
      "learningWords": 80,
      "streak": 5,
      "bestStreak": 12,
      "totalMinutes": 450
    }
  }
}
```

---

### POST `/me/onboarding`
Complete initial user setup.

**Request:**
```json
{
  "displayName": "Nguyen Van A",
  "goalType": "hsk_exam",
  "currentLevel": "HSK1",
  "targetLevel": "HSK4",
  "dailyMinutesTarget": 15,
  "notificationsEnabled": true,
  "reminderTime": "20:00",
  "timezone": "Asia/Ho_Chi_Minh"
}
```

---

### PUT `/me/profile`
Update profile settings. All fields optional.

**Fields:** `displayName`, `goalType`, `currentLevel`, `targetLevel`, `dailyMinutesTarget`, `dailyNewLimit`, `reviewIntensity`, `soundEnabled`, `hapticsEnabled`, `vietnameseSupport`, `timezone`

---

### DELETE `/me`
Hard delete account immediately.

### POST `/me/request-deletion`
Soft delete with 7-day grace period.

### POST `/me/cancel-deletion`
Cancel pending deletion.

---

### GET `/me/stats`
Get comprehensive stats.

### GET `/me/achievements`
Get achievements list.

### GET `/me/calendar?months=3`
Get learning calendar.

### GET `/me/learned-vocabs?limit=100&state=all&shuffle=true`
Get learned vocabulary for games.

---

### GET `/me/level-progress`
Get HSK level progress.

### POST `/me/advance-level`
Advance to next HSK level.

### GET `/me/progress/level`
Get batch progress (legacy).

### POST `/me/progress/unlock-next`
Unlock next batch.

### GET `/me/progress/needs-mastery?limit=20`
Get words needing mastery.

---

### GET `/me/notifications` 🔒
Get notification settings.

**Response:**
```json
{
  "success": true,
  "data": {
    "enabled": true,
    "reminderTime": "20:00",
    "timezone": "Asia/Ho_Chi_Minh",
    "types": {
      "dailyReminder": true,
      "streakReminder": true,
      "newContent": false,
      "achievements": true
    }
  }
}
```

### POST `/me/notifications` 🔒
Update notification settings.

**Request:**
```json
{
  "enabled": true,
  "reminderTime": "20:00",
  "timezone": "Asia/Ho_Chi_Minh",
  "types": {
    "dailyReminder": true,
    "streakReminder": true,
    "newContent": false,
    "achievements": true
  }
}
```

---

### POST `/me/avatar` 🔒
Upload avatar image.

**Request:** `multipart/form-data` with `avatar` file field (max 5MB, images only)

**Response:**
```json
{
  "success": true,
  "data": {
    "avatarUrl": "https://res.cloudinary.com/xxx/image/upload/v123/hanly/avatars/user_123.jpg"
  }
}
```

---

## 📊 Dashboard (`/dashboard`) 🔒

### GET `/dashboard`
Aggregated data for home screen.

**Response:**
```json
{
  "data": {
    "me": { "displayName": "...", "currentLevel": "HSK1", "dailyMinutesTarget": 15 },
    "today": {
      "dateKey": "2026-01-18",
      "reviewCount": 15,
      "newAvailable": 5,
      "completedMinutes": 10,
      "streak": 5
    },
    "studyModes": [...],
    "learnedToday": { "count": 3, "items": [...] },
    "forecast": { "days": [...] },
    "dailyPick": { "vocab": {...} }
  }
}
```

---

## 📚 Vocabulary (`/vocabs`)

### GET `/vocabs?level=HSK1&page=1&limit=20`
List vocabulary with filters.

**Query params:** `level`, `topic`, `word_type`, `diffMin`, `diffMax`, `sort`, `page`, `limit`

### GET `/vocabs/search?q=hello`
Search vocabulary.

### GET `/vocabs/:id`
Get vocabulary details.

**Response:**
```json
{
  "data": {
    "id": "...",
    "word": "你好",
    "pinyin": "nǐ hǎo",
    "meaning_vi": "Xin chào",
    "meaning_en": "Hello",
    "level": "HSK1",
    "examples": [{ "cn": "你好，我是小明。", "vi": "Xin chào, tôi là Tiểu Minh." }],
    "audio_url": "...",
    "word_type": "phrase"
  }
}
```

### GET `/vocabs/daily-pick`
Get daily random word.

### GET `/vocabs/meta/topics`
Get all topics.

### GET `/vocabs/meta/types`
Get all word types.

---

## 🎯 Learning (`/today`, `/review`, `/session`) 🔒

### GET `/today`
Get today's learning queue.

**Response:**
```json
{
  "data": {
    "newQueue": [...],
    "reviewQueue": [...],
    "newCount": 10,
    "reviewCount": 15,
    "dailyNewLimit": 10,
    "remainingNewLimit": 5,
    "streak": 5,
    "isNewQueueLocked": false,
    "gamePlaysToday": 2,
    "dailyGameLimit": 3
  }
}
```

---

### POST `/review/answer`
Submit SRS review answer.

**Request:**
```json
{
  "vocabId": "651b...",
  "rating": "good",
  "mode": "flashcard",
  "timeSpent": 5000
}
```

**Rating options:** `again`, `hard`, `good`, `easy`

**Response:**
```json
{
  "data": {
    "progress": {
      "vocabId": "651b...",
      "state": "review",
      "intervalDays": 3,
      "dueDate": "2026-01-21T00:00:00Z"
    },
    "effects": {
      "xpEarned": 5,
      "masteredWord": false,
      "levelUp": false
    }
  }
}
```

---

### POST `/session/finish`
Finish learning session.

**Request:**
```json
{
  "minutes": 15,
  "newCount": 5,
  "reviewCount": 20,
  "accuracy": 85,
  "dateKey": "2026-01-18"
}
```

---

### GET `/today/learned-today`
Get words learned today.

### GET `/today/forecast?days=7`
Get review forecast.

---

## 📖 Study Modes (`/study-modes`) 🔒

### GET `/study-modes`
Get available study modes.

**Response:**
```json
{
  "data": {
    "studyModes": [
      { "id": "srs_vocabulary", "name": "Thẻ từ", "wordCount": 15, "isPremium": false },
      { "id": "listening", "name": "Luyện Nghe", "wordCount": 15, "isPremium": false },
      { "id": "writing", "name": "Viết Hán Tự", "wordCount": 10, "isPremium": false },
      { "id": "matching", "name": "Ghép Từ", "wordCount": 12, "isPremium": false }
    ]
  }
}
```

### GET `/study-modes/:modeId/words?limit=20`
Get words for a specific study mode.

---

## ⭐ Favorites (`/favorites`) 🔒

### GET `/favorites`
Get all favorites.

### POST `/favorites/:vocabId`
Add to favorites.

### DELETE `/favorites/:vocabId`
Remove from favorites.

---

## 📂 Decks (`/decks`) 🔒

### GET `/decks`
Get all decks.

### POST `/decks`
Create deck. **Request:** `{ "name": "Từ khó" }`

### GET `/decks/:id`
Get deck details.

### PUT `/decks/:id`
Update deck name.

### DELETE `/decks/:id`
Delete deck.

### POST `/decks/:id/add/:vocabId`
Add vocab to deck.

### POST `/decks/:id/remove/:vocabId`
Remove vocab from deck.

---

## 📚 Collections (`/collections`)

### GET `/collections`
Get all collections (by level, topic, special).

### GET `/collections/:id?page=1&limit=20`
Get collection details with vocabulary.

---

## 🎮 Game (`/game`)

### GET `/game/leaderboard/:gameType?period=week`
Get leaderboard.

**gameType:** `speed30s`, `listening`, `pronunciation`, `matching`  
**period:** `today`, `week`, `month`, `all`

---

### POST `/game/submit` 🔒
Submit game result.

**Request:**
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
  "data": {
    "session": { "score": 75, "accuracy": 75 },
    "rank": { "rank": 5, "percentile": 90 },
    "xp": { "earned": 75, "levelUp": false },
    "gameLimit": { "remainingPlays": 1, "canPlayGame": true }
  }
}
```

---

### GET `/game/my-stats` 🔒
Get personal game stats.

---

## 🎤 Pronunciation (`/pronunciation`) 🔒

### GET `/pronunciation/words?level=HSK1&count=10`
Get words for practice.

### POST `/pronunciation/evaluate`
Evaluate pronunciation.

**Request:** `{ "vocabId": "...", "spokenText": "ni hao" }`

### POST `/pronunciation/session`
Submit complete session.

### GET `/pronunciation/history?limit=10`
Get history.

---

## 📦 Offline (`/offline`)

### GET `/offline/bundles`
Get available offline bundles.

### GET `/offline/bundle/:level`
Download bundle data.

### GET `/offline/topics`
Get topics.

### PUT `/offline/downloads` 🔒
Update downloaded levels.

**Request:** `{ "level": "HSK1", "action": "add" }`

---

## 📝 HSK Exam (`/hsk-exam`) 🔒

### GET `/hsk-exam/overview`
Get exam overview.

### GET `/hsk-exam/tests?level=HSK1&page=1&limit=10`
Get available tests.

### GET `/hsk-exam/tests/:testId`
Start or get test.

### POST `/hsk-exam/tests/:testId/submit`
Submit test answers.

**Request:**
```json
{
  "attemptId": "attempt_123...",
  "timeSpent": 2400,
  "answers": [
    { "questionId": "q1", "selectedOption": "A" }
  ]
}
```

### GET `/hsk-exam/history`
Get test history.

### GET `/hsk-exam/tests/:testId/review/:attemptId`
Review test attempt.

---

## 💝 Donations (`/donations`)

### GET `/donations/options`
Get donation options (public).

### GET `/donations/wall-of-fame`
Get donors list (public).

### POST `/donations/create` 🔒
Create donation.

### GET `/donations/history` 🔒
Get donation history.

### POST `/donations/:id/verify`
Verify donation (webhook).

---

## ⚠️ Error Codes

| Code | HTTP | Description |
|:-----|:-----|:------------|
| `VALIDATION_ERROR` | 400 | Invalid request body |
| `UNAUTHORIZED` | 401 | Missing/invalid token |
| `TOKEN_EXPIRED` | 401 | Access token expired |
| `FORBIDDEN` | 403 | Permission denied |
| `PREMIUM_REQUIRED` | 403 | Feature requires premium |
| `NOT_FOUND` | 404 | Resource not found |
| `CONFLICT` | 409 | Already exists |
| `RATE_LIMITED` | 429 | Too many requests |

---

## 📊 Data Models

### VocabProgress States
| State | Description |
|:------|:------------|
| `new` | Never seen |
| `learning` | Recently started, reps < 3 |
| `review` | Active in SRS cycle |
| `mastered` | Interval > 21 days, 5+ reps |

### SRS Rating Effects
| Rating | Effect |
|:-------|:-------|
| `again` | Reset to 1 day, decrease ease |
| `hard` | Smaller interval increase |
| `good` | Normal interval increase |
| `easy` | Larger interval, max ease |

### Goal Types
- `hsk_exam` - HSK test prep
- `conversation` - Daily speaking
- `both` - Balanced

### Review Intensity
- `light` - Fewer reviews/day
- `normal` - Default SRS
- `heavy` - More reviews, shorter intervals
