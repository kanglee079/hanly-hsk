# Backend Requirements - HanLy HSK App

## 📋 Tổng quan

Document này chứa tất cả API endpoints cần phát triển cho các tính năng mới:
1. Premium System
2. HSK Level Progress & Transition
3. HSK Exam Prep

---

## 🔐 1. PREMIUM SYSTEM

### 1.1 GET /me/subscription

Lấy thông tin subscription của user.

**Response:**
```json
{
  "success": true,
  "data": {
    "isPremium": true,
    "plan": "yearly",  // "free" | "monthly" | "yearly" | "lifetime"
    "startedAt": "2025-01-01T00:00:00Z",
    "expiresAt": "2026-01-01T00:00:00Z",  // null for lifetime
    "autoRenew": true,
    "features": [
      "unlimited_flashcards",
      "comprehensive_review", 
      "hsk_exam_prep",
      "ad_free",
      "streak_protection",
      "priority_support"
    ],
    "limits": {
      "flashcardsPerDay": -1,      // -1 = unlimited
      "comprehensivePerDay": -1,
      "examAttemptsPerDay": -1,
      "gamePerDay": 10
    }
  }
}
```

### 1.2 GET /premium/plans

Lấy danh sách các gói Premium.

**Response:**
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

### 1.3 POST /premium/subscribe

Đăng ký Premium (sau khi thanh toán thành công).

**Request:**
```json
{
  "planId": "yearly",
  "paymentMethod": "apple_iap",  // "apple_iap" | "google_play" | "momo" | "vnpay"
  "receiptData": "..."  // IAP receipt hoặc payment token
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "subscriptionId": "sub_123",
    "plan": "yearly",
    "expiresAt": "2026-01-01T00:00:00Z",
    "message": "Đăng ký Premium thành công!"
  }
}
```

### 1.4 Update GET /study-modes

Thêm fields cho Premium limits.

**Response (updated):**
```json
{
  "success": true,
  "data": {
    "date": "2025-01-01",
    "isPremium": false,
    "studyModes": [
      {
        "id": "srs_vocabulary",
        "name": "Flashcards",
        "isPremium": true,
        "isAvailable": true,
        "freeLimit": 10,           // 🆕 Free users: 10 cards/day
        "usedToday": 5,            // 🆕 Đã dùng hôm nay
        "remainingToday": 5,       // 🆕 Còn lại
        "premiumUnlimited": true   // 🆕 Premium không giới hạn
      },
      {
        "id": "listening",
        "name": "Luyện Nghe", 
        "isPremium": false,
        "isAvailable": true
      },
      {
        "id": "pronunciation",
        "name": "Phát âm",
        "isPremium": false,
        "isAvailable": true
      },
      {
        "id": "matching",
        "name": "Ghép từ",
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
    ]
  }
}
```

---

## 📊 2. HSK LEVEL PROGRESS & TRANSITION

### 2.1 GET /me/level-progress

Lấy tiến độ học theo từng cấp HSK.

