# 🚨 LỖI CHƯA SỬA: DUPLICATE_ERROR Issue

## Trạng thái: CHƯA HOẠT ĐỘNG ❌

Backend vẫn đang trả về `DUPLICATE_ERROR` thay vì đăng nhập user có sẵn.

---

## Vấn đề hiện tại

**Log từ app:**
```
POST /auth/anonymous
Request: { deviceId: "device_xxx", deviceInfo: {...} }
Response: { "success": false, "error": { "message": "Duplicate entry", "code": "DUPLICATE_ERROR" } }
```

**Đây là SAI.** Khi deviceId đã tồn tại, backend PHẢI trả về tokens của user đó, KHÔNG được trả về lỗi.

---

## ✅ CÁCH SỬA ĐÚNG

### Endpoint: `POST /auth/anonymous`

```javascript
async function createOrLoginAnonymous(req, res) {
  const { deviceId, deviceInfo } = req.body;
  
  // 1. Hash deviceId
  const deviceIdHash = hashDeviceId(deviceId);
  
  // 2. TÌM USER BẤT KỂ STATUS (không filter status: 'active')
  let user = await User.findOne({ deviceIdHash });
  
  // 3. NẾU USER ĐÃ TỒN TẠI → TRẢ VỀ TOKENS
  if (user) {
    // Check nếu bị suspend
    if (user.status === 'suspended') {
      return res.status(401).json({
        success: false,
        error: { 
          message: 'Tài khoản đã bị tạm khóa', 
          code: 'ACCOUNT_SUSPENDED' 
        }
      });
    }
    
    // Reactivate nếu đã deleted
    if (user.status === 'deleted' || user.status === 'pending_deletion') {
      user.status = 'active';
      user.deletionScheduledAt = null;
    }
    
    // Update login time
    user.lastLoginAt = new Date();
    user.deviceInfo = deviceInfo;
    await user.save();
    
    // Generate tokens
    const tokens = generateTokens(user);
    
    // ✅ TRẢ VỀ TOKENS VỚI isNewUser: false
    return res.json({
      success: true,
      data: {
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        user: userToResponse(user),
        isNewUser: false  // ← QUAN TRỌNG
      }
    });
  }
  
  // 4. NẾU USER CHƯA TỒN TẠI → TẠO MỚI
  try {
    user = await User.create({
      deviceIdHash,
      deviceInfo,
      isAnonymous: true,
      displayName: `Người học #${Date.now().toString().slice(-6)}`,
      status: 'active',
      // KHÔNG set email: null, để undefined
    });
    
    const tokens = generateTokens(user);
    
    return res.json({
      success: true,
      data: {
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        user: userToResponse(user),
        isNewUser: true  // ← QUAN TRỌNG
      }
    });
    
  } catch (error) {
    // Handle race condition - duplicate key error
    if (error.code === 11000) {
      // Có ai đó vừa tạo user với deviceId này
      const existingUser = await User.findOne({ deviceIdHash });
      if (existingUser) {
        const tokens = generateTokens(existingUser);
        return res.json({
          success: true,
          data: {
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
            user: userToResponse(existingUser),
            isNewUser: false
          }
        });
      }
    }
    
    throw error;
  }
}
```

---

## ❌ KHÔNG ĐƯỢC LÀM

```javascript
// ❌ SAI - Query chỉ tìm active users
let user = await User.findOne({ deviceIdHash, status: 'active' });

// ❌ SAI - Throw error khi tìm thấy user
if (existingUser) {
  throw new Error('Duplicate entry');  // ← ĐÂY LÀ BUG
}

// ❌ SAI - Return lỗi DUPLICATE_ERROR
return res.status(400).json({
  success: false,
  error: { message: 'Duplicate entry', code: 'DUPLICATE_ERROR' }
});
```

---

## Bảng hành vi đúng

| Tình huống | deviceId tồn tại? | Response |
|------------|------------------|----------|
| Cài mới app | Không | `{ success: true, isNewUser: true, tokens }` |
| Mở lại app | Có | `{ success: true, isNewUser: false, tokens }` |
| Xóa app rồi cài lại | Có (deviceId được lưu) | `{ success: true, isNewUser: false, tokens }` |
| Thiết bị mới | Không | `{ success: true, isNewUser: true, tokens }` |
| User bị suspend | Có | `{ success: false, code: 'ACCOUNT_SUSPENDED' }` |

---

## Cách test

```bash
# 1. Gọi lần 1 - tạo user mới
curl -X POST https://your-api/auth/anonymous \
  -H "Content-Type: application/json" \
  -d '{"deviceId": "test_device_123", "deviceInfo": {"platform": "ios"}}'

# Expected: { success: true, isNewUser: true, ... }

# 2. Gọi lại với cùng deviceId - phải trả về tokens
curl -X POST https://your-api/auth/anonymous \
  -H "Content-Type: application/json" \
  -d '{"deviceId": "test_device_123", "deviceInfo": {"platform": "ios"}}'

# Expected: { success: true, isNewUser: false, ... }
# ❌ KHÔNG ĐƯỢC: { success: false, code: "DUPLICATE_ERROR" }
```

---

## Kiểm tra MongoDB Index

Nếu có unique index trên deviceIdHash, hãy đảm bảo:

```javascript
// Check index
db.users.getIndexes()

// Nếu có index gây conflict, hãy sử dụng findOneAndUpdate thay vì findOne + create
const user = await User.findOneAndUpdate(
  { deviceIdHash },
  {
    $setOnInsert: {
      deviceIdHash,
      deviceInfo,
      isAnonymous: true,
      displayName: `Người học #${Date.now().toString().slice(-6)}`,
      status: 'active',
      createdAt: new Date(),
    },
    $set: {
      lastLoginAt: new Date(),
      deviceInfo: deviceInfo,
    }
  },
  {
    upsert: true,
    new: true,
    setDefaultsOnInsert: true,
  }
);

const isNewUser = user.createdAt.getTime() > Date.now() - 1000; // Created within 1 second
```

---

## Checklist cho Backend Developer

- [ ] `POST /auth/anonymous` KHÔNG return `DUPLICATE_ERROR` khi deviceId tồn tại
- [ ] Khi deviceId tồn tại → return tokens của user đó
- [ ] Query tìm user KHÔNG filter theo `status`
- [ ] Handle deleted/pending_deletion users bằng cách reactivate
- [ ] Handle suspended users với error code riêng
- [ ] Handle race condition (MongoDB 11000)
- [ ] Return `isNewUser: true/false` trong response
- [ ] Test lại bằng curl với cùng deviceId 2 lần

---

## Tóm tắt

**Nguyên tắc vàng:** `POST /auth/anonymous` LUÔN trả về tokens nếu deviceId hợp lệ. KHÔNG BAO GIỜ trả về `DUPLICATE_ERROR`.
