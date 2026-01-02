# HanLy HSK API Reference

**Base URL**: `https://hanzi-memory-api.onrender.com` (Production) or `http://localhost:5000` (Local)
**Version**: v2.2 (Detailed)

---

## 🔐 Authentication (`/auth`)

Headers: `Content-Type: application/json`

### 1. Register
`POST /auth/register`

Create a new user account.

**Request Body**:
```json
{
  "email": "user@example.com", // Required, Valid Email
  "password": "Password123!",  // Required, Min 8 chars
  "confirmPassword": "Password123!" // Must match password
}
```

**Success Response (201 Created)**:
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbG...",
    "refreshToken": "7c8e9a...",
    "expiresIn": 900,
    "refreshTokenExpiresAt": "2024-01-01T12:00:00.000Z",
    "user": {
      "id": "651a...",
      "email": "user@example.com",
      "twoFactorEnabled": false
    }
  },
  "message": "Đăng ký thành công"
}
```

### 2. Login
`POST /auth/login`

Login with email and password.

**Request Body**:
```json
{
  "email": "user@example.com", // Required
  "password": "Password123!"   // Required
}
```

**Success Response (Standard)**:
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbG...",
    "refreshToken": "7c8e9a...",
    "expiresIn": 900,
    "user": {
      "id": "651a...",
      "email": "user@example.com",
      "twoFactorEnabled": false
    }
  }
}
```

**Success Response (If 2FA Enabled)**:
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

### 3. Verify 2FA
`POST /auth/verify-2fa`

Complete login process when 2FA is required.

**Request Body**:
```json
{
  "userId": "651a...", // From login response
  "code": "123456"     // 6-digit code
}
```

### 4. Refresh Token
`POST /auth/refresh`

Get new access token using refresh token.

**Request Body**:
```json
{
  "refreshToken": "7c8e9a..." // Required
}
```

**Success Response**:
```json
{
  "success": true,
  "data": {
    "accessToken": "new_access_token...",
    "refreshToken": "new_refresh_token...",
    "expiresIn": 900
  }
}
```

---

## 👤 User Profile (`/me`)

Auth Required: `Authorization: Bearer <token>`

### 1. Get Me
`GET /me`

Get current user profile, settings, and stats.