**Response:**
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
      },
      "HSK3": {
        "totalWords": 300,
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
      // HSK4, HSK5, HSK6...
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
      "overallProgress": 24.7  // % of all HSK1-6 words
    }
  }
}
```

### 2.2 POST /me/advance-level

Xác nhận chuyển lên level tiếp theo.

**Request:**
```json
{
  "newLevel": "HSK2"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "previousLevel": "HSK1",
    "currentLevel": "HSK2",
    "newWordsUnlocked": 150,
    "message": "Chúc mừng! Bạn đã lên HSK2! 🎉",
    "rewards": {
      "xp": 500,
      "badge": "hsk1_completed"
    }
  }
}
```

### 2.3 Update GET /today

Thêm field cho level advancement notification.

**Response (updated):**
```json
{
  "success": true,
  "data": {
    // ... existing fields ...
    
    "levelAdvancement": {           // 🆕 null nếu chưa đủ điều kiện
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

---

## 📝 3. HSK EXAM PREP

### 3.1 GET /hsk-exam/overview

Tổng quan về tính năng thi HSK.

**Response:**
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
      "passRate": 80  // % đạt điểm pass
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

### 3.2 GET /hsk-exam/tests

Danh sách đề thi.

**Query params:**
- `level`: HSK1-6 (optional)
- `type`: "mock" | "practice" | "official" (optional)

**Response:**
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
          {
            "type": "listening",
            "name": "Nghe hiểu",
            "questionCount": 20,
            "duration": 15
          },
          {
            "type": "reading", 
            "name": "Đọc hiểu",
            "questionCount": 20,
            "duration": 17
          }
        ],
        "totalQuestions": 40,
        "totalDuration": 35,
        "passingScore": 60,
        "maxScore": 100,
        "isPremium": false,
        "attempts": 3,
        "bestScore": 85,
        "lastAttempt": "2025-01-01T10:00:00Z"
      },
      {
        "id": "hsk1_mock_2",
        "level": "HSK1",
        "type": "mock",
        "title": "Đề thi thử HSK1 - Đề 2",
        "isPremium": true,
        "attempts": 0,
        "bestScore": null
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 50
    }
  }
}
```

### 3.3 GET /hsk-exam/tests/:testId

Chi tiết đề thi (để bắt đầu làm bài).

**Response:**
```json
{
  "success": true,
  "data": {
    "test": {
      "id": "hsk1_mock_1",
      "level": "HSK1",
      "title": "Đề thi thử HSK1 - Đề 1",
      "totalDuration": 35,
      "instructions": "Bài thi gồm 2 phần: Nghe hiểu và Đọc hiểu...",
      "sections": [
        {
          "id": "section_listening",
          "type": "listening",
          "name": "Phần 1: Nghe hiểu",
          "instructions": "Bạn sẽ nghe 20 đoạn hội thoại...",
          "duration": 15,
          "questions": [
            {
              "id": "q1",
              "order": 1,
              "type": "listening_single",
              "audioUrl": "https://cdn.../q1.mp3",
              "imageUrl": "https://cdn.../q1.jpg",  // optional
              "prompt": "Hãy chọn hình ảnh phù hợp với đoạn hội thoại",
              "options": [
                {"id": "A", "text": null, "imageUrl": "https://cdn.../q1_a.jpg"},
                {"id": "B", "text": null, "imageUrl": "https://cdn.../q1_b.jpg"},
                {"id": "C", "text": null, "imageUrl": "https://cdn.../q1_c.jpg"}
              ]
            },
            {
              "id": "q2",
              "order": 2,
              "type": "listening_dialogue",
              "audioUrl": "https://cdn.../q2.mp3",
              "prompt": "男的想去哪儿？",
              "options": [
                {"id": "A", "text": "商店"},
                {"id": "B", "text": "医院"},
                {"id": "C", "text": "学校"}
              ]
            }
          ]
        },
        {
          "id": "section_reading",
          "type": "reading",
          "name": "Phần 2: Đọc hiểu",
          "instructions": "Đọc các câu sau và chọn đáp án đúng...",
          "duration": 17,
          "questions": [
            {
              "id": "q21",
              "order": 21,
              "type": "reading_match",
              "prompt": "Chọn từ phù hợp để điền vào chỗ trống",
              "context": "我喜欢___水果。",
              "options": [
                {"id": "A", "text": "吃"},
                {"id": "B", "text": "喝"},
                {"id": "C", "text": "看"}
              ]
            },
            {
              "id": "q22",
              "order": 22,
              "type": "reading_comprehension",
              "passage": "小明今年十岁，他很喜欢读书...",
              "prompt": "小明喜欢什么？",
              "options": [
                {"id": "A", "text": "看电视"},
                {"id": "B", "text": "读书"},
                {"id": "C", "text": "玩游戏"}
              ]
            }
          ]
        }
      ]
    },
    "attempt": {
      "id": "attempt_new_123",
      "startedAt": "2025-01-01T10:00:00Z",
      "expiresAt": "2025-01-01T10:35:00Z"
    }
  }
}
```

### 3.4 POST /hsk-exam/tests/:testId/submit

Nộp bài thi.

**Request:**
```json
{
  "attemptId": "attempt_new_123",
  "answers": [
    {"questionId": "q1", "selectedOption": "A"},
    {"questionId": "q2", "selectedOption": "B"},
    {"questionId": "q21", "selectedOption": "A"},
    {"questionId": "q22", "selectedOption": "B"}
  ],
  "timeSpent": 1800  // seconds
}
```

**Response:**
```json
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
      "listening": {
        "correct": 17,
        "total": 20,
        "score": 42.5,
        "maxScore": 50
      },
      "reading": {
        "correct": 17,
        "total": 20,
        "score": 42.5,
        "maxScore": 50
      }
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
      "xp": 100,
      "badges": ["first_hsk1_pass"]
    }
  }
}
```

### 3.5 GET /hsk-exam/history

Lịch sử làm bài.

**Query params:**
- `level`: HSK1-6 (optional)
- `page`: 1 (default)
- `limit`: 20 (default)

**Response:**
```json
{
  "success": true,
  "data": {
    "attempts": [
      {
        "id": "attempt_123",
        "testId": "hsk1_mock_1",
        "testTitle": "Đề thi thử HSK1 - Đề 1",
        "level": "HSK1",
        "score": 85,
        "maxScore": 100,
        "passed": true,
        "timeSpent": 1800,
        "completedAt": "2025-01-01T10:30:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 15
    }
  }
}
```

### 3.6 GET /hsk-exam/tests/:testId/review/:attemptId

Xem lại bài thi đã làm.

**Response:**
```json
{
  "success": true,
  "data": {
    "attempt": {
      "id": "attempt_123",
      "testId": "hsk1_mock_1",
      "score": 85,
      "completedAt": "2025-01-01T10:30:00Z"
    },
    "test": {
      // Same as GET /hsk-exam/tests/:testId
    },
    "answers": [
      {
        "questionId": "q1",
        "selectedOption": "A",
        "correctOption": "A", 
        "isCorrect": true
      }
    ]
  }
}
```

---

## 💰 4. PREMIUM PRICING (Recommended)

| Plan | Price (VND) | USD Equiv | Period | Discount |
|------|-------------|-----------|--------|----------|
| Monthly | 79,000 | ~$3.2 | 1 tháng | - |
| Yearly | 499,000 | ~$20 | 1 năm | 47% off |
| Lifetime | 999,000 | ~$40 | Vĩnh viễn | - |

### Features by Plan

| Feature | Free | Premium |
|---------|------|---------|
| Flashcards/ngày | 10 | Không giới hạn |
| Ôn tập tổng hợp | ❌ | ✅ |
| Ôn thi HSK | 1 đề miễn phí/level | Tất cả đề thi |
| Game 30s | 3 lượt/ngày | 10 lượt/ngày |
| Quảng cáo | Có | Không |
| Bảo vệ streak | ❌ | 3 lần/tháng |
| Hỗ trợ ưu tiên | ❌ | ✅ (Yearly+) |

---

## 📋 Summary - Danh sách Endpoints

### Mới hoàn toàn:
1. `GET /me/subscription`
2. `GET /premium/plans`
3. `POST /premium/subscribe`
4. `GET /me/level-progress`
5. `POST /me/advance-level`
6. `GET /hsk-exam/overview`
7. `GET /hsk-exam/tests`
8. `GET /hsk-exam/tests/:testId`
9. `POST /hsk-exam/tests/:testId/submit`
10. `GET /hsk-exam/history`
11. `GET /hsk-exam/tests/:testId/review/:attemptId`

### Cần update:
1. `GET /study-modes` - thêm freeLimit, usedToday, remainingToday
2. `GET /today` - thêm levelAdvancement object

---

## 🔄 Database Schema Updates (Suggested)

### Subscriptions Collection
```javascript
{
  userId: ObjectId,
  plan: "monthly" | "yearly" | "lifetime",
  status: "active" | "cancelled" | "expired",
  startedAt: Date,
  expiresAt: Date | null,
  autoRenew: Boolean,
  paymentMethod: String,
  transactions: [...]
}
```

### ExamAttempts Collection
```javascript
{
  userId: ObjectId,
  testId: String,
  answers: [{questionId, selectedOption}],
  score: Number,
  breakdown: {listening: {...}, reading: {...}},
  timeSpent: Number,
  passed: Boolean,
  completedAt: Date
}
```

### MockTests Collection
```javascript
{
  id: String,
  level: "HSK1" - "HSK6",
  type: "mock" | "practice",
  title: String,
  isPremium: Boolean,
  sections: [{
    type: "listening" | "reading",
    questions: [{
      id: String,
      type: String,
      audioUrl: String,
      imageUrl: String,
      prompt: String,
      options: [{id, text, imageUrl}],
      correctOption: String,
      explanation: String
    }]
  }]
}
```

