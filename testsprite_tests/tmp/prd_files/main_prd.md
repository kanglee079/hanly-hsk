# Product Requirements Document: Học Tiếng Trung HSK – HanLy

## 1. Overview
HanLy is a premium iOS Chinese learning app focused on HSK vocabulary mastery through spaced repetition, gamification, and immersive learning experiences.

## 2. Target Users
- Vietnamese speakers learning Chinese
- HSK exam preparation students (levels 1-6)
- Casual learners interested in Chinese vocabulary

## 3. Core Features

### 3.1 Authentication
- **Magic Link Email Authentication**: Users enter email, receive a magic link, and verify to login
- Token-based authentication with automatic refresh
- Account deletion capability

### 3.2 Onboarding
- Goal selection (exam prep, casual learning, business, travel)
- Current HSK level assessment
- Daily learning time preference (5, 10, 15, 20, 30 minutes)
- Focus skills selection (listening, reading, writing, speaking)

### 3.3 Today/Home Screen
- Progress ring showing daily goal completion
- Streak counter with celebration animations
- Quick actions: Learn New, Review, 30s Game
- Due today word list
- Weekly progress summary

### 3.4 Learn Modes
- **Flashcards**: SRS-based vocabulary cards with 3D flip animation
- **Listening Practice**: Audio-based MCQ exercises
- **Pronunciation Practice**: Speech recognition for pronunciation feedback
- **Matching Game**: Match Hanzi with meanings
- **MCQ Exercises**: Various formats (Hanzi→Meaning, Meaning→Hanzi, Audio→Hanzi)

### 3.5 Explore
- Full vocabulary search with filters
- Filter by HSK level, topic, word type
- Quick actions: add to favorites, add to deck
- Word detail navigation

### 3.6 Word Detail
- Hanzi with pinyin and Vietnamese meaning
- Audio playback (normal and slow speed)
- Radical/component breakdown (Hanzi DNA)
- Example sentences with audio
- Collocations
- Add to favorites/deck actions

### 3.7 Practice Sessions
- Unified 5-step learning flow
- SRS rating system (Again/Hard/Good/Easy)
- Progress tracking per session
- Completion summary with accuracy stats

### 3.8 Game 30s
- 30-second speed vocabulary game
- Score calculation based on correct answers
- Leaderboard with top players
- Daily game limits

### 3.9 Favorites & Decks
- Save favorite vocabulary words
- Create custom vocabulary decks
- Add/remove words from decks

### 3.10 Profile & Settings
- User profile display
- Logout functionality
- Account deletion
- Settings (stubs for privacy/terms)

## 4. Navigation Structure
Bottom navigation with 4 tabs:
1. **Today** - Daily dashboard and quick actions
2. **Learn** - Learning modes and sessions
3. **Explore** - Vocabulary search and discovery
4. **Me** - Profile, favorites, decks, settings

## 5. UI/UX Requirements
- Premium, clean, calm design aesthetic
- Consistent spacing, typography, colors, shadows
- Reusable components (HMButton, HMCard, HMChip, etc.)
- Dark mode support
- Smooth animations and transitions

## 6. Technical Requirements
- iOS-first (Flutter)
- GetX state management
- GetStorage local persistence
- Dio networking with auth interceptors
- Configurable API base URL via dart-define

## 7. API Integration
All features integrate with backend API endpoints for:
- Authentication flow
- Vocabulary data
- Learning progress tracking
- SRS scheduling
- Game results and leaderboards
- User preferences

