# 📱 HanLy Frontend Complete Integration Guide

> **Version:** 2.0 (Anonymous-First)  
> **Updated:** 2026-01-09  
> **Base URL:** `https://hanzi-memory-api.onrender.com`

---

## 📋 Mục lục

1. [Tổng quan kiến trúc](#1-tổng-quan-kiến-trúc)
2. [Response Format chuẩn](#2-response-format-chuẩn)
3. [Authentication Flow](#3-authentication-flow)
4. [Data Models chi tiết](#4-data-models-chi-tiết)
5. [API Endpoints đầy đủ](#5-api-endpoints-đầy-đủ)
6. [Tested cURL Examples](#6-tested-curl-examples)
7. [Error Codes](#7-error-codes)
8. [Best Practices cho FE](#8-best-practices-cho-fe)

---

## 1. Tổng quan kiến trúc

### 🆕 Anonymous-First Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     HanLy App Architecture                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │  FIRST LAUNCH                                           │   │
│   │                                                          │   │
│   │  1. App khởi động lần đầu                               │   │
│   │  2. Gọi POST /auth/anonymous với deviceId               │   │
│   │  3. Nhận accessToken + refreshToken                     │   │
│   │  4. Lưu tokens vào secure storage                       │   │
│   │  5. User sử dụng app với ĐẦY ĐỦ tính năng              │   │
│   │                                                          │   │
│   │  → KHÔNG CẦN ĐĂNG KÝ, KHÔNG CÓ PAYWALL                 │   │
│   └─────────────────────────────────────────────────────────┘   │
│                              │                                   │
│                              ▼                                   │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │  OPTIONAL: LIÊN KẾT TÀI KHOẢN                           │   │
│   │                                                          │   │
│   │  Khi user muốn backup/sync:                             │   │
│   │  1. Gọi POST /auth/link-account với email               │   │
│   │  2. User nhận email xác nhận                            │   │
│   │  3. Gọi POST /auth/verify-link-account                  │   │
│   │  4. Account upgraded, dữ liệu được giữ nguyên           │   │
│   │                                                          │   │
│   │  LỢI ÍCH: Backup cloud, sync multi-device               │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Token Management

```dart
// Flutter example
class TokenStorage {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  
  // Lưu tokens sau khi auth
  static Future<void> saveTokens(String accessToken, String refreshToken) async {
    final storage = FlutterSecureStorage();
    await storage.write(key: _accessTokenKey, value: accessToken);
    await storage.write(key: _refreshTokenKey, value: refreshToken);
  }
  
  // Attach token vào mọi request
  static Future<Map<String, String>> getAuthHeaders() async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: _accessTokenKey);
    return {'Authorization': 'Bearer $token'};
  }
}
```

---

## 2. Response Format chuẩn

### ✅ Success Response

```json
{
  "success": true,
  "data": { ... },
  "message": "Optional success message"
}
```

### ❌ Error Response

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable message in Vietnamese"
  }
}
```

### 📄 Paginated Response

```json
{
  "success": true,
  "data": {
    "items": [...],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 500,
      "totalPages": 25,
      "hasNext": true,
      "hasPrev": false
    }
  }
}
```

---

## 3. Authentication Flow

### 3.1 Anonymous User (First Launch)

**Flow:**
```
App Start → Check local tokens → None found → POST /auth/anonymous → Store tokens → Ready!
```

**Request:**
```bash
POST /auth/anonymous
Content-Type: application/json

{
  "deviceId": "your-unique-device-uuid-at-least-10-chars",
  "deviceInfo": {
    "platform": "ios",           // "ios" | "android"
    "osVersion": "17.0",
    "appVersion": "1.0.0",
    "model": "iPhone 15 Pro"
  }
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "data": {
    "userId": "6961339e35f999d02fb6ecde",
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "a1b2c3d4e5f6g7h8i9j0...",
    "isAnonymous": true,
    "createdAt": "2026-01-09T10:00:00.000Z"
  }
}
```

**Flutter Implementation:**
```dart
Future<void> initializeAnonymousUser() async {
  // Get device ID (persist across reinstalls)
  final deviceId = await _getOrCreateDeviceId();
  
  final response = await http.post(
    Uri.parse('$baseUrl/auth/anonymous'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'deviceId': deviceId,
      'deviceInfo': {
        'platform': Platform.isIOS ? 'ios' : 'android',
        'osVersion': Platform.operatingSystemVersion,
        'appVersion': await PackageInfo.fromPlatform().then((p) => p.version),
        'model': await DeviceInfoPlugin().then((d) => d.model),
      },
    }),
  );
  
  if (response.statusCode == 201) {
    final data = jsonDecode(response.body)['data'];
    await TokenStorage.saveTokens(data['accessToken'], data['refreshToken']);
    // User is now authenticated and can use all features!
  }
}

Future<String> _getOrCreateDeviceId() async {
  final storage = FlutterSecureStorage();
  var deviceId = await storage.read(key: 'device_id');
  
  if (deviceId == null) {
    deviceId = const Uuid().v4();
    await storage.write(key: 'device_id', value: deviceId);
  }
  
  return deviceId;
}
```

### 3.2 Check Auth Status

**Request:**
```bash
GET /auth/status
Authorization: Bearer <accessToken>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "userId": "6961339e35f999d02fb6ecde",
    "isAnonymous": true,
    "hasEmail": false,
    "email": null,
    "displayName": "Người học #1234",
    "deviceIdHash": "abc123...",
    "createdAt": "2026-01-09T10:00:00.000Z"
  }
}
```

### 3.3 Link Account (Optional)

**Step 1: Request Link**
```bash
POST /auth/link-account
Authorization: Bearer <accessToken>
Content-Type: application/json

{
  "email": "user@example.com"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "linkId": "6961339e35f999d02fb6ece3",
    "expiresAt": "2026-01-09T10:15:00.000Z",
    "message": "Đã gửi email xác nhận. Vui lòng kiểm tra hộp thư."
  }
}
```

**Step 2: User clicks email link → App receives deep link with token**

**Step 3: Verify Link**
```bash
POST /auth/verify-link-account
Content-Type: application/json

{
  "linkId": "6961339e35f999d02fb6ece3",
  "token": "abc123def456..."
}
```

**Response (Email mới):**
```json
{
  "success": true,
  "data": {
    "userId": "6961339e35f999d02fb6ecde",
    "email": "user@example.com",
    "isAnonymous": false,
    "accessToken": "new_access_token...",
    "refreshToken": "new_refresh_token...",
    "merged": false
  }
}
```

**Response (Email đã có account - MERGE):**
```json
{
  "success": true,
  "data": {
    "userId": "existing_user_id",
    "email": "user@example.com",
    "isAnonymous": false,
    "accessToken": "...",
    "refreshToken": "...",
    "merged": true,
    "mergeResult": {
      "vocabsLearned": 312,
      "streakDays": 14,
      "message": "Đã merge 156 từ vựng và 10 phiên học"
    }
  }
}
```

### 3.4 Email/Password Auth (Alternative)

**Register:**
```bash
POST /auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "confirmPassword": "SecurePass123!"
}
```

**Login:**
```bash
POST /auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePass123!"
}
```

**Response (No 2FA):**
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJ...",
    "refreshToken": "abc...",
    "expiresIn": 900,
    "refreshTokenExpiresAt": "2026-01-16T10:00:00.000Z",
    "user": {
      "id": "...",
      "email": "user@example.com",
      "twoFactorEnabled": false
    }
  }
}
```

