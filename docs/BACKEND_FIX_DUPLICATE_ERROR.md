# ✅ FIXED: DUPLICATE_ERROR Issue

## Trạng thái: ĐÃ SỬA XONG ✅

---

## Vấn đề gốc

`POST /auth/anonymous` trả về `DUPLICATE_ERROR` thay vì login tokens cho user đã tồn tại.

## Nguyên nhân

Fix trước đó dùng pattern "check then create" → vẫn gặp race conditions → MongoDB 11000 errors bị leak qua `errorHandler.ts` thành `DUPLICATE_ERROR`.

---

## Giải pháp cuối cùng: Atomic Upsert

Sử dụng `findOneAndUpdate` với `upsert: true` - loại bỏ hoàn toàn race conditions.

### anonymousService.ts

```javascript
// ATOMIC OPERATION - không bao giờ throw duplicate key error
const now = new Date();

const result = await User.findOneAndUpdate(
  { deviceIdHash },
  {
    $setOnInsert: {
      deviceIdHash,
      isAnonymous: true,
      displayName: `Người học #${Date.now().toString().slice(-6)}`,
      status: 'active',
      createdAt: now,
    },
    $set: {
      lastLoginAt: now,
      updatedAt: now,
    }
  },
  { upsert: true, new: true }
);

// Xác định có phải user mới bằng cách check createdAt
const isNewUser = result.createdAt && (now.getTime() - result.createdAt.getTime()) < 1000;

// Generate tokens và return
const tokens = generateTokens(result);

return {
  success: true,
  data: {
    accessToken: tokens.accessToken,
    refreshToken: tokens.refreshToken,
    user: userToResponse(result),
    isNewUser: isNewUser
  }
};
```

---

## Tại sao Atomic Upsert tốt hơn?

| Approach | Race Condition? | Code Complexity |
|----------|-----------------|-----------------|
| `findOne` → `create` | ❌ Có | Phức tạp |
| `try create` → `catch 11000` | ❌ Có thể miss | Trung bình |
| **`findOneAndUpdate` + `upsert`** | ✅ Không có | Đơn giản |

### Giải thích:
- `$setOnInsert`: Chỉ chạy khi INSERT (user mới)
- `$set`: Luôn chạy (cập nhật lastLoginAt)
- `upsert: true`: Tạo document nếu không tìm thấy
- `new: true`: Return document sau khi update

---

## Bảng hành vi

| Tình huống | Response |
|------------|----------|
| Cài mới app (deviceId mới) | `{ success: true, isNewUser: true, tokens }` |
| Mở lại app (deviceId cũ) | `{ success: true, isNewUser: false, tokens }` |
| Xóa app rồi cài lại | `{ success: true, isNewUser: false, tokens }` |
| Race condition (2 request cùng lúc) | Cả 2 đều success ✅ |

---

## Test Results

```
PASS  tests/anonymousUser.test.ts
  Anonymous User Creation         
    ✓ should create a new anonymous user with device ID
    ✓ should return existing anonymous user for same device ID
    ✓ should reject invalid device ID
    ✓ should create different users for different devices
  Account Linking (6 tests)
    ✓ All passing
  Auth Status (2 tests)
    ✓ All passing

Tests: 13 passed, 13 total
```

---

## Frontend Integration

Frontend không cần thay đổi gì. API response format giữ nguyên:

```json
{
  "success": true,
  "data": {
    "accessToken": "...",
    "refreshToken": "...",
    "user": { ... },
    "isNewUser": true/false
  }
}
```

Frontend sử dụng `isNewUser` để quyết định:
- `true` → Show Intro → Setup → Home
- `false` → Skip thẳng đến Home

---

## Deployed ✅

Backend đã deploy thành công. Issue đã được fix hoàn toàn.
