# 🤖 Prompt cho AI sửa Backend

Copy đoạn prompt dưới đây và gửi cho AI (Claude/ChatGPT) cùng với codebase backend của bạn:

---

## PROMPT BẮT ĐẦU TỪ ĐÂY:

---

Tôi cần bạn giúp tôi refactor backend để hỗ trợ **Anonymous-First User Experience**. Đây là thay đổi lớn trong kiến trúc authentication của app.

## 📋 TÓM TẮT YÊU CẦU

### Mục tiêu chính:
1. **Anonymous User**: Cho phép người dùng sử dụng app ngay mà không cần đăng ký. Mỗi thiết bị tự động được tạo một anonymous user.
2. **Account Linking**: Người dùng có thể liên kết email để backup/sync dữ liệu giữa các thiết bị.
3. **Full Feature Access**: Anonymous users được dùng ĐẦY ĐỦ tất cả tính năng (không có premium/paywall).
4. **Donation System**: Thay thế Premium bằng hệ thống donate tùy tâm.

---

## 🔧 CÁC API CẦN THÊM MỚI

### 1. `POST /auth/anonymous` - Tạo Anonymous User

Khi app khởi động lần đầu, tự động tạo anonymous user.

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

**Logic cần implement:**
1. Check `deviceId` đã tồn tại trong DB chưa
2. Nếu có → return existing anonymous user + tokens mới
3. Nếu chưa → tạo user mới với:
   - `userId` có prefix `anon_` + random string
   - `isAnonymous = true`
   - `deviceId` lưu vào DB
4. Generate access token + refresh token như user thường
5. Anonymous token phải được chấp nhận bởi tất cả API như user thường

---

### 2. `POST /auth/link-account` - Bắt đầu liên kết tài khoản

Gửi magic link để liên kết email với anonymous user.

**Request:**
```json
{
  "email": "user@example.com"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "linkId": "link_xyz789",
    "expiresAt": "2024-01-15T10:15:00Z",
    "message": "Đã gửi email xác nhận. Vui lòng kiểm tra hộp thư."
  }
}
```

**Logic cần implement:**
1. Lấy current user từ token (anonymous user)
2. Check email đã tồn tại trong hệ thống chưa:
   - Nếu chưa → tạo link request mới
   - Nếu có → chuẩn bị merge (xem bước 3)
3. Tạo `linkId` và `token` ngẫu nhiên
4. Lưu vào bảng `account_links` với status = 'pending'
5. Gửi email với link verify (giống magic link hiện tại)
6. Token expire sau 15 phút

---

### 3. `POST /auth/verify-link` - Xác nhận và hoàn tất liên kết

**Request:**
```json
{
  "linkId": "link_xyz789",
  "token": "abc123"
}
```

**Response (200 OK) - Trường hợp email mới:**
```json
{
  "success": true,
  "data": {
    "userId": "user_real123",
    "email": "user@example.com",
    "isAnonymous": false,
    "accessToken": "new_access_token",
    "refreshToken": "new_refresh_token",
    "message": "Đã liên kết tài khoản thành công!"
  }
}
```

**Response (200 OK) - Trường hợp email đã có tài khoản:**
```json
{
  "success": true,
  "data": {
    "userId": "existing_user_456",
    "email": "user@example.com",
    "isAnonymous": false,
    "accessToken": "...",
    "refreshToken": "...",
    "merged": true,
    "mergeResult": {
      "vocabsLearned": 312,
      "streakDays": 14,
      "totalXp": 5680,
      "message": "Đã merge dữ liệu từ thiết bị này vào tài khoản có sẵn"
    }
  }
}
```

**Logic cần implement:**

**Trường hợp A: Email mới (chưa có tài khoản)**
1. Validate `linkId` và `token`
2. Update anonymous user:
   - Set `email = email từ request`
   - Set `isAnonymous = false`
   - Optional: đổi userId prefix từ `anon_` sang `user_`
3. Update `account_links.status = 'verified'`
4. Generate new token pair
5. Giữ nguyên toàn bộ dữ liệu học tập

**Trường hợp B: Email đã có tài khoản (MERGE)**
1. Validate `linkId` và `token`
2. Lấy existing user từ email
3. Merge dữ liệu từ anonymous user vào existing user:
   - `vocabsLearned`: cộng dồn
   - `streakDays`: lấy max
   - `totalXp`: cộng dồn
   - `vocab_progress`: merge, giữ level cao hơn cho mỗi từ
   - `favorites`: union
   - `decks`: union (rename nếu trùng tên)
   - `session_results`: copy tất cả sang existing user
4. Xóa anonymous user (hoặc mark as merged)
5. Return tokens của existing user

---

