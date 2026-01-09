# 🔄 Kế hoạch chuyển đổi: Anonymous-First User Experience

> **Mục tiêu**: Cho phép người dùng sử dụng app ngay lập tức mà không cần đăng ký, chỉ yêu cầu tài khoản khi cần đồng bộ dữ liệu.

---

## 📋 Tổng quan thay đổi

### Trước (Hiện tại)
```
[Tải app] → [Bắt buộc Auth] → [Onboarding] → [Sử dụng app]
```

### Sau (Mới)
```
[Tải app] → [Onboarding] → [Sử dụng app ngay] → [Optional: Liên kết tài khoản khi cần]
```

---

## 🎯 Các thay đổi chính

| # | Thay đổi | Mô tả |
|---|----------|-------|
| 1 | **Anonymous User** | Mỗi thiết bị tự động tạo Anonymous User với Device ID |
| 2 | **Local-first Storage** | Dữ liệu học tập lưu local, sync lên server khi có mạng |
| 3 | **Optional Auth** | Chỉ cần đăng ký khi muốn: backup, chuyển thiết bị, leaderboard |
| 4 | **Account Linking** | Merge dữ liệu Anonymous → Registered User |
| 5 | **Remove Premium** | Bỏ paywall, tất cả tính năng miễn phí |
| 6 | **Add Donation** | Thêm tính năng donate tùy tâm |

---

## 🏗️ PHẦN 1: YÊU CẦU BACKEND API

### 1.1 Anonymous User Management

#### 1.1.1 `POST /auth/anonymous` - Tạo Anonymous User
Tự động tạo user ẩn danh khi app khởi động lần đầu.

**Request:**
```json
{
  "deviceId": "UUID-từ-device",
  "deviceInfo": {
    "platform": "ios",
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
    "userId": "anon_abc123xyz",
    "accessToken": "eyJhbGc...",
    "refreshToken": "eyJhbGc...",
    "isAnonymous": true,
    "createdAt": "2024-01-15T10:00:00Z"
  }
}
```

**Logic Backend:**
1. Check deviceId đã tồn tại chưa
2. Nếu có → return existing anonymous user
3. Nếu chưa → tạo mới với prefix `anon_`
4. Tạo token pair như user thường

---

#### 1.1.2 `POST /auth/link-account` - Liên kết tài khoản
Chuyển từ Anonymous → Registered User (giữ toàn bộ dữ liệu).

**Request:**
```json
{
  "email": "user@example.com",
  "linkMethod": "magic_link" | "apple" | "google"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "linkId": "link_xyz789",
    "method": "magic_link",
    "expiresAt": "2024-01-15T10:15:00Z",
    "message": "Đã gửi email xác nhận. Vui lòng kiểm tra hộp thư."
  }
}
```

---

#### 1.1.3 `POST /auth/verify-link` - Xác nhận liên kết
Hoàn tất quá trình liên kết sau khi user verify.

**Request:**
```json
{
  "linkId": "link_xyz789",
  "token": "abc123" // từ magic link hoặc OAuth
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "userId": "user_real123", // Đã upgrade từ anon_abc123xyz
    "email": "user@example.com",
    "isAnonymous": false,
    "accessToken": "new_access_token",
    "refreshToken": "new_refresh_token",
    "mergeResult": {
      "vocabsLearned": 156,
      "streakDays": 7,
      "totalXp": 2340
    }
  }
}
```

**Logic Backend QUAN TRỌNG:**
1. Kiểm tra email đã tồn tại chưa
2. **Nếu email mới**: 
   - Update anonymous user → registered user
   - Giữ nguyên userId hoặc tạo mới, migrate data
3. **Nếu email đã có tài khoản**:
   - Merge dữ liệu anonymous vào tài khoản existing
   - Xóa anonymous user
   - Return tokens của tài khoản existing

---

#### 1.1.4 `POST /auth/merge-accounts` - Merge dữ liệu khi conflict
Khi user có dữ liệu ở cả 2 nơi (anonymous + existing account).