**Response (2FA Required):**
```json
{
  "success": true,
  "data": {
    "requires2FA": true,
    "userId": "...",
    "message": "Mã xác thực đã được gửi đến email của bạn"
  }
}
```

### 3.5 Token Refresh

```bash
POST /auth/refresh
Content-Type: application/json

{
  "refreshToken": "your_refresh_token"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "accessToken": "new_access_token...",
    "refreshToken": "new_refresh_token...",
    "expiresIn": 900,
    "refreshTokenExpiresAt": "2026-01-16T10:00:00.000Z"
  }
}
```

---

## 4. Data Models chi tiết

### 4.1 User

| Field | Type | Description |
|-------|------|-------------|
| `_id` | ObjectId | User ID |
| `email` | string \| null | Email (null for anonymous) |
| `isAnonymous` | boolean | True if anonymous user |
| `displayName` | string \| null | Display name |
| `status` | enum | 'active' \| 'suspended' \| 'deleted' \| 'pending_deletion' |
| `twoFactorEnabled` | boolean | 2FA enabled |
| `linkedAt` | Date \| null | When linked email |
| `createdAt` | Date | Created timestamp |

### 4.2 UserProfile

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `userId` | ObjectId | - | Reference to User |
| `displayName` | string | '' | Display name |
| `avatarUrl` | string | '' | Avatar URL |
| `onboardingCompleted` | boolean | false | Completed onboarding |
| `isPremium` | boolean | false | Premium status (deprecated) |
| `goalType` | enum | 'both' | 'hsk_exam' \| 'conversation' \| 'both' |
| `currentLevel` | string | 'HSK1' | Current HSK level |
| `targetLevel` | string | 'HSK3' | Target HSK level |
| `dailyMinutesTarget` | number | 15 | Daily study minutes goal (5-120) |
| `dailyNewLimit` | number | 30 | New words per day limit (1-100) |
| `reviewIntensity` | enum | 'normal' | 'light' \| 'normal' \| 'heavy' |
| `focusWeights` | object | - | { listening, hanzi, meaning } |
| `notificationsEnabled` | boolean | false | Push notifications |
| `reminderTime` | string | '20:00' | Reminder time (HH:mm) |
| `soundEnabled` | boolean | true | Sound effects |
| `hapticsEnabled` | boolean | true | Haptic feedback |
| `vietnameseSupport` | boolean | true | Show Vietnamese translations |
| `downloadedLevels` | string[] | [] | Offline downloaded levels |
| `streak` | number | 0 | Current streak |
| `bestStreak` | number | 0 | Best streak ever |
| `lastStudyDate` | Date \| null | null | Last study date |
| `timezone` | string | 'Asia/Ho_Chi_Minh' | User timezone |