### 4. `GET /auth/status` - Kiểm tra trạng thái tài khoản

**Response:**
```json
{
  "success": true,
  "data": {
    "userId": "anon_abc123xyz",
    "isAnonymous": true,
    "hasEmail": false,
    "email": null,
    "deviceId": "UUID",
    "createdAt": "2024-01-15T10:00:00Z"
  }
}
```

---

### 5. `POST /auth/login` - Đăng nhập tài khoản có sẵn

Cho phép user đăng nhập vào tài khoản đã đăng ký (từ thiết bị mới).

**Request:**
```json
{
  "email": "user@example.com"
}
```

**Logic:**
- Gửi magic link như hiện tại
- Sau khi verify, nếu thiết bị có anonymous data:
  - Hỏi user có muốn merge không
  - Hoặc tự động merge với strategy `merge_all`

---

## 🗄️ DATABASE CHANGES

### Sửa bảng `users`:
```sql
ALTER TABLE users ADD COLUMN is_anonymous BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN device_id VARCHAR(255) NULL;
ALTER TABLE users ADD COLUMN linked_at TIMESTAMP NULL;
ALTER TABLE users ADD COLUMN merged_from_user_id VARCHAR(50) NULL;
```

### Thêm bảng `account_links`:
```sql
CREATE TABLE account_links (
  id VARCHAR(50) PRIMARY KEY,
  anonymous_user_id VARCHAR(50) NOT NULL,
  email VARCHAR(255) NOT NULL,
  token VARCHAR(255) NOT NULL,
  status ENUM('pending', 'verified', 'expired') DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP NOT NULL,
  verified_at TIMESTAMP NULL,
  FOREIGN KEY (anonymous_user_id) REFERENCES users(id)
);
```

### Thêm bảng `donations` (thay Premium):
```sql
CREATE TABLE donations (
  id VARCHAR(50) PRIMARY KEY,
  user_id VARCHAR(50) NOT NULL,
  amount INT NOT NULL,
  currency VARCHAR(3) DEFAULT 'VND',
  payment_method VARCHAR(20) NOT NULL,
  status ENUM('pending', 'completed', 'failed') DEFAULT 'pending',
  message TEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

---

## 🔒 SECURITY REQUIREMENTS

1. **Anonymous tokens** phải có cùng security level như regular tokens
2. **Device ID** nên được hash trước khi lưu DB
3. **Link tokens** expire sau 15 phút, one-time use
4. **Rate limiting**: Max 3 link requests / email / hour
5. **Merge operation** phải atomic (transaction)

---

## ✅ CHECKLIST IMPLEMENTATION

### Phase 1: Anonymous User
- [ ] Thêm columns vào bảng `users`
- [ ] Tạo endpoint `POST /auth/anonymous`
- [ ] Update middleware để accept anonymous tokens
- [ ] Test: tạo anonymous user, gọi các API khác

### Phase 2: Account Linking
- [ ] Tạo bảng `account_links`
- [ ] Tạo endpoint `POST /auth/link-account`
- [ ] Tạo endpoint `POST /auth/verify-link`
- [ ] Implement merge logic
- [ ] Test: link email mới, link email có sẵn

### Phase 3: Donation (Optional, có thể làm sau)
- [ ] Tạo bảng `donations`
- [ ] Tạo endpoint `GET /donations/options`
- [ ] Tạo endpoint `POST /donations/create`
- [ ] Integrate payment provider

---

## 📝 GHI CHÚ QUAN TRỌNG

1. **KHÔNG thay đổi** các API hiện tại (/vocabs, /today, /review, etc.) - chỉ cần đảm bảo chúng accept anonymous token
2. **KHÔNG có feature restriction** cho anonymous users - tất cả tính năng đều available
3. **Backward compatible**: Users đã đăng ký vẫn hoạt động bình thường
4. **Token refresh** vẫn hoạt động như cũ cho cả anonymous và registered users

---

## 🚀 BẮT ĐẦU

Hãy bắt đầu bằng việc:
1. Review codebase hiện tại của tôi
2. Xác định những file nào cần sửa
3. Đề xuất thứ tự implementation
4. Bắt đầu implement Phase 1 (Anonymous User) trước

Đây là codebase backend của tôi: [PASTE BACKEND CODE HOẶC ATTACH FILES]

---

## KẾT THÚC PROMPT

---

**Hướng dẫn sử dụng:**
1. Copy toàn bộ nội dung từ "PROMPT BẮT ĐẦU TỪ ĐÂY" đến "KẾT THÚC PROMPT"
2. Paste vào chat với AI (Claude/ChatGPT/Cursor)
3. Attach hoặc paste codebase backend của bạn
4. AI sẽ review và bắt đầu implement