**Request:**
```json
{
  "strategy": "keep_highest" | "keep_existing" | "keep_anonymous" | "merge_all"
}
```

**Merge Strategies:**
- `keep_highest`: Giữ số cao hơn (streak, XP, progress)
- `keep_existing`: Ưu tiên tài khoản đã đăng ký
- `keep_anonymous`: Ưu tiên dữ liệu anonymous
- `merge_all`: Cộng dồn tất cả (recommended)

**Response:**
```json
{
  "success": true,
  "data": {
    "mergedStats": {
      "vocabsLearned": 312, // 156 + 156
      "streakDays": 14, // max(7, 14)
      "totalXp": 5680, // 2340 + 3340
      "decksCount": 5
    },
    "conflicts": [], // Các conflict cần user quyết định
    "message": "Đã merge thành công dữ liệu học tập"
  }
}
```

---

#### 1.1.5 `GET /auth/status` - Kiểm tra trạng thái user
App gọi để biết user đang anonymous hay registered.

**Response:**
```json
{
  "success": true,
  "data": {
    "userId": "anon_abc123xyz",
    "isAnonymous": true,
    "hasLinkedEmail": false,
    "deviceId": "UUID",
    "createdAt": "2024-01-15T10:00:00Z",
    "stats": {
      "vocabsLearned": 156,
      "streakDays": 7,
      "canUseLeaderboard": false // Anonymous không thể dùng
    }
  }
}
```

---

### 1.2 Thay đổi các API hiện tại

#### 1.2.1 Tất cả API cần hỗ trợ Anonymous Token
- Token của anonymous user phải được chấp nhận như user thường
- Middleware check `isAnonymous` cho các feature restricted

#### 1.2.2 Restricted Features cho Anonymous User

| Feature | Anonymous | Registered |
|---------|-----------|------------|
| Học từ vựng | ✅ | ✅ |
| SRS Review | ✅ | ✅ |
| Game 30s | ✅ (không lưu rank) | ✅ |
| Favorites | ✅ (local) | ✅ (sync) |
| Decks | ✅ (local) | ✅ (sync) |
| Leaderboard | ❌ (chỉ xem) | ✅ (tham gia) |
| Backup/Restore | ❌ | ✅ |
| Multi-device | ❌ | ✅ |

#### 1.2.3 `GET /leaderboard` - Thêm filter
```json
{
  "entries": [...],
  "userRank": null, // null nếu anonymous
  "requiresAccount": true,
  "message": "Liên kết tài khoản để tham gia bảng xếp hạng"
}
```

---

### 1.3 Data Sync Strategy

#### 1.3.1 Local-first với Background Sync

**Nguyên tắc:**
1. Mọi action lưu local trước (immediate feedback)
2. Queue sync lên server khi có mạng
3. Conflict resolution: Last-write-wins hoặc manual merge

**New Endpoint: `POST /sync/batch`**
```json
{
  "lastSyncAt": "2024-01-15T10:00:00Z",
  "changes": [
    {
      "type": "vocab_progress",
      "action": "update",
      "data": { "vocabId": "v123", "level": 3, "nextReview": "..." },
      "timestamp": "2024-01-15T10:05:00Z"
    },
    {
      "type": "session_result",
      "action": "create",
      "data": { "seconds": 300, "newCount": 5, ... },
      "timestamp": "2024-01-15T10:10:00Z"
    }
  ]
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "syncedCount": 15,
    "conflicts": [],
    "serverTime": "2024-01-15T10:11:00Z"
  }
}
```

---

### 1.4 Donation System (Thay thế Premium)

