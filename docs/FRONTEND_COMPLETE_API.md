# 📱 HanLy - Complete API Documentation for Frontend

**Base URL:** `https://hanzi-memory-api.onrender.com`  
**Version:** 2.0  
**Last Updated:** 2025-12-28

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Response Format](#response-format)
3. [Authentication](#authentication)
4. [User & Profile](#user--profile)
5. [Premium System](#premium-system)
6. [HSK Level Progress](#hsk-level-progress)
7. [HSK Exam Prep](#hsk-exam-prep)
8. [Dashboard](#dashboard)
9. [Vocabulary](#vocabulary)
10. [Learning (Today/SRS)](#learning-todaysrs)
11. [Study Modes](#study-modes)
12. [Favorites](#favorites)
13. [Decks](#decks)
14. [Collections](#collections)
15. [Game](#game)
16. [Pronunciation](#pronunciation)
17. [Offline](#offline)
18. [Error Codes](#error-codes)

---

## Overview

### Ký hiệu
- 🔒 = Cần Access Token (Authorization: Bearer <token>)
- 📱 = Public endpoint (không cần auth)

### Headers cần thiết
```
Content-Type: application/json
Authorization: Bearer <accessToken>  // cho 🔒 endpoints
```

---

## Response Format

### ✅ Success
```json
{
  "success": true,
  "data": { ... },
  "message": "optional message"
}
```

### ❌ Error
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable message"
  }
}
```

### 📄 Pagination
```json
{
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 500,
    "totalPages": 25,
    "hasNext": true,
    "hasPrev": false
  }
}
```

---

## Authentication

### Hệ thống mới: Email + Password + Optional 2FA

> ⚠️ Magic Link đã bị deprecate. Sử dụng email/password.

### POST `/auth/register` 📱
Đăng ký tài khoản mới.

```json
// Request
{
  "email": "user@example.com",
  "password": "MyPassword123!",
  "confirmPassword": "MyPassword123!"
}

// Password Requirements:
// - Ít nhất 8 ký tự
// - Ít nhất 1 chữ hoa (A-Z)
// - Ít nhất 1 chữ thường (a-z)
// - Ít nhất 1 số (0-9)
// - Ít nhất 1 ký tự đặc biệt (!@#$%^&*...)

// Response 201
{
  "success": true,
  "data": {
    "accessToken": "eyJ...",
    "refreshToken": "abc...",
    "expiresIn": 900,
    "refreshTokenExpiresAt": "2026-01-27T...",
    "user": {
      "id": "...",
      "email": "user@example.com",
      "twoFactorEnabled": false
    }
  },
  "message": "Đăng ký thành công"
}
```

### POST `/auth/login` 📱
Đăng nhập.

```json
// Request
{
  "email": "user@example.com",
  "password": "MyPassword123!"
}

// Response (NO 2FA)
{
  "success": true,
  "data": {
    "accessToken": "eyJ...",
    "refreshToken": "abc...",
    "expiresIn": 900,
    "refreshTokenExpiresAt": "2026-01-27T...",
    "user": {
      "id": "...",
      "email": "user@example.com",
      "twoFactorEnabled": false
    }
  }
}

// Response (2FA REQUIRED)
{
  "success": true,
  "data": {
    "requires2FA": true,
    "userId": "676123...",
    "message": "Mã xác thực đã được gửi đến email của bạn"
  }
}
```

### POST `/auth/verify-2fa` 📱
Xác thực mã 2FA.

```json
// Request
{
  "userId": "676123...",
  "code": "123456"
}

// Response
{
  "success": true,
  "data": {
    "accessToken": "eyJ...",
    "refreshToken": "abc...",
    "expiresIn": 900,
    "user": { "id": "...", "email": "...", "twoFactorEnabled": true }
  }
}
```

### POST `/auth/resend-2fa` 📱
Gửi lại mã 2FA.

```json
// Request
{ "userId": "676123..." }

// Response
{ "success": true, "message": "Mã xác thực mới đã được gửi" }
```

### POST `/auth/enable-2fa` 🔒
Bật 2FA cho tài khoản.

```json
// Response
{ "success": true, "message": "Xác thực 2 bước đã được bật" }
```

### POST `/auth/disable-2fa` 🔒
Tắt 2FA (cần xác nhận password).

```json
// Request
{ "password": "CurrentPassword123!" }

// Response
{ "success": true, "message": "Xác thực 2 bước đã được tắt" }
```

### POST `/auth/change-password` 🔒
Đổi mật khẩu.

```json
// Request
{
  "currentPassword": "OldPassword123!",
  "newPassword": "NewPassword456!",
  "confirmNewPassword": "NewPassword456!"
}

// Response
{ "success": true, "message": "Đổi mật khẩu thành công" }
```

### POST `/auth/refresh` 📱
Làm mới tokens.

```json
// Request
{ "refreshToken": "abc..." }

// Response
{
  "success": true,
  "data": {
    "accessToken": "new_eyJ...",
    "refreshToken": "new_abc...",
    "expiresIn": 900,
    "refreshTokenExpiresAt": "2026-01-27T..."
  }
}
```

### POST `/auth/logout` 📱
Đăng xuất.

```json
// Request
{ "refreshToken": "abc..." }

// Response
{ "success": true, "message": "Đăng xuất thành công" }
```

### Token Expiry
| Token | Thời hạn |
|-------|----------|
| Access Token | 15 phút |
| Refresh Token | 30 ngày |
| 2FA Code | 5 phút |

### Account Lockout
- Sau 5 lần đăng nhập sai → khóa 30 phút
- Reset sau khi đăng nhập thành công

---

## User & Profile

### GET `/me` 🔒
Lấy thông tin user hiện tại.

```json
{
  "success": true,
  "data": {
    "user": {
      "id": "...",
      "email": "user@example.com",
      "status": "active",
      "deletionScheduledAt": null,
      "createdAt": "2025-01-01T..."
    },
    "profile": {
      "displayName": "Nguyen Van A",
      "avatarUrl": "",
      "onboardingCompleted": true,
      "isPremium": false,
      "premiumExpiresAt": null,
      "goalType": "hsk_exam",
      "currentLevel": "HSK1",
      "targetLevel": "HSK3",
      "dailyMinutesTarget": 15,
      "dailyNewLimit": 10,
      "reviewIntensity": "normal",
      "focusWeights": { "listening": 0.33, "hanzi": 0.34, "meaning": 0.33 },
      "notificationsEnabled": false,
      "reminderTime": "20:00",
      "soundEnabled": true,
      "hapticsEnabled": true,
      "vietnameseSupport": true,
      "downloadedLevels": ["HSK1"],
      "timezone": "Asia/Ho_Chi_Minh"
    },
    "stats": {
      "totalWords": 50,
      "masteredWords": 10,
      "learningWords": 25,
      "streak": 5,
      "bestStreak": 12,
      "totalMinutes": 120
    }
  }
}
```

### POST `/me/onboarding` 🔒
Hoàn thành onboarding.

```json
// Request
{
  "displayName": "Nguyen Van A",
  "goalType": "hsk_exam",        // "hsk_exam" | "conversation" | "both"
  "currentLevel": "HSK1",
  "targetLevel": "HSK4",
  "dailyMinutesTarget": 15,
  "focusWeights": { "listening": 0.33, "hanzi": 0.34, "meaning": 0.33 },
  "notificationsEnabled": true,
  "reminderTime": "20:00",
  "timezone": "Asia/Ho_Chi_Minh"
}
```

### PUT `/me/profile` 🔒
Cập nhật profile (tất cả fields optional).

### DELETE `/me` 🔒
Xóa tài khoản ngay lập tức (hard delete).

### POST `/me/request-deletion` 🔒
Yêu cầu xóa tài khoản (7 ngày grace period).

### POST `/me/cancel-deletion` 🔒
Hủy yêu cầu xóa tài khoản.

### GET `/me/stats` 🔒
Thống kê chi tiết.

### GET `/me/achievements` 🔒
Danh sách achievements.

### GET `/me/calendar?months=3` 🔒
Lịch học tập.

### GET `/me/learned-vocabs?limit=100&state=all&shuffle=true` 🔒
Lấy tất cả từ đã học (dùng cho Game 30s).

---

## Premium System

### GET `/me/subscription` 🔒
Lấy thông tin subscription.

```json
{
  "success": true,
  "data": {
    "isPremium": false,
    "plan": "free",  // "free" | "monthly" | "yearly" | "lifetime"
    "startedAt": null,
    "expiresAt": null,
    "autoRenew": false,
    "features": [],
    "limits": {
      "flashcardsPerDay": 10,      // -1 = unlimited
      "comprehensivePerDay": 0,
      "examAttemptsPerDay": 1,
      "gamePerDay": 3
    }
  }
}
```

### GET `/premium/plans` 📱
Danh sách các gói Premium.

```json
{
  "success": true,
  "data": {
    "plans": [
      {
        "id": "monthly",
        "name": "Tháng",
        "price": 79000,
        "currency": "VND",
        "period": "month",
        "periodCount": 1,
        "discount": 0,
        "features": ["unlimited_flashcards", "comprehensive_review", "hsk_exam_prep", "ad_free"],
        "popular": false
      },
      {
        "id": "yearly",
        "name": "Năm",
        "price": 499000,
        "originalPrice": 948000,
        "currency": "VND",
        "period": "year",
        "periodCount": 1,
        "discount": 47,
        "features": ["unlimited_flashcards", "comprehensive_review", "hsk_exam_prep", "ad_free", "streak_protection"],
        "popular": true
      },
      {
        "id": "lifetime",
        "name": "Trọn đời",
        "price": 999000,
        "currency": "VND",
        "period": "lifetime",
        "periodCount": 0,
        "discount": 0,
        "features": ["unlimited_flashcards", "comprehensive_review", "hsk_exam_prep", "ad_free", "streak_protection", "priority_support"],
        "popular": false
      }
    ]
  }
}
```

### POST `/premium/subscribe` 🔒
Đăng ký Premium (sau khi thanh toán).

```json
// Request
{
  "planId": "yearly",
  "paymentMethod": "apple_iap",  // "apple_iap" | "google_play" | "momo" | "vnpay"
  "receiptData": "..."
}

// Response
{
  "success": true,
  "data": {
    "subscriptionId": "sub_123",
    "plan": "yearly",
    "expiresAt": "2027-01-01T...",
    "message": "Đăng ký Premium thành công!"
  }
}
```

### Premium Features
| Feature | Free | Premium |
|---------|------|---------|
| Flashcards/ngày | 10 | Không giới hạn |
| Ôn tập tổng hợp | ❌ | ✅ |
| Ôn thi HSK | 1 đề/level | Tất cả đề |
| Game 30s | 3 lượt/ngày | 10 lượt |
| Quảng cáo | Có | Không |
| Bảo vệ streak | ❌ | 3 lần/tháng |

---

## HSK Level Progress

### GET `/me/level-progress` 🔒
Tiến độ học theo từng cấp HSK.

```json
{
  "success": true,
  "data": {
    "currentLevel": "HSK1",
    "targetLevel": "HSK3",
    "levels": {
      "HSK1": {
        "totalWords": 150,
        "learned": 148,
        "mastered": 140,
        "inProgress": 8,
        "percentage": 98.7,
        "masteryPercentage": 93.3,
        "isCompleted": false,
        "canAdvance": true,
        "isLocked": false,
        "requiredMasteryPercent": 80
      },
      "HSK2": {
        "totalWords": 150,
        "learned": 0,
        "mastered": 0,
        "inProgress": 0,
        "percentage": 0,
        "masteryPercentage": 0,
        "isCompleted": false,
        "canAdvance": false,
        "isLocked": true,
        "requiredMasteryPercent": 80
      }
      // HSK3, HSK4, HSK5, HSK6...
    },
    "advancement": {
      "canAdvanceNow": true,
      "nextLevel": "HSK2",
      "currentMastery": 93.3,
      "requiredMastery": 80,
      "message": "Xuất sắc! Bạn đã sẵn sàng lên HSK2!"
    },
    "stats": {
      "totalWordsLearned": 148,
      "totalWordsMastered": 140,
      "overallProgress": 24.7
    }
  }
}
```

### POST `/me/advance-level` 🔒
Chuyển lên level tiếp theo.

```json
// Request
{ "newLevel": "HSK2" }

// Response
{
  "success": true,
  "data": {
    "previousLevel": "HSK1",
    "currentLevel": "HSK2",
    "newWordsUnlocked": 150,
    "message": "Chúc mừng! Bạn đã lên HSK2! 🎉",
    "rewards": {
      "badge": "hsk1_completed"
    }
  }
}
```

---

## HSK Exam Prep

### GET `/hsk-exam/overview` 🔒
Tổng quan tính năng thi HSK.

```json
{
  "success": true,
  "data": {
    "availableLevels": ["HSK1", "HSK2", "HSK3", "HSK4", "HSK5", "HSK6"],
    "userLevel": "HSK1",
    "stats": {
      "totalAttempts": 15,
      "averageScore": 82,
      "bestScore": 95,
      "passRate": 80
    },
    "recentAttempts": [
      {
        "id": "attempt_123",
        "testId": "hsk1_mock_1",
        "level": "HSK1",
        "score": 85,
        "maxScore": 100,
        "passed": true,
        "completedAt": "2025-01-01T10:00:00Z"
      }
    ]
  }
}
```

### GET `/hsk-exam/tests?level=HSK1&type=mock` 🔒
Danh sách đề thi.

```json
{
  "success": true,
  "data": {
    "tests": [
      {
        "id": "hsk1_mock_1",
        "level": "HSK1",
        "type": "mock",
        "title": "Đề thi thử HSK1 - Đề 1",
        "description": "Đề thi mô phỏng kỳ thi HSK1 thực tế",
        "sections": [
          { "type": "listening", "name": "Nghe hiểu", "questionCount": 20, "duration": 15 },
          { "type": "reading", "name": "Đọc hiểu", "questionCount": 20, "duration": 17 }
        ],
        "totalQuestions": 40,
        "totalDuration": 32,
        "passingScore": 60,
        "maxScore": 100,
        "isPremium": false,
        "attempts": 3,
        "bestScore": 85,
        "lastAttempt": "2025-01-01T10:00:00Z"
      }
    ],
    "pagination": { "page": 1, "limit": 20, "total": 5 }
  }
}
```

### GET `/hsk-exam/tests/:testId` 🔒
Chi tiết đề thi (bắt đầu làm bài).

```json
{
  "success": true,
  "data": {
    "test": {
      "id": "hsk1_mock_1",
      "level": "HSK1",
      "title": "Đề thi thử HSK1 - Đề 1",
      "totalDuration": 32,
      "instructions": "Bài thi gồm 2 phần...",
      "sections": [
        {
          "id": "section_listening",
          "type": "listening",
          "name": "Phần 1: Nghe hiểu",
          "instructions": "Bạn sẽ nghe 20 đoạn âm thanh...",
          "duration": 15,
          "questions": [
            {
              "id": "q1",
              "order": 1,
              "type": "listening_single",
              "audioUrl": "https://...",
              "prompt": "Nghe và chọn nghĩa đúng",
              "options": [
                { "id": "A", "text": "Xin chào" },
                { "id": "B", "text": "Tạm biệt" },
                { "id": "C", "text": "Cảm ơn" }
              ]
            }
          ]
        },
        {
          "id": "section_reading",
          "type": "reading",
          "name": "Phần 2: Đọc hiểu",
          "duration": 17,
          "questions": [...]
        }
      ]
    },
    "attempt": {
      "id": "attempt_new_123",
      "startedAt": "2025-01-01T10:00:00Z",
      "expiresAt": "2025-01-01T10:32:00Z"
    }
  }
}
```

### POST `/hsk-exam/tests/:testId/submit` 🔒
Nộp bài thi.

```json
// Request
{
  "attemptId": "attempt_new_123",
  "answers": [
    { "questionId": "q1", "selectedOption": "A" },
    { "questionId": "q2", "selectedOption": "B" }
  ],
  "timeSpent": 1800
}

// Response
{
  "success": true,
  "data": {
    "result": {
      "attemptId": "attempt_new_123",
      "testId": "hsk1_mock_1",
      "score": 85,
      "maxScore": 100,
      "passed": true,
      "passingScore": 60,
      "timeSpent": 1800,
      "completedAt": "2025-01-01T10:30:00Z"
    },
    "breakdown": {
      "listening": { "correct": 17, "total": 20, "score": 42.5, "maxScore": 50 },
      "reading": { "correct": 17, "total": 20, "score": 42.5, "maxScore": 50 }
    },
    "answers": [
      {
        "questionId": "q1",
        "selectedOption": "A",
        "correctOption": "A",
        "isCorrect": true
      },
      {
        "questionId": "q2",
        "selectedOption": "B",
        "correctOption": "C",
        "isCorrect": false,
        "explanation": "Đáp án đúng là C vì..."
      }
    ],
    "isNewBest": true,
    "previousBest": 80,
    "rewards": {
      "badges": ["first_hsk1_pass"]
    }
  }
}
```

### GET `/hsk-exam/history?level=HSK1&page=1&limit=20` 🔒
Lịch sử làm bài.

### GET `/hsk-exam/tests/:testId/review/:attemptId` 🔒
Xem lại bài thi đã làm.

---

## Dashboard

### GET `/dashboard` 🔒
Aggregated data (one request).

```json
{
  "success": true,
  "data": {
    "me": {
      "displayName": "...",
      "isPremium": false,
      "currentLevel": "HSK1",
      "targetLevel": "HSK3",
      "dailyMinutesTarget": 15,
      "dailyNewLimit": 10
    },
    "today": {
      "dateKey": "2025-12-28",
      "reviewCount": 15,
      "newAvailable": 5,
      "completedMinutes": 10,
      "streak": 5,
      "bestStreak": 12
    },
    "studyModes": [...],
    "learnedToday": { "count": 3, "items": [...] },
    "forecast": { "days": [{ "dateKey": "2025-12-29", "reviewCount": 12 }] },
    "dailyPick": { "dateKey": "2025-12-28", "vocab": {...} }
  }
}
```

---

## Vocabulary

### GET `/vocabs?level=HSK1&page=1&limit=20` 📱
Danh sách từ vựng.

### GET `/vocabs/search?q=hello` 📱
Tìm kiếm từ vựng.

### GET `/vocabs/:id` 📱
Chi tiết từ vựng.

### GET `/vocabs/daily-pick` 📱
Từ của ngày.

### GET `/vocabs/meta/topics` 📱
Danh sách topics.

### GET `/vocabs/meta/types` 📱
Danh sách word types.

---

## Learning (Today/SRS)

### GET `/today` 🔒
Queue học hôm nay.

```json
{
  "success": true,
  "data": {
    "newQueue": [...],
    "reviewQueue": [...],
    "newCount": 10,
    "reviewCount": 15,
    "masteredCount": 50,
    "totalLearned": 100,
    
    "dailyGoalMinutes": 15,
    "dailyNewLimit": 10,
    "newLearnedToday": 5,
    "remainingNewLimit": 5,
    "completedMinutes": 10,
    "todayAccuracy": 85,
    "reviewed": 20,
    
    "streak": 5,
    "bestStreak": 12,
    "streakRank": "top10",
    "streakStatus": "active",
    "weeklyProgress": [...],
    
    "isNewQueueLocked": false,
    "lockReason": null,
    "unlockRequirement": null,
    "reviewOverloadInfo": null,
    
    "gamePlaysToday": 2,
    "dailyGameLimit": 3,
    "remainingGamePlays": 1,
    "canPlayGame": true,
    
    "levelAdvancement": {
      "canAdvance": true,
      "currentLevel": "HSK1",
      "nextLevel": "HSK2",
      "currentMastery": 93.3,
      "requiredMastery": 80,
      "message": "Bạn đã sẵn sàng lên HSK2!"
    }
  }
}
```

### POST `/review/answer` 🔒
Submit câu trả lời SRS.

```json
// Request
{
  "vocabId": "...",
  "rating": "good",  // "again" | "hard" | "good" | "easy"
  "mode": "flashcard",
  "timeSpent": 5000
}

// Response
{
  "success": true,
  "data": {
    "progress": {
      "vocabId": "...",
      "state": "review",
      "reps": 4,
      "intervalDays": 7,
      "ease": 2.6,
      "dueDate": "2026-01-04T...",
      "lastResult": "good"
    },
    "effects": {
      "masteredWord": false,
      "streakChanged": false
    }
  }
}
```

### POST `/session/finish` 🔒
Kết thúc session học.

```json
// Request
{
  "minutes": 15,
  "newCount": 5,
  "reviewCount": 20,
  "accuracy": 85,
  "dateKey": "2025-12-28"
}

// Response
{
  "success": true,
  "data": {
    "dateKey": "2025-12-28",
    "minutes": 15,
    "newCount": 5,
    "reviewCount": 20,
    "accuracy": 85,
    "streak": 6,
    "bestStreak": 12
  }
}
```

---

## Study Modes

### GET `/study-modes` 🔒

```json
{
  "success": true,
  "data": {
    "date": "2025-12-28",
    "streak": 5,
    "isPremium": false,
    "currentLevel": "HSK1",
    "targetLevel": "HSK3",
    "activeLevels": ["HSK1", "HSK2", "HSK3"],
    "studyModes": [
      {
        "id": "srs_vocabulary",
        "name": "Thẻ từ",
        "nameEn": "SRS Vocabulary",
        "description": "15 từ cần ôn tập",
        "icon": "📚",
        "estimatedMinutes": 5,
        "wordCount": 15,
        "isPremium": true,
        "isAvailable": true,
        "freeLimit": 10,
        "usedToday": 5,
        "remainingToday": 5,
        "premiumUnlimited": true
      },
      {
        "id": "listening",
        "name": "Luyện Nghe",
        "isPremium": false,
        "isAvailable": true
      },
      {
        "id": "comprehensive",
        "name": "Ôn tập tổng hợp",
        "isPremium": true,
        "isAvailable": false,
        "unavailableReason": "Cần đăng ký Premium"
      }
    ],
    "todayProgress": {
      "completedMinutes": 10,
      "goalMinutes": 15,
      "newLearned": 5,
      "reviewed": 20,
      "accuracy": 85
    }
  }
}
```

### GET `/study-modes/:modeId/words?limit=20` 🔒
Lấy từ cho mode học cụ thể.

---

## Favorites

### GET `/favorites` 🔒
### POST `/favorites/:vocabId` 🔒
### DELETE `/favorites/:vocabId` 🔒

---

## Decks

### GET `/decks` 🔒
### POST `/decks` 🔒 `{ "name": "Từ khó" }`
### GET `/decks/:id` 🔒
### PUT `/decks/:id` 🔒
### DELETE `/decks/:id` 🔒
### POST `/decks/:id/add/:vocabId` 🔒
### POST `/decks/:id/remove/:vocabId` 🔒

---

## Collections

### GET `/collections` 📱
### GET `/collections/:id?page=1&limit=20` 📱

---

## Game

### POST `/game/submit` 🔒

```json
// Request
{
  "gameType": "speed30s",
  "score": 75,
  "correctCount": 15,
  "totalCount": 20,
  "timeSpent": 30000,
  "level": "HSK1"
}

// Response
{
  "success": true,
  "data": {
    "session": {
      "id": "...",
      "score": 75,
      "correctCount": 15,
      "totalCount": 20,
      "accuracy": 75,
      "timeSpent": 30000
    },
    "rank": { "rank": 5, "bestScore": 85, "percentile": 90 },
    "newAchievements": ["game_score_50"],
    "gameLimit": {
      "gamePlaysToday": 2,
      "dailyGameLimit": 3,
      "remainingPlays": 1,
      "canPlayGame": true,
      "isPremium": false
    }
  }
}
```

### GET `/game/leaderboard/:gameType?period=week` 📱
### GET `/game/my-stats` 🔒

---

## Pronunciation

### GET `/pronunciation/words?level=HSK1&count=10` 🔒
### POST `/pronunciation/evaluate` 🔒
### POST `/pronunciation/session` 🔒
### GET `/pronunciation/history?limit=10` 🔒

---

## Offline

### GET `/offline/bundles` 📱
### GET `/offline/bundle/:level` 📱
### PUT `/offline/downloads` 🔒
### GET `/offline/topics` 📱

---

## Error Codes

| Code | HTTP | Description |
|------|------|-------------|
| `VALIDATION_ERROR` | 400 | Invalid request body |
| `BADREQUEST` | 400 | Bad request |
| `UNAUTHORIZED` | 401 | Missing/invalid token |
| `TOKEN_EXPIRED` | 401 | Access token expired |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `PREMIUM_REQUIRED` | 403 | Feature requires premium |
| `NOT_FOUND` | 404 | Resource not found |
| `CONFLICT` | 409 | Already exists |
| `RATE_LIMITED` | 429 | Too many requests |
| `INTERNAL_ERROR` | 500 | Server error |

---

## Rate Limits

| Endpoint | Limit |
|----------|-------|
| `/auth/*` | 5/min per IP |
| General API | 100/min per user |
| Public endpoints | 60/min per IP |

---

## Quick Reference

### Public Endpoints 📱
```
GET  /health
POST /auth/register
POST /auth/login
POST /auth/verify-2fa
POST /auth/resend-2fa
POST /auth/refresh
POST /auth/logout
GET  /premium/plans
GET  /vocabs, /vocabs/search, /vocabs/:id, /vocabs/daily-pick
GET  /vocabs/meta/topics, /vocabs/meta/types
GET  /collections, /collections/:id
GET  /game/leaderboard/:gameType
GET  /offline/bundles, /offline/bundle/:level, /offline/topics
```

### Protected Endpoints 🔒
```
GET/PUT/DELETE /me, /me/*
POST /auth/enable-2fa, /auth/disable-2fa, /auth/change-password
GET  /me/subscription
POST /premium/subscribe
GET  /me/level-progress
POST /me/advance-level
GET  /hsk-exam/*
POST /hsk-exam/tests/:testId/submit
GET  /dashboard, /today
POST /review/answer, /session/finish
GET  /study-modes, /study-modes/:modeId/words
GET/POST/DELETE /favorites/*
GET/POST/PUT/DELETE /decks/*
POST /game/submit
GET  /game/my-stats
GET/POST /pronunciation/*
PUT  /offline/downloads
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 2.0 | 2025-12-28 | Auth: Email+Password+2FA, Premium System, HSK Level Progress, HSK Exam Prep |
| 1.0 | 2025-12-19 | Initial release với Magic Link auth |

---

**📞 Contact Backend Team nếu có thắc mắc!**