### 4.3 Vocab

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `_id` | ObjectId | ✓ | Vocab ID |
| `word` | string | ✓ | Chinese word (e.g., "你好") |
| `pinyin` | string | ✓ | Pinyin (e.g., "nǐ hǎo") |
| `meaning_vi` | string | ✓ | Vietnamese meaning |
| `meaning_en` | string | ✓ | English meaning |
| `level` | string | ✓ | HSK level (e.g., "HSK1") |
| `subLevel` | string | | Sub-level (e.g., "1A") |
| `topics` | string[] | | Topics (e.g., ["greeting", "daily"]) |
| `images` | string[] | | Image URLs |
| `examples` | Example[] | | Example sentences |
| `audio_url` | string | | Normal speed audio |
| `audio_slow_url` | string | | Slow speed audio |
| `word_type` | string | | Word type (noun, verb, adj...) |
| `stroke_count` | number | | Number of strokes |
| `stroke_order_url` | string | | Stroke order animation URL |
| `stroke_order_images` | string[] | | Stroke-by-stroke images |
| `radical` | string | | Radical character |
| `components` | string[] | | Character components |
| `mnemonic` | string | | Memory aid |
| `synonyms` | string[] | | Synonyms |
| `antonyms` | string[] | | Antonyms |
| `collocations` | string[] | | Common collocations |
| `usage_notes` | string | | Usage notes |
| `grammar_notes` | string | | Grammar notes |
| `cultural_notes` | string | | Cultural notes |
| `hsk_tips` | string | | HSK exam tips |
| `frequency_rank` | number | | Frequency ranking |
| `difficulty_score` | number | | Difficulty (0-100) |
| `is_common` | boolean | | Common word flag |
| `hsk_official` | boolean | | Official HSK word |
| `order_in_level` | number | | Order within level |