#### 1.4.1 `GET /donations/options`
```json
{
  "success": true,
  "data": {
    "title": "Ủng hộ HanLy ❤️",
    "description": "Nếu bạn thấy app hữu ích, hãy ủng hộ để mình phát triển thêm!",
    "options": [
      { "id": "coffee", "amount": 25000, "label": "☕ Ly cà phê", "emoji": "☕" },
      { "id": "meal", "amount": 50000, "label": "🍜 Bữa ăn", "emoji": "🍜" },
      { "id": "support", "amount": 100000, "label": "💪 Ủng hộ", "emoji": "💪" },
      { "id": "sponsor", "amount": 500000, "label": "🌟 Tài trợ", "emoji": "🌟" },
      { "id": "custom", "amount": null, "label": "💝 Tùy chọn", "emoji": "💝" }
    ],
    "paymentMethods": [
      { "id": "momo", "name": "MoMo", "icon": "momo_icon" },
      { "id": "bank", "name": "Chuyển khoản", "icon": "bank_icon" },
      { "id": "iap", "name": "App Store", "icon": "apple_icon" }
    ],
    "stats": {
      "totalDonors": 156,
      "totalAmount": 15600000,
      "recentDonors": ["Minh N.", "Hà T.", "An L."]
    }
  }
}
```

#### 1.4.2 `POST /donations/create`
```json
{
  "optionId": "coffee", // hoặc "custom"
  "amount": 25000, // required nếu custom
  "paymentMethod": "momo",
  "message": "Cảm ơn app rất hay!" // optional
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "donationId": "don_xyz789",
    "paymentUrl": "https://momo.vn/...", // redirect user
    "qrCode": "base64...", // cho bank transfer
    "expiresAt": "2024-01-15T10:30:00Z"
  }
}
```

#### 1.4.3 `POST /donations/verify`
Webhook từ payment provider hoặc app verify.

#### 1.4.4 `GET /donations/history`
Lịch sử donate của user (nếu đã đăng ký).

---

## 🎨 PHẦN 2: YÊU CẦU FRONTEND

### 2.1 Luồng khởi động mới

```
┌─────────────────────────────────────────────────────────────┐
│                      APP LAUNCH                              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │  Check Local    │
                    │  User Data      │
                    └─────────────────┘
                              │
              ┌───────────────┴───────────────┐
              │                               │
              ▼                               ▼
    ┌─────────────────┐             ┌─────────────────┐
    │ First Launch    │             │ Returning User  │
    │ (No local data) │             │ (Has local data)│
    └─────────────────┘             └─────────────────┘
              │                               │
              ▼                               │
    ┌─────────────────┐                       │
    │ Create Anonymous│                       │
    │ User (API call) │                       │
    └─────────────────┘                       │
              │                               │
              ▼                               │
    ┌─────────────────┐                       │
    │   Onboarding    │                       │
    │  (Goal, Level)  │                       │
    └─────────────────┘                       │
              │                               │
              └───────────────┬───────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │   HOME SCREEN   │
                    │  (Today Tab)    │
                    └─────────────────┘
```

### 2.2 Files cần thay đổi

#### 2.2.1 Auth Service (`lib/app/services/auth_session_service.dart`)

```dart
// Thêm các method mới
class AuthSessionService {
  // Existing...
  
  /// Check if current user is anonymous
  bool get isAnonymous => _user?.isAnonymous ?? true;
  
  /// Create anonymous user on first launch
  Future<void> createAnonymousUser() async {
    final deviceId = await _getDeviceId();
    final response = await _api.post('/auth/anonymous', {
      'deviceId': deviceId,
      'deviceInfo': await _getDeviceInfo(),
    });
    await _saveTokens(response.data);
  }
  
  /// Link anonymous account to email
  Future<LinkResult> linkAccount(String email) async {
    final response = await _api.post('/auth/link-account', {
      'email': email,
      'linkMethod': 'magic_link',
    });
    return LinkResult.fromJson(response.data);
  }
  
  /// Verify link and complete account upgrade
  Future<void> verifyLink(String linkId, String token) async {
    final response = await _api.post('/auth/verify-link', {
      'linkId': linkId,
      'token': token,
    });
    await _saveTokens(response.data);
    await _refreshUser();
  }
}
```

#### 2.2.2 Splash Controller (`lib/app/modules/splash/splash_controller.dart`)