**Success Response**:
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "651a...",
      "email": "user@example.com",
      "status": "active"
    },
    "profile": {
      "displayName": "User Name",
      "avatarUrl": "https://...",
      "onboardingCompleted": true,
      "isPremium": false,
      "currentLevel": "HSK1",
      "targetLevel": "HSK3",
      "dailyMinutesTarget": 15,
      "dailyNewLimit": 10,
      "notificationsEnabled": true
    },
    "stats": {
      "totalWordsLearned": 150,
      "streak": 5,
      "lastStudyDate": "2024-01-01"
    }
  }
}
```

### 2. Onboarding
`POST /me/onboarding`

Complete initial user setup.

**Request Body**:
```json
{
  "displayName": "John Doe",           // Required, 1-50 chars
  "goalType": "hsk_exam",              // Enum: 'hsk_exam', 'conversation', 'both'
  "currentLevel": "HSK1",              // Regex: ^HSK[1-6]$
  "dailyMinutesTarget": 15,            // Min 5, Max 120
  "notificationsEnabled": true,        // Optional
  "reminderTime": "20:00"              // Optional, Format HH:MM
}
```

### 3. Update Profile
`PUT /me/profile`

Update user settings. All fields optional.

**Request Body**:
```json
{
  "displayName": "New Name",
  "dailyNewLimit": 20,           // Min 1, Max 50
  "reviewIntensity": "normal",   // Enum: 'light', 'normal', 'heavy'
  "soundEnabled": true,
  "hapticsEnabled": true
}
```

---

## 📚 Learning Core (Root `/`)

The core SRS loop.

### 1. Get Today's Queue
`GET /today`

Get everything needed for the "Today" tab.

**Success Response**:
```json
{
  "success": true,
  "data": {
    "dateKey": "2024-01-01",
    "stats": {
      "reviewCount": 15,       // Total reviews due today
      "newCount": 5,           // New words available to learn
      "completedMinutes": 10,  // Minutes studied today
      "streak": 5
    },
    "newQueue": [              // List of new words to learn
      {
        "id": "651a...",
        "word": "你好",
        "pinyin": "nǐ hǎo",
        "meaning_vi": "Xin chào",
        "level": "HSK1",
        "audio_url": "..."
      }
    ],
    "reviewQueue": [           // List of words to review
      {
        "id": "651b...",
        "word": "谢谢",
        "progress": {
          "state": "review",   // 'learning', 'review', 'relearning'
          "reps": 3,
          "intervalDays": 1,
          "dueDate": "2024-01-01T00:00:00Z"
        }
      }
    ]
  }
}
```

### 2. Record Review Answer
`POST /review/answer`

Submit an SRS judgment for a word.

**Request Body**:
```json
{
  "vocabId": "651b...",        // Required
  "rating": "good",            // Enum: 'again', 'hard', 'good', 'easy'
  "timeSpent": 5000,           // Optional, ms
  "mode": "flashcard"          // Optional
}
```

**Success Response**:
```json
{
  "success": true,
  "data": {
    "progress": {
      "vocabId": "651b...",
      "state": "review",
      "intervalDays": 3,       // Next review in 3 days
      "dueDate": "2024-01-04T12:00:00.000Z"
    },
    "effects": {
      "masteredWord": false,   // True if word moved to 'mastered' state
      "streakChanged": false
    }
  }
}
```

### 3. Finish Session
`POST /session/finish`

Call this when user exits learning mode or completes a batch.

**Request Body**:
```json
{
  "minutes": 5,               // Minutes spent in this session
  "newCount": 2,              // Count of new words learned
  "reviewCount": 10,          // Count of reviews done
  "accuracy": 85              // % Accuracy
}
```

**Success Response**:
```json
{
  "success": true,
  "data": {
    "streak": 6,              // Updated streak
    "minutes": 15,            // Total minutes today
    "bestStreak": 10
  }
}
```

### 4. Get Learned Today
`GET /today/learned-today`

Get list of new words learned today (for summary screen).

**Success Response**:
```json
{
  "success": true,
  "data": {
    "dateKey": "2024-01-01",
    "count": 5,
    "items": [
      { "id": "...", "word": "你好", "meaning_vi": "Xin chào" }
    ]
  }
}
```

---

## 🧧 HSK Exam (`/hsk-exam`)

### 1. Get Valid Tests
`GET /hsk-exam/tests?level=HSK1&page=1&limit=10`

**Success Response**:
```json
{
  "success": true,
  "data": {
    "tests": [
      {
        "testId": "hsk1-test-01",
        "title": "HSK 1 Practice Test 1",
        "level": "HSK1",
        "duration": 40,
        "questionCount": 40,
        "isPremium": false,
        "userAttempt": {      // Current user's best/latest attempt status
          "status": "completed",
          "score": 180,
          "passed": true
        }
      }
    ],
    "pagination": { "total": 5, "page": 1, "limit": 10 }
  }
}
```

### 2. Start/Get Test
`GET /hsk-exam/tests/:testId`

**Success Response**:
```json
{
  "success": true,
  "data": {
    "test": {
      "id": "hsk1-test-01",
      "sections": [ /* ...questions without correct answers... */ ]
    },
    "attempt": {
      "id": "attempt_123...",
      "startedAt": "2024-01-01..."
    }
  }
}
```
*Error: Returns 403 `PREMIUM_REQUIRED` if limit reached or premium test accessed without sub.*

### 3. Submit Test
`POST /hsk-exam/tests/:testId/submit`

**Request Body**:
```json
{
  "attemptId": "attempt_123...",
  "timeSpent": 2400, // seconds
  "answers": [
    { "questionId": "q1", "selectedOption": "A" },
    { "questionId": "q2", "selectedOption": "C" }
  ]
}
```

**Success Response**:
```json
{
  "success": true,
  "data": {
    "result": {
      "score": 185,
      "maxScore": 200,
      "passed": true,
      "breakdown": [
        { "type": "listening", "score": 90, "correct": 18, "total": 20 },
        { "type": "reading", "score": 95, "correct": 19, "total": 20 }
      ]
    },
    "detailedAnswers": [
      { "questionId": "q1", "isCorrect": true, "correctOption": "A", "explanation": "..." }
    ]
  }
}
```

---

## 💎 Premium (`/premium`)

### 1. Subscribe
`POST /premium/subscribe`

**Request Body**:
```json
{
  "planId": "yearly",             // Enum: 'monthly', 'yearly', 'lifetime'
  "paymentMethod": "apple_iap",   // Enum: 'apple_iap', 'google_play', 'momo', 'vnpay'
  "receiptData": "base64..."      // Optional verification data
}
```

---

## ⚠️ Common Error Codes

| Code | HTTP Status | Description |
|:-----|:------------|:------------|
| `UNAUTHORIZED` | 401 | Missing or invalid token. |
| `FORBIDDEN` | 403 | Permission denied. |
| `PREMIUM_REQUIRED` | 403 | Feature requires premium or limit reached. |
| `BAD_REQUEST` | 400 | Invalid input (schema validation failed). |
| `NOT_FOUND` | 404 | Resource not found. |
