# 📱 HanLy - Phân tích Tính năng App

> **Tài liệu cập nhật**: Ngày 17/12/2025  
> **Phiên bản**: 1.0.0  
> **Mục đích**: Tổng hợp toàn diện tính năng hiện tại, điểm yếu, tính năng còn thiếu, và yêu cầu từ Backend

---

## 📋 MỤC LỤC

1. [Tổng quan kiến trúc](#1-tổng-quan-kiến-trúc)
2. [Tính năng đã triển khai](#2-tính-năng-đã-triển-khai)
3. [Điểm yếu và vấn đề chưa khắc phục](#3-điểm-yếu-và-vấn-đề-chưa-khắc-phục)
4. [Tính năng còn thiếu](#4-tính-năng-còn-thiếu)
5. [Yêu cầu từ Backend](#5-yêu-cầu-từ-backend)
6. [Vấn đề về tính liên kết học tập](#6-vấn-đề-về-tính-liên-kết-học-tập)
7. [Đề xuất cải thiện](#7-đề-xuất-cải-thiện)
8. [Roadmap ưu tiên](#8-roadmap-ưu-tiên)

---

## 1. TỔNG QUAN KIẾN TRÚC

### 1.1 Cấu trúc Module

```
lib/app/
├── core/                    # Design system, widgets, utilities
│   ├── config/              # AppConfig
│   ├── constants/           # Strings, limits
│   ├── theme/               # Colors, typography, spacing
│   ├── utils/               # Logger, validators, date format
│   └── widgets/             # Reusable components (HM prefix)
├── data/
│   ├── models/              # Data models
│   ├── network/             # Dio client, interceptors
│   └── repositories/        # API repositories
├── modules/                 # Feature screens
│   ├── auth/                # Magic link authentication
│   ├── onboarding/          # User profile setup
│   ├── shell/               # Tab navigation (4 tabs)
│   ├── today/               # Today tab - daily progress
│   ├── learn/               # Learn tab - study modes
│   ├── explore/             # Explore tab - vocabulary browser
│   ├── me/                  # Me tab - profile & settings
│   ├── session/             # OLD learning session (6 steps)
│   ├── practice/            # NEW practice system (exercise-based)
│   ├── word_detail/         # Vocabulary detail view
│   ├── favorites/           # Favorite words list
│   ├── decks/               # Custom word decks
│   ├── game30/              # 30-second speed game
│   ├── pronunciation/       # Pronunciation practice
│   ├── stats/               # User statistics
│   ├── leaderboard/         # Game leaderboard
│   ├── premium/             # Premium features (UI only)
│   └── settings/            # App settings
├── services/                # Business services
│   ├── audio_service.dart   # Audio playback
│   ├── auth_session_service.dart
│   ├── storage_service.dart # Local storage
│   ├── cache_service.dart
│   ├── connectivity_service.dart
│   └── exercise_generator.dart
└── routes/                  # Navigation
```

### 1.2 Tech Stack
- **State Management**: GetX
- **Local Storage**: GetStorage
- **Networking**: Dio (với Auth + Refresh interceptors)
- **Audio**: just_audio
- **Speech Recognition**: speech_to_text
- **TTS**: flutter_tts

---

## 2. TÍNH NĂNG ĐÃ TRIỂN KHAI

### 2.1 🔐 Authentication
| Tính năng | Trạng thái | Mô tả |
|-----------|------------|-------|
| Magic Link Email | ✅ Hoàn thành | POST `/auth/request-link`, nhập token thủ công |
| Token Verification | ✅ Hoàn thành | GET `/auth/verify-link?token=` |
| Token Refresh | ✅ Hoàn thành | POST `/auth/refresh` với interceptor tự động |
| Logout | ✅ Hoàn thành | POST `/auth/logout` |
| Apple/Google Sign-in | 🔘 UI Only | Placeholder "Coming soon" |

### 2.2 👤 Onboarding & Profile
| Tính năng | Trạng thái | Mô tả |
|-----------|------------|-------|
| Display Name | ✅ Hoàn thành | Tên hiển thị, tối thiểu 2 ký tự |
| Goal Type Selection | ✅ Hoàn thành | HSK Exam / Conversation / Both |
| Current Level | ✅ Hoàn thành | HSK 1-6 |
| Daily Minutes Target | ✅ Hoàn thành | 5/15/30/45 phút |
| Focus Skills | ✅ Hoàn thành | Listening, Hanzi weights |
| Profile Update | ✅ Hoàn thành | PUT `/me/profile` |
| Daily Word Limit Adjustment | ✅ Hoàn thành | Slider trong Me screen |

### 2.3 📚 Today Tab (Màn hình chính)
| Tính năng | Trạng thái | Mô tả |
|-----------|------------|-------|
| Progress Ring | ✅ Hoàn thành | Tiến độ phút học/mục tiêu |
| Daily Stats | ✅ Hoàn thành | Mục tiêu, từ mới, độ chính xác |
| Streak Widget | ✅ Hoàn thành | Chuỗi ngày + streak rank + weekly calendar |
| Learn New Card | ✅ Hoàn thành | Nút học từ mới + limit tracking |
| Quick Actions | ✅ Hoàn thành | Review + Game 30s buttons |
| Review Today's Words | ✅ Hoàn thành | Củng cố từ vừa học hôm nay |
| Due Today Section | ✅ Hoàn thành | Danh sách từ cần ôn + SRS info |
| Weekly Progress Chart | ✅ Hoàn thành | Biểu đồ cột 7 ngày |

### 2.4 📖 Learn Tab
| Tính năng | Trạng thái | Mô tả |
|-----------|------------|-------|
| Study Modes Grid | ✅ Hoàn thành | 4 mode chính từ API |
| Quick Review | ✅ Hoàn thành | Ôn tập nhanh |
| SRS Vocabulary | ✅ Hoàn thành | Thẻ từ flashcard |
| Listening Mode | ✅ Hoàn thành | Luyện nghe |
| Writing Mode | ⚠️ Partial | Có routing nhưng chưa có UI viết nét |
| Matching Mode | ✅ Hoàn thành | Game ghép cặp |
| Comprehensive Mode | 🔘 Premium | UI chỉ báo cần Premium |
| Streak Widget | ✅ Hoàn thành | Hiển thị streak đồng bộ với Today |

### 2.5 🔍 Explore Tab
| Tính năng | Trạng thái | Mô tả |
|-----------|------------|-------|
| Search | ✅ Hoàn thành | GET `/vocabs/search` |
| HSK Level Filters | ✅ Hoàn thành | Chips HSK 1-3, 4-6 |
| Topic Filters | ✅ Hoàn thành | Load từ `/vocabs/meta/topics` |
| Word Type Filters | ✅ Hoàn thành | Load từ `/vocabs/meta/types` |
| Sort Options | ✅ Hoàn thành | Frequency, Difficulty, Level |
| Vocabulary List | ✅ Hoàn thành | Pagination + load more |
| Collections Grid | ✅ Hoàn thành | Load từ `/collections` |
| Daily Pick | ⚠️ Partial | Logic có nhưng chỉ lấy từ đầu tiên |
| Recent Items | ✅ Hoàn thành | Lưu local, tối đa 10 items |
| Quick Actions | ✅ Hoàn thành | Favorite, Add to deck |

### 2.6 👨‍💼 Me Tab
| Tính năng | Trạng thái | Mô tả |
|-----------|------------|-------|
| Profile Display | ✅ Hoàn thành | Avatar, name, email |
| Stats Overview | ✅ Hoàn thành | Streak, mastered, reviewed |
| Daily Goal Progress | ✅ Hoàn thành | Progress bar + percentage |
| Learning Settings | ✅ Hoàn thành | HSK level, goal type, focus skills |
| Favorites Link | ✅ Hoàn thành | Navigate to favorites |
| Decks Link | ✅ Hoàn thành | Navigate to decks |
| Stats Link | ✅ Hoàn thành | Navigate to stats screen |
| Leaderboard Link | ✅ Hoàn thành | Navigate to leaderboard |
| Premium Upsell | ✅ Hoàn thành | UI banner, không khóa features |
| Logout | ✅ Hoàn thành | Với confirm dialog |
| Delete Account | ✅ Hoàn thành | Soft delete flow với countdown |

### 2.7 🎓 Learning System

#### Session Controller (OLD - 6 Steps)
| Step | Trạng thái | Mô tả |
|------|------------|-------|
| 1. Guess | ✅ Hoàn thành | Đoán nghĩa từ Hanzi |
| 2. Audio | ✅ Hoàn thành | Nghe normal/slow |
| 3. Hanzi DNA | ✅ Hoàn thành | Radical, components, strokes |
| 4. Context | ✅ Hoàn thành | Collocations, examples |
| 5. Pronunciation | ⚠️ Partial | Speech recognition, fallback evaluation |
| 6. Quiz | ✅ Hoàn thành | MCQ, auto-submit rating |

#### Practice Controller (NEW - Exercise-based)
| Tính năng | Trạng thái | Mô tả |
|-----------|------------|-------|
| Learn New Mode | ✅ Hoàn thành | Full content + exercises |
| Review SRS Mode | ✅ Hoàn thành | Quick flashcard review |
| Listening Mode | ✅ Hoàn thành | Audio-to-hanzi/meaning |
| Matching Mode | ✅ Hoàn thành | 6 pairs matching game |
| Game 30s Mode | ✅ Hoàn thành | Speed quiz with timer |
| SRS Rating | ⚠️ Partial | Again/Hard/Good/Easy buttons |

#### Exercise Types
| Type | Trạng thái | Mô tả |
|------|------------|-------|
| Hanzi → Meaning | ✅ Hoàn thành | MCQ 4 options |
| Meaning → Hanzi | ✅ Hoàn thành | MCQ 4 options |
| Audio → Hanzi | ✅ Hoàn thành | Play audio, choose hanzi |
| Audio → Meaning | ✅ Hoàn thành | Play audio, choose meaning |
| Hanzi → Pinyin | ✅ Hoàn thành | MCQ 4 options |
| Fill Blank | ✅ Hoàn thành | Điền từ vào câu |
| Matching Pairs | ✅ Hoàn thành | Ghép 6 cặp |
| Sentence Order | ⚠️ Partial | Logic có, UI chưa hoàn thiện |
| Stroke Writing | ❌ Chưa có | Chưa implement |
| Speak Word | ⚠️ Partial | Logic có, STT không ổn định |

### 2.8 🗃️ Vocabulary Management
| Tính năng | Trạng thái | Mô tả |
|-----------|------------|-------|
| Word Detail Screen | ✅ Hoàn thành | Full info, accordions |
| Audio Playback | ✅ Hoàn thành | Normal + slow speed |
| TTS for Examples | ✅ Hoàn thành | flutter_tts zh-CN |
| Favorites CRUD | ✅ Hoàn thành | Add/remove/list |
| Decks CRUD | ✅ Hoàn thành | Create/update/delete |
| Add to Deck | ✅ Hoàn thành | From word detail |
| Collection View | ✅ Hoàn thành | Browse by HSK level |

### 2.9 🎮 Games & Gamification
| Tính năng | Trạng thái | Mô tả |
|-----------|------------|-------|
| Game 30s | ✅ Hoàn thành | Speed quiz, streak multiplier |
| Score Calculation | ✅ Hoàn thành | Base + multiplier |
| Submit to Leaderboard | ✅ Hoàn thành | POST `/game/submit` |
| Leaderboard View | ✅ Hoàn thành | By period (today/week/month/all) |
| My Rank Display | ✅ Hoàn thành | Rank + percentile |

### 2.10 🎤 Pronunciation
| Tính năng | Trạng thái | Mô tả |
|-----------|------------|-------|
| Words for Practice | ✅ Hoàn thành | GET `/pronunciation/words` |
| Audio Playback | ✅ Hoàn thành | Normal + slow |
| Manual Evaluation | ✅ Hoàn thành | 1-5 stars self-assessment |
| API Evaluation | ⚠️ Partial | POST `/pronunciation/evaluate` |
| Submit Session | ✅ Hoàn thành | POST `/pronunciation/session` |
| History | ❌ Chưa có | API có nhưng UI chưa implement |

### 2.11 📊 Statistics
| Tính năng | Trạng thái | Mô tả |
|-----------|------------|-------|
| Stats Overview | ✅ Hoàn thành | Vocab counts, study time |
| Achievements List | ✅ Hoàn thành | Unlocked/locked badges |
| Learning Calendar | ✅ Hoàn thành | Heatmap style |
| Monthly Progress | ⚠️ Partial | API có, UI cơ bản |

### 2.12 ⚙️ Settings
| Tính năng | Trạng thái | Mô tả |
|-----------|------------|-------|
| Settings Screen | ✅ Hoàn thành | Basic layout |
| Privacy Policy | 🔘 Placeholder | Stub link |
| Terms of Service | 🔘 Placeholder | Stub link |
| Sound Settings | 🔘 Coming Soon | Toast placeholder |
| Haptics Settings | 🔘 Coming Soon | Toast placeholder |
| Notifications | 🔘 Coming Soon | Toast placeholder |
| Vietnamese Support | 🔘 Coming Soon | Toast placeholder |
| Offline Download | 🔘 Coming Soon | Toast placeholder |

---

## 3. ĐIỂM YẾU VÀ VẤN ĐỀ CHƯA KHẮC PHỤC

### 3.1 🔴 Vấn đề nghiêm trọng

#### A. Hai hệ thống học tập song song, thiếu thống nhất
- **Vấn đề**: Có 2 module học: `SessionController` (6 steps) và `PracticeController` (exercise-based)
- **Hậu quả**: Code duplicated, UX không nhất quán, khó maintain
- **Nguyên nhân**: Refactor chưa hoàn tất, cả hai đều đang được sử dụng

#### B. Speech Recognition không ổn định
- **Vấn đề**: `speech_to_text` package có nhiều hạn chế:
  - Không phải lúc nào cũng nhận dạng được tiếng Trung
  - Phụ thuộc vào internet và Google/Apple services
  - Không có offline mode
- **Hậu quả**: Tính năng pronunciation đánh giá không chính xác
- **Fallback hiện tại**: So sánh text đơn giản, manual pass

#### C. Stroke Writing chưa implement
- **Vấn đề**: Exercise type `strokeWriting` được define nhưng không có UI
- **Hậu quả**: Không thể luyện viết chữ Hán - một kỹ năng quan trọng

### 3.2 🟡 Vấn đề trung bình

#### A. Daily Pick logic yếu
```dart
// Hiện tại chỉ lấy vocab đầu tiên
final result = await _vocabRepo.getVocabs(page: 1, limit: 1);
dailyPick.value = result.items.first;
```
- **Cần**: API endpoint riêng hoặc logic random cải tiến

#### B. Sentence Order exercise chưa hoàn thiện
- Logic generate có trong `exercise_generator.dart`
- Nhưng UI để user kéo thả sắp xếp chưa implement

#### C. Review Today's Words dùng workaround
```dart
// Lọc words state='learning' hoặc reps=1 - không chính xác
final learnedToday = today.reviewQueue
    .where((v) => v.state == 'learning' || v.reps == 1)
    .toList();
```
- **Cần**: BE cung cấp queue riêng cho từ học hôm nay

#### D. Không có XP system hiển thị rõ ràng
- `xpEarned` được tính trong exercises
- Nhưng không hiển thị tổng XP, không có XP bar, không có level system

#### E. Premium features không enforce
- UI có badge "Premium" nhưng không thực sự khóa features
- `isPremium` check có nhưng chỉ hiển thị dialog, vẫn cho dùng

### 3.3 🟢 Vấn đề nhỏ

#### A. Thiếu animation/transition
- Chuyển exercise khá cứng
- Không có celebration animation khi hoàn thành

#### B. Error handling UI chưa đẹp
- Một số nơi chỉ show toast, không có empty/error state

#### C. Image loading không có fallback
- `HMCachedImage` có nhưng không phải nơi nào cũng dùng

#### D. Audio pre-cache không verify
- `preCacheAudio` chạy background nhưng không track completion

---

## 4. TÍNH NĂNG CÒN THIẾU

### 4.1 ❌ Chưa triển khai (Cần thiết)

| Tính năng | Ưu tiên | Mô tả | BE Ready |
|-----------|---------|-------|----------|
| **Stroke Writing Exercise** | 🔴 Cao | Vẽ nét chữ Hán | Không cần |
| **Notification Settings** | 🔴 Cao | Reminder giờ học | ✅ API có |
| **Offline Download** | 🔴 Cao | Download HSK bundles | ✅ API có |
| **Achievements Detail** | 🟡 Trung bình | Xem chi tiết achievement | ✅ API có |
| **Pronunciation History** | 🟡 Trung bình | Lịch sử luyện phát âm | ✅ API có |
| **Game History** | 🟡 Trung bình | Lịch sử game đã chơi | ✅ API có |
| **Apple Sign-in** | 🟡 Trung bình | OAuth authentication | ❌ Cần BE |
| **Google Sign-in** | 🟡 Trung bình | OAuth authentication | ❌ Cần BE |
| **Dark Mode Toggle** | 🟢 Thấp | Switch theme | Không cần |
| **Sound/Haptics Settings** | 🟢 Thấp | Preference settings | ✅ API có |

### 4.2 ❌ Chưa có (Nice to have)

| Tính năng | Mô tả | BE Ready |
|-----------|-------|----------|
| Character Animation | Animation stroke order | Không cần |
| Voice Feedback | TTS đọc kết quả | Không cần |
| Listening Comprehension | Nghe đoạn văn, trả lời | ❌ Cần BE |
| Reading Comprehension | Đọc hiểu passage | ❌ Cần BE |
| Grammar Lessons | Bài học ngữ pháp | ❌ Cần BE |
| Story Mode | Học qua câu chuyện | ❌ Cần BE |
| Multiplayer Game | Thi đấu realtime | ❌ Cần BE |
| Social Features | Follow, share progress | ❌ Cần BE |
| Widget iOS | Home screen widget | Không cần |
| Push Notifications | FCM/APNs | ❌ Cần BE |

---

## 5. YÊU CẦU TỪ BACKEND

### 5.1 ✅ API đã có và đang sử dụng

| Endpoint | Trạng thái | Ghi chú |
|----------|------------|---------|
| `/auth/*` | ✅ Đầy đủ | Magic link flow |
| `/me`, `/me/profile`, `/me/onboarding` | ✅ Đầy đủ | |
| `/me/stats`, `/me/achievements`, `/me/calendar` | ✅ Đầy đủ | |
| `/me/request-deletion`, `/me/cancel-deletion` | ✅ Đầy đủ | |
| `/today` | ✅ Đầy đủ | newQueue, reviewQueue |
| `/review/answer` | ✅ Đầy đủ | SRS rating submission |
| `/session/finish` | ✅ Đầy đủ | |
| `/vocabs`, `/vocabs/search`, `/vocabs/:id` | ✅ Đầy đủ | |
| `/vocabs/meta/topics`, `/vocabs/meta/types` | ✅ Đầy đủ | |
| `/favorites/*` | ✅ Đầy đủ | |
| `/decks/*` | ✅ Đầy đủ | |
| `/collections`, `/collections/:id` | ✅ Đầy đủ | |
| `/game/submit`, `/game/leaderboard/:type` | ✅ Đầy đủ | |
| `/pronunciation/*` | ✅ Đầy đủ | |
| `/offline/*` | ✅ Đầy đủ | Chưa implement FE |

### 5.2 ⚠️ API có nhưng chưa dùng đầy đủ

| Endpoint | Vấn đề | Hành động cần thiết |
|----------|--------|---------------------|
| `/study-modes` | Dùng fallback nhiều | Verify API response format |
| `/study-modes/:modeId/words` | Chỉ dùng cho writing | Mở rộng sử dụng |
| `/game/my-stats` | Chưa có UI | Thêm vào stats screen |
| `/pronunciation/history` | Chưa có UI | Thêm history tab |
| `/offline/bundles`, `/offline/bundle/:level` | Chưa implement | Cần implement download manager |
| `/me/achievements` | UI cơ bản | Thêm detail view |

### 5.3 ❌ API cần bổ sung

| Endpoint đề xuất | Mục đích |
|-----------------|----------|
| `GET /today/learned-today` | Lấy danh sách từ học hôm nay để review |
| `GET /vocabs/daily-pick` | Từ ngẫu nhiên/được đề xuất mỗi ngày |
| `POST /auth/apple` | Apple Sign-in |
| `POST /auth/google` | Google Sign-in |
| `POST /device/register` | Đăng ký device token cho push notifications |
| `GET /grammar/lessons` | Bài học ngữ pháp (nếu có) |
| `GET /reading/:id` | Bài đọc hiểu (nếu có) |
| `GET /user/xp` | Tổng XP và level của user |
| `POST /streak/protect` | Sử dụng streak protection (Premium) |

---

## 6. VẤN ĐỀ VỀ TÍNH LIÊN KẾT HỌC TẬP

### 6.1 Vấn đề chính: Flow học tập rời rạc

#### A. Thiếu Learning Path rõ ràng
- User không biết nên học gì tiếp theo
- Không có progression system (Level 1 → Level 2)
- Daily goal chỉ đếm thời gian, không đếm skills

#### B. Các module học độc lập
```
Today → Learn New → [Session/Practice] → Done
        ↓
        Review → [Session/Practice] → Done
        ↓
        Game 30s → Done
        
Pronunciation → Independent flow
Matching → Independent flow
```
- Không có liên kết giữa các mode
- Học xong 1 từ trong Learn New, không tự động xuất hiện trong Review sau X phút

#### C. SRS không được visualize
- User không thấy "đường cong quên lãng"
- Không thấy "interval" của mỗi từ sẽ tăng thế nào
- Không có dự báo "ngày mai bạn cần ôn X từ"

#### D. Thiếu Mastery Tracking theo Skills
```
Từ "你好" cần master:
- ✅ Nghĩa (đã test 5 lần, 100% đúng)
- ⚠️ Pinyin (đã test 3 lần, 66% đúng)
- ❌ Viết (chưa test)
- ⚠️ Phát âm (1 lần, 70%)
```
Hiện tại: Chỉ có 1 "state" chung cho cả từ

### 6.2 Vấn đề thứ hai: Personalization không đủ sâu

#### A. Focus Weights không được sử dụng
```dart
// Trong user profile:
focusWeights: {
  'listening': 0.4,
  'hanzi': 0.3,
  'meaning': 0.3
}
```
- Nhưng exercise generator không đọc weights này
- Tất cả users nhận cùng loại exercises

#### B. Difficulty adaptation thiếu
- Không có adaptive difficulty dựa trên performance
- User giỏi vẫn nhận bài tập dễ
- User yếu vẫn nhận bài tập khó

#### C. Goal Type không ảnh hưởng content
- User chọn "HSK Exam" vs "Conversation"
- Nhưng content giống nhau cho cả hai

### 6.3 Vấn đề thứ ba: Motivation & Engagement

#### A. Streak là động lực duy nhất
- Không có XP/Level system hiển thị
- Không có daily challenges
- Không có weekly goals

#### B. Achievements không có impact
- Unlock achievement → Toast → Done
- Không có rewards kèm theo
- Không có showcase/share

#### C. Leaderboard chỉ cho Game 30s
- Không có overall leaderboard
- Không có leaderboard cho streak
- Không có friends system

---

## 7. ĐỀ XUẤT CẢI THIỆN

### 7.1 🔴 Ưu tiên cao (Sprint 1-2)

#### A. Thống nhất Learning System
```
Đề xuất: Migrate hoàn toàn sang PracticeController
- Xóa SessionController
- PracticeMode.learnNew = 6 steps (learning content + exercises)
- Các mode khác = exercises only
```

#### B. Implement Stroke Writing
```
Sử dụng package: flutter_stroke_animation hoặc custom canvas
- Show stroke order animation
- Let user draw
- Validate strokes
```

#### C. Xây dựng Smart Learning Path
```dart
class LearningPath {
  // Gợi ý hành động tiếp theo
  RecommendedAction getNextAction() {
    if (dueForReview > 10) return ReviewAction();
    if (newLearnedToday < dailyLimit) return LearnNewAction();
    if (!pronunciationPracticedToday) return PronunciationAction();
    return Game30Action(); // Gamification
  }
}
```

### 7.2 🟡 Ưu tiên trung bình (Sprint 3-4)

#### A. Skill-based Mastery Tracking
```dart
class VocabMastery {
  String vocabId;
  Map<SkillType, SkillProgress> skills;
  // meaning, pinyin, listening, writing, pronunciation
}

class SkillProgress {
  int attempts;
  int correct;
  double mastery; // 0-100%
  DateTime lastPracticed;
}
```

#### B. XP & Level System
```dart
class UserProgress {
  int totalXP;
  int level; // XP thresholds
  int xpToNextLevel;
  List<XPActivity> recentXP;
}
```

#### C. Daily Challenges
```dart
class DailyChallenge {
  String id;
  String title; // "Học 10 từ mới", "Streak 3 trong Game 30s"
  int progress;
  int target;
  int xpReward;
  DateTime expiresAt;
}
```

### 7.3 🟢 Ưu tiên thấp (Backlog)

- Multiplayer game mode
- Social features (follow, share)
- Story mode learning
- Grammar lessons integration
- iOS Home Screen widget
- Apple Watch app
- Voice commands

---

## 8. ROADMAP ƯU TIÊN

### Phase 1: Foundation (2-3 tuần)
1. ✅ Audit và document toàn bộ codebase (DONE - tài liệu này)
2. 🔲 Merge SessionController vào PracticeController
3. 🔲 Implement Stroke Writing exercise
4. 🔲 Fix Speech Recognition fallback

### Phase 2: Learning Path (2-3 tuần)
1. 🔲 Design Smart Learning Path system
2. 🔲 BE: Add endpoint `/today/learned-today`
3. 🔲 Implement skill-based mastery tracking
4. 🔲 Add learning path recommendations UI

### Phase 3: Gamification (2 tuần)
1. 🔲 Design XP & Level system
2. 🔲 BE: Add XP tracking endpoints
3. 🔲 Implement XP display UI
4. 🔲 Add daily challenges

### Phase 4: Personalization (2 tuần)
1. 🔲 Use focusWeights in exercise generator
2. 🔲 Implement adaptive difficulty
3. 🔲 Customize content based on goal type

### Phase 5: Polish (1-2 tuần)
1. 🔲 Implement offline download
2. 🔲 Add notifications/reminders
3. 🔲 Improve animations/transitions
4. 🔲 Performance optimization

---

## 📝 Ghi chú cuối

**Tổng kết:**
- App có nền tảng tốt với đầy đủ core features
- Vấn đề chính là thiếu tính liên kết và cá nhân hóa
- Backend API khá đầy đủ, FE chưa tận dụng hết
- Cần focus vào user learning journey hơn là thêm features mới

**Đề xuất action tiếp theo:**
1. Review tài liệu này với team
2. Prioritize Phase 1 tasks
3. Tạo issues/tickets cho từng task
4. Sprint planning dựa trên roadmap

---

*Tài liệu được tạo tự động từ phân tích codebase. Cập nhật thường xuyên theo tiến độ phát triển.*