```dart
Future<void> _initializeApp() async {
  // Check local user data
  final hasLocalUser = await _authService.hasStoredSession();
  
  if (hasLocalUser) {
    // Try to restore session
    final success = await _authService.restoreSession();
    if (success) {
      _navigateToHome();
      return;
    }
  }
  
  // First launch or session expired
  // Create anonymous user
  await _authService.createAnonymousUser();
  
  // Check if completed onboarding
  final completedOnboarding = _storage.read('onboarding_complete') ?? false;
  
  if (completedOnboarding) {
    _navigateToHome();
  } else {
    _navigateToOnboarding();
  }
}
```

#### 2.2.3 Xóa/Sửa Auth Screens

| File | Action |
|------|--------|
| `auth_screen.dart` | Xóa hoặc chuyển thành "Link Account" screen |
| `auth_controller.dart` | Refactor thành `LinkAccountController` |
| `verify_screen.dart` | Giữ lại, dùng cho verify link |

#### 2.2.4 Thêm Account Linking UI

**Trong Me Screen hoặc Settings:**
```dart
// Hiển thị nếu user anonymous
if (authService.isAnonymous) {
  _buildLinkAccountCard();
}

Widget _buildLinkAccountCard() {
  return HMCard(
    child: Column(
      children: [
        Icon(Icons.cloud_upload, size: 48),
        Text('Bảo vệ dữ liệu học tập'),
        Text('Liên kết tài khoản để backup và đồng bộ trên nhiều thiết bị'),
        HMButton(
          text: 'Liên kết ngay',
          onPressed: () => Get.toNamed(Routes.linkAccount),
        ),
      ],
    ),
  );
}
```

### 2.3 Thay đổi Premium → Donation

#### 2.3.1 Xóa Premium

| File | Action |
|------|--------|
| `premium_screen.dart` | Xóa hoặc replace bằng Donation |
| `premium_controller.dart` | Xóa |
| `premium_binding.dart` | Xóa |

#### 2.3.2 Thêm Donation Screen

```dart
class DonationScreen extends GetView<DonationController> {
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: HMAppBar(title: 'Ủng hộ HanLy'),
      body: Column(
        children: [
          _buildHeader(), // Emoji, thank you message
          _buildDonationOptions(), // Coffee, Meal, Support...
          _buildPaymentMethods(), // MoMo, Bank, IAP
          _buildRecentDonors(), // Wall of fame
        ],
      ),
    );
  }
}
```

### 2.4 UI Prompts cho Anonymous User

#### 2.4.1 Khi truy cập Leaderboard
```dart
if (authService.isAnonymous) {
  _showLinkAccountPrompt(
    title: 'Tham gia bảng xếp hạng',
    message: 'Liên kết tài khoản để cạnh tranh với bạn bè!',
  );
}
```

#### 2.4.2 Khi streak đạt milestone (7, 30, 100 ngày)
```dart
_showLinkAccountPrompt(
  title: 'Tuyệt vời! $streakDays ngày liên tiếp! 🔥',
  message: 'Đừng để mất công sức. Liên kết tài khoản để bảo vệ tiến độ.',
);
```

#### 2.4.3 Reminder nhẹ nhàng (không spam)
- Sau 7 ngày sử dụng
- Sau khi học 100 từ
- Mỗi 30 ngày nếu chưa link

---

## 📦 PHẦN 3: DATABASE CHANGES (Backend)

### 3.1 User Table

```sql
ALTER TABLE users ADD COLUMN is_anonymous BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN device_id VARCHAR(255);
ALTER TABLE users ADD COLUMN linked_at TIMESTAMP NULL;
ALTER TABLE users ADD COLUMN anonymous_user_id VARCHAR(50) NULL; -- Để track merged from
```

### 3.2 New Tables