**Example object:**
```dart
class Vocab {
  final String word;       // "你好"
  final String pinyin;     // "nǐ hǎo"
  final String meaningVi;  // "Xin chào"
  final String meaningEn;  // "Hello"
  final String level;      // "HSK1"
  final List<String> topics;  // ["greeting", "daily"]
  final List<Example> examples;
  final String? audioUrl;
  final String? wordType;     // "interjection"
  final int? strokeCount;     // 5
  // ...
}

class Example {
  final String cn;     // "你好，我叫小明。"
  final String vi;     // "Xin chào, tôi tên Tiểu Minh."
  final String? pinyin; // "Nǐ hǎo, wǒ jiào Xiǎo Míng."
}
```

### 4.4 UserVocabProgress

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `userId` | ObjectId | - | User reference |
| `vocabId` | ObjectId | - | Vocab reference |
| `state` | enum | 'new' | 'new' \| 'learning' \| 'review' \| 'mastered' |
| `reps` | number | 0 | Repetition count |
| `intervalDays` | number | 0 | Days until next review |
| `ease` | number | 2.5 | Ease factor (1.3-3.0) |
| `dueDate` | Date | - | Next review date |
| `lastResult` | enum | - | 'again' \| 'hard' \| 'good' \| 'easy' |
| `seenCount` | number | 0 | Times seen |
| `wrongCount` | number | 0 | Times wrong |
| `lastReviewedAt` | Date | - | Last review timestamp |

### 4.5 StudySession

| Field | Type | Description |
|-------|------|-------------|
| `userId` | ObjectId | User reference |
| `dateKey` | string | Date key (YYYY-MM-DD) |
| `minutes` | number | Study minutes |
| `newCount` | number | New words learned |
| `reviewCount` | number | Words reviewed |
| `accuracy` | number | Accuracy percentage (0-100) |
| `streak` | number | Streak count at time of session |

### 4.6 GameSession

| Field | Type | Description |
|-------|------|-------------|
| `userId` | ObjectId | User reference |
| `gameType` | enum | 'speed30s' \| 'listening' \| 'pronunciation' \| 'matching' |
| `score` | number | Game score |
| `correctCount` | number | Correct answers |
| `totalCount` | number | Total questions |
| `accuracy` | number | Accuracy percentage |
| `timeSpent` | number | Time in milliseconds |
| `level` | string | HSK level played |
| `dateKey` | string | Date key (YYYY-MM-DD) |

### 4.7 Deck

| Field | Type | Description |
|-------|------|-------------|
| `_id` | ObjectId | Deck ID |
| `userId` | ObjectId | Owner |
| `name` | string | Deck name (max 100 chars) |
| `vocabIds` | ObjectId[] | Vocab IDs in deck |
| `createdAt` | Date | Created timestamp |

### 4.8 Donation

| Field | Type | Description |
|-------|------|-------------|
| `_id` | ObjectId | Donation ID |
| `userId` | ObjectId | Donor |
| `amount` | number | Amount in VND (min 1000) |
| `currency` | string | Currency (default 'VND') |
| `paymentMethod` | enum | 'momo' \| 'bank_transfer' \| 'apple_iap' \| 'google_play' |
| `status` | enum | 'pending' \| 'completed' \| 'failed' \| 'refunded' |
| `optionId` | string | 'coffee' \| 'meal' \| 'support' \| 'sponsor' \| 'custom' |
| `message` | string | Thank you message (max 500) |
| `donorName` | string | Display name for wall of fame |
| `completedAt` | Date | Completion timestamp |

---

## 5. API Endpoints đầy đủ