```sql
-- Donations table
CREATE TABLE donations (
  id VARCHAR(50) PRIMARY KEY,
  user_id VARCHAR(50) NOT NULL,
  amount INT NOT NULL,
  currency VARCHAR(3) DEFAULT 'VND',
  payment_method VARCHAR(20) NOT NULL,
  status ENUM('pending', 'completed', 'failed', 'refunded') DEFAULT 'pending',
  message TEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Account link requests
CREATE TABLE account_links (
  id VARCHAR(50) PRIMARY KEY,
  anonymous_user_id VARCHAR(50) NOT NULL,
  email VARCHAR(255) NOT NULL,
  method ENUM('magic_link', 'apple', 'google') NOT NULL,
  token VARCHAR(255) NOT NULL,
  status ENUM('pending', 'verified', 'expired') DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP NOT NULL,
  verified_at TIMESTAMP NULL
);

-- Sync queue for offline changes
CREATE TABLE sync_queue (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id VARCHAR(50) NOT NULL,
  change_type VARCHAR(50) NOT NULL,
  change_data JSON NOT NULL,
  client_timestamp TIMESTAMP NOT NULL,
  server_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  synced BOOLEAN DEFAULT false
);
```

---

## 📅 PHẦN 4: TIMELINE & PHASES

### Phase 1: Backend Preparation (1-2 tuần)
- [ ] Thêm anonymous user endpoints
- [ ] Modify existing APIs để accept anonymous tokens
- [ ] Implement account linking
- [ ] Add donation system APIs
- [ ] Database migrations

### Phase 2: Frontend Core Changes (1 tuần)
- [ ] Refactor auth flow
- [ ] Implement anonymous user creation
- [ ] Update splash/onboarding flow
- [ ] Remove mandatory auth screens

### Phase 3: Account Linking UI (3-5 ngày)
- [ ] Create LinkAccount screen
- [ ] Add prompts/nudges cho anonymous users
- [ ] Implement merge flow UI

### Phase 4: Donation Feature (3-5 ngày)
- [ ] Remove Premium screens
- [ ] Create Donation screen
- [ ] Integrate payment (MoMo/Bank/IAP)
- [ ] Add donor wall/thank you

### Phase 5: Testing & Polish (1 tuần)
- [ ] E2E testing new flows
- [ ] Edge cases (offline, merge conflicts)
- [ ] UI/UX polish
- [ ] Performance optimization

---

## ⚠️ PHẦN 5: MIGRATION STRATEGY

### Existing Users
1. Users đã đăng ký giữ nguyên
2. Update app sẽ tự động detect đã có account
3. Không ảnh hưởng gì

### Data Safety
1. Local data backup trước khi link
2. Server-side backup trước khi merge
3. Rollback option nếu merge fail

### Analytics
Track các metrics:
- % anonymous vs registered users
- Conversion rate (anon → registered)
- Trigger points hiệu quả nhất
- Donation conversion rate

---

## 🔐 PHẦN 6: SECURITY CONSIDERATIONS

### Device ID
- Sử dụng `identifierForVendor` (iOS) - reset khi reinstall
- Không dùng IDFA (cần permission)
- Fallback: UUID lưu trong Keychain (persist qua reinstall)

### Anonymous Token Security
- Same security level as regular tokens
- Short expiry, refresh mechanism
- Rate limiting per device

### Account Linking
- Email verification required
- OTP/Magic link expiry: 15 minutes
- One-time use tokens
- Prevent account hijacking

---

## ✅ Checklist trước khi bắt đầu

### Backend Team
- [ ] Review API spec này
- [ ] Confirm database changes
- [ ] Estimate timeline
- [ ] Identify blockers

### Frontend Team
- [ ] Review UI/UX changes
- [ ] Confirm compatible với current codebase
- [ ] Estimate timeline
- [ ] Identify blockers

### Product
- [ ] Confirm donation tiers
- [ ] Confirm prompt messages
- [ ] Confirm analytics requirements

---

## 📝 Notes

1. **Ưu tiên UX**: Người dùng phải cảm thấy việc link account là có lợi, không phải bị ép
2. **Không spam**: Prompts thông minh, không gây khó chịu
3. **Data safety**: Luôn có backup, user không mất dữ liệu
4. **Graceful degradation**: Offline vẫn dùng được app bình thường

---

*Document version: 1.0*
*Created: January 2025*
*Author: AI Assistant*