### 5.1 Authentication

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/auth/anonymous` | ❌ | Create/get anonymous user |
| GET | `/auth/status` | 🔒 | Get auth status |
| POST | `/auth/link-account` | 🔒 | Request email link |
| POST | `/auth/verify-link-account` | ❌ | Verify and link account |
| POST | `/auth/register` | ❌ | Register with email/password |
| POST | `/auth/login` | ❌ | Login with email/password |
| POST | `/auth/verify-2fa` | ❌ | Verify 2FA code |
| POST | `/auth/resend-2fa` | ❌ | Resend 2FA code |
| POST | `/auth/enable-2fa` | 🔒 | Enable 2FA |
| POST | `/auth/disable-2fa` | 🔒 | Disable 2FA |
| POST | `/auth/change-password` | 🔒 | Change password |
| POST | `/auth/refresh` | ❌ | Refresh tokens |
| POST | `/auth/logout` | ❌ | Logout |

### 5.2 User & Profile

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/me` | 🔒 | Get current user + profile |
| POST | `/me/onboarding` | 🔒 | Complete onboarding |
| PUT | `/me/profile` | 🔒 | Update profile |
| DELETE | `/me` | 🔒 | Delete account immediately |
| POST | `/me/request-deletion` | 🔒 | Request deletion (7 days) |
| POST | `/me/cancel-deletion` | 🔒 | Cancel deletion |
| GET | `/me/stats` | 🔒 | Get user statistics |
| GET | `/me/achievements` | 🔒 | Get achievements |
| GET | `/me/calendar` | 🔒 | Get learning calendar |
| GET | `/me/subscription` | 🔒 | Get subscription info |
| GET | `/me/level-progress` | 🔒 | Get HSK level progress |
| POST | `/me/advance-level` | 🔒 | Advance to next level |
| GET | `/me/progress/level` | 🔒 | Get batch progress |
| POST | `/me/progress/unlock-next` | 🔒 | Unlock next batch |
| GET | `/me/progress/needs-mastery` | 🔒 | Get words needing mastery |
| GET | `/me/learned-vocabs` | 🔒 | Get learned vocabs |

### 5.3 Dashboard

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/dashboard` | 🔒 | Get aggregated dashboard data |

### 5.4 Vocabulary

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/vocabs` | ❌ | List vocabs (paginated) |
| GET | `/vocabs/search?q=` | ❌ | Search vocabs |
| GET | `/vocabs/daily-pick` | ❌ | Get daily pick vocab |
| GET | `/vocabs/meta/topics` | ❌ | Get all topics |
| GET | `/vocabs/meta/types` | ❌ | Get all word types |
| GET | `/vocabs/:id` | ❌ | Get vocab by ID |

### 5.5 Learning (SRS)

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/today` | 🔒 | Get today's queue |
| GET | `/today/learned-today` | 🔒 | Get learned today count |
| GET | `/today/forecast` | 🔒 | Get review forecast |
| POST | `/review/answer` | 🔒 | Submit review answer |
| POST | `/session/finish` | 🔒 | Finish study session |

### 5.6 Study Modes

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/study-modes` | 🔒 | Get available study modes |
| GET | `/study-modes/:modeId/words` | 🔒 | Get words for mode |

### 5.7 Game

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/game/leaderboard/:gameType` | ❌ | Get leaderboard |
| POST | `/game/submit` | 🔒 | Submit game result |
| GET | `/game/my-stats` | 🔒 | Get my game stats |

### 5.8 Favorites

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/favorites` | 🔒 | Get favorites |
| POST | `/favorites/:vocabId` | 🔒 | Add to favorites |
| DELETE | `/favorites/:vocabId` | 🔒 | Remove from favorites |

### 5.9 Decks

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/decks` | 🔒 | Get all decks |
| POST | `/decks` | 🔒 | Create deck |
| GET | `/decks/:id` | 🔒 | Get deck by ID |
| PUT | `/decks/:id` | 🔒 | Update deck |
| DELETE | `/decks/:id` | 🔒 | Delete deck |
| POST | `/decks/:id/add/:vocabId` | 🔒 | Add vocab to deck |
| POST | `/decks/:id/remove/:vocabId` | 🔒 | Remove vocab from deck |

### 5.10 HSK Exam

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/hsk-exam/overview` | 🔒 | Get exam overview |
| GET | `/hsk-exam/tests` | 🔒 | Get test list |
| GET | `/hsk-exam/tests/:testId` | 🔒 | Get test details |
| POST | `/hsk-exam/tests/:testId/submit` | 🔒 | Submit test |
| GET | `/hsk-exam/history` | 🔒 | Get exam history |
| GET | `/hsk-exam/tests/:testId/review/:attemptId` | 🔒 | Review attempt |

### 5.11 Donations

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/donations/options` | ❌ | Get donation options |
| GET | `/donations/wall-of-fame` | ❌ | Get donors list |
| POST | `/donations/create` | 🔒 | Create donation |
| GET | `/donations/history` | 🔒 | Get donation history |
| POST | `/donations/:id/verify` | ❌ | Verify donation (webhook) |

### 5.12 Offline

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/offline/bundles` | ❌ | Get bundle info |
| GET | `/offline/bundle/:level` | ❌ | Get bundle data |
| GET | `/offline/topics` | ❌ | Get topics |
| PUT | `/offline/downloads` | 🔒 | Update downloads |

### 5.13 Collections

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/collections` | ❌ | Get collections |
| GET | `/collections/:id` | ❌ | Get collection by ID |

### 5.14 Pronunciation

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/pronunciation/words` | 🔒 | Get pronunciation words |
| POST | `/pronunciation/evaluate` | 🔒 | Evaluate pronunciation |
| POST | `/pronunciation/session` | 🔒 | Submit session |
| GET | `/pronunciation/history` | 🔒 | Get history |

---

## 6. Tested cURL Examples

### 6.1 Anonymous User Flow

```bash
# Step 1: Create anonymous user
curl -X POST https://hanzi-memory-api.onrender.com/auth/anonymous \
  -H "Content-Type: application/json" \
  -d '{
    "deviceId": "test-device-uuid-12345678",
    "deviceInfo": {
      "platform": "ios",
      "osVersion": "17.0",
      "appVersion": "1.0.0",
      "model": "iPhone 15"
    }
  }'

# Response:
# {
#   "success": true,
#   "data": {
#     "userId": "6961339e35f999d02fb6ecde",
#     "accessToken": "eyJhbGciOiJIUzI1NiI...",
#     "refreshToken": "a1b2c3d4e5f6...",
#     "isAnonymous": true,
#     "createdAt": "2026-01-09T10:00:00.000Z"
#   }
# }
```

### 6.2 Get Today's Queue

```bash
curl https://hanzi-memory-api.onrender.com/today \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiI..."

# Response:
# {
#   "success": true,
#   "data": {
#     "newQueue": [
#       {
#         "_id": "...",
#         "word": "你好",
#         "pinyin": "nǐ hǎo",
#         "meaning_vi": "Xin chào",
#         "meaning_en": "Hello",
#         "level": "HSK1"
#       }
#     ],
#     "reviewQueue": [...],
#     "todayStats": {
#       "newLearned": 5,
#       "reviewed": 20,
#       "accuracy": 85,
#       "streak": 7
#     }
#   }
# }
```

### 6.3 Submit Review Answer

```bash
curl -X POST https://hanzi-memory-api.onrender.com/review/answer \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiI..." \
  -H "Content-Type: application/json" \
  -d '{
    "vocabId": "6961339e35f999d02fb6ecde",
    "rating": "good",
    "mode": "flashcard",
    "timeSpent": 5000
  }'

# Response:
# {
#   "success": true,
#   "data": {
#     "progress": {
#       "state": "learning",
#       "reps": 2,
#       "intervalDays": 1,
#       "ease": 2.5,
#       "dueDate": "2026-01-10T00:00:00.000Z"
#     }
#   }
# }
```

### 6.4 Get Dashboard

```bash
curl https://hanzi-memory-api.onrender.com/dashboard \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiI..."

# Response:
# {
#   "success": true,
#   "data": {
#     "profile": {...},
#     "todayProgress": {
#       "minutes": 15,
#       "newCount": 10,
#       "reviewCount": 30,
#       "accuracy": 87
#     },
#     "weeklyProgress": [...],
#     "stats": {
#       "totalVocabs": 156,
#       "masteredVocabs": 45,
#       "streak": 7,
#       "totalMinutes": 340
#     },
#     "dailyPick": {...}
#   }
# }
```

### 6.5 Search Vocabs

```bash
curl "https://hanzi-memory-api.onrender.com/vocabs/search?q=hello"

# Response:
# {
#   "success": true,
#   "data": {
#     "items": [
#       {
#         "_id": "...",
#         "word": "你好",
#         "pinyin": "nǐ hǎo",
#         "meaning_vi": "Xin chào",
#         "meaning_en": "Hello",
#         "level": "HSK1"
#       }
#     ],
#     "total": 5
#   }
# }
```

### 6.6 List Vocabs with Filters

```bash
curl "https://hanzi-memory-api.onrender.com/vocabs?level=HSK1&limit=20&page=1"

# Response:
# {
#   "success": true,
#   "data": {
#     "items": [...],
#     "pagination": {
#       "page": 1,
#       "limit": 20,
#       "total": 150,
#       "totalPages": 8,
#       "hasNext": true,
#       "hasPrev": false
#     }
#   }
# }
```

### 6.7 Game Submit

```bash
curl -X POST https://hanzi-memory-api.onrender.com/game/submit \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiI..." \
  -H "Content-Type: application/json" \
  -d '{
    "gameType": "speed30s",
    "score": 650,
    "correctCount": 45,
    "totalCount": 50,
    "accuracy": 90,
    "timeSpent": 30000,
    "level": "HSK1"
  }'

# Response:
# {
#   "success": true,
#   "data": {
#     "sessionId": "...",
#     "isNewHighScore": true,
#     "previousBest": 600,
#     "rank": 5
#   }
# }
```

### 6.8 Create Donation

```bash
curl -X POST https://hanzi-memory-api.onrender.com/donations/create \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiI..." \
  -H "Content-Type: application/json" \
  -d '{
    "optionId": "coffee",
    "paymentMethod": "momo",
    "message": "Cảm ơn app rất hay!",
    "donorName": "Minh N."
  }'

# Response:
# {
#   "success": true,
#   "data": {
#     "donationId": "...",
#     "amount": 25000,
#     "paymentInfo": {
#       "method": "momo",
#       "phone": "0909123456",
#       "content": "HL-ABC12345",
#       "amount": 25000
#     },
#     "expiresAt": "2026-01-09T10:30:00.000Z"
#   }
# }
```

---

## 7. Error Codes

| Code | HTTP | Description |
|------|------|-------------|
| `BADREQUEST` | 400 | Invalid request body/params |
| `UNAUTHORIZED` | 401 | Invalid/expired token |
| `FORBIDDEN` | 403 | Not allowed action |
| `NOTFOUND` | 404 | Resource not found |
| `CONFLICT` | 409 | Resource conflict |
| `RATE_LIMIT` | 429 | Too many requests |
| `INTERNAL_ERROR` | 500 | Server error |

**Example error:**
```json
{
  "success": false,
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Token expired"
  }
}
```

---

## 8. Best Practices cho FE

### 8.1 Token Management

```dart
class ApiClient {
  final Dio _dio;
  
  ApiClient() : _dio = Dio() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token
        final token = await TokenStorage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 - refresh token
        if (error.response?.statusCode == 401) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            // Retry request
            return handler.resolve(await _retry(error.requestOptions));
          }
        }
        return handler.next(error);
      },
    ));
  }
  
  Future<bool> _refreshToken() async {
    final refreshToken = await TokenStorage.getRefreshToken();
    if (refreshToken == null) return false;
    
    try {
      final response = await _dio.post('/auth/refresh', data: {
        'refreshToken': refreshToken,
      });
      
      await TokenStorage.saveTokens(
        response.data['data']['accessToken'],
        response.data['data']['refreshToken'],
      );
      return true;
    } catch (e) {
      // Force logout
      await TokenStorage.clear();
      return false;
    }
  }
}
```

### 8.2 Offline-First Strategy

```dart
class VocabRepository {
  final ApiClient _api;
  final LocalDb _db;
  
  // Always read from local first, sync in background
  Future<List<Vocab>> getVocabs(String level) async {
    // Return cached data immediately
    final cached = await _db.getVocabs(level);
    if (cached.isNotEmpty) {
      // Sync in background
      _syncVocabs(level);
      return cached;
    }
    
    // No cache - fetch from API
    final vocabs = await _api.get('/vocabs?level=$level');
    await _db.saveVocabs(vocabs);
    return vocabs;
  }
  
  Future<void> _syncVocabs(String level) async {
    try {
      final vocabs = await _api.get('/vocabs?level=$level');
      await _db.saveVocabs(vocabs);
    } catch (e) {
      // Ignore sync errors - user has cached data
    }
  }
}
```

### 8.3 Error Handling

```dart
Future<T> safeApiCall<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on DioException catch (e) {
    final errorData = e.response?.data;
    
    if (errorData != null && errorData['error'] != null) {
      throw AppException(
        code: errorData['error']['code'],
        message: errorData['error']['message'],
      );
    }
    
    throw AppException(
      code: 'NETWORK_ERROR',
      message: 'Không thể kết nối server. Vui lòng thử lại.',
    );
  }
}
```

### 8.4 Rate Limiting Awareness

```dart
// Auth endpoints are rate limited
// - /auth/anonymous: 100/15min per IP
// - /auth/login: 10/15min per IP
// - /auth/link-account: 3/hour per email

// Show appropriate UI when rate limited
if (error.code == 'RATE_LIMIT') {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Quá nhiều yêu cầu'),
      content: Text('Vui lòng thử lại sau vài phút.'),
    ),
  );
}
```

### 8.5 Deep Link Handling for Account Linking

```dart
// iOS: Info.plist
// <key>CFBundleURLTypes</key>
// <array>
//   <dict>
//     <key>CFBundleURLSchemes</key>
//     <array>
//       <string>hanly</string>
//     </array>
//   </dict>
// </array>

// Android: AndroidManifest.xml
// <intent-filter>
//   <action android:name="android.intent.action.VIEW"/>
//   <category android:name="android.intent.category.DEFAULT"/>
//   <category android:name="android.intent.category.BROWSABLE"/>
//   <data android:scheme="hanly" android:host="link-verify"/>
// </intent-filter>

// Handle deep link
void _handleDeepLink(Uri uri) {
  if (uri.host == 'link-verify') {
    final linkId = uri.queryParameters['linkId'];
    final token = uri.queryParameters['token'];
    
    if (linkId != null && token != null) {
      _verifyAccountLink(linkId, token);
    }
  }
}
```

---

## 📝 Checklist cho FE

### Phase 1: Core Setup
- [ ] Implement TokenStorage
- [ ] Setup Dio interceptors
- [ ] Handle anonymous user creation on first launch
- [ ] Implement token refresh logic

### Phase 2: Auth UI
- [ ] Splash screen with anonymous user init
- [ ] Optional: Account linking screen
- [ ] Optional: Login/Register screens

### Phase 3: Main Features
- [ ] Dashboard
- [ ] Today queue (SRS)
- [ ] Vocab browser
- [ ] Favorites
- [ ] Decks

### Phase 4: Advanced
- [ ] Games
- [ ] HSK Exam
- [ ] Pronunciation
- [ ] Offline mode

### Phase 5: Donations
- [ ] Donation screen
- [ ] Payment integration
- [ ] Wall of fame

---

*Document version: 2.0*  
*Last updated: 2026-01-09*  
*Tested with: HanLy Backend v2.0*
