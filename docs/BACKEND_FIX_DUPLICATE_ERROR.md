# 🚨 CRITICAL Backend Fix: DUPLICATE_ERROR Issue

## Tình trạng hiện tại: APP KHÔNG SỬ DỤNG ĐƯỢC

### Triệu chứng
Khi user **xóa app và cài lại**, hoặc **lần đầu mở app**, gặp lỗi:

```
POST /auth/anonymous (deviceId_A) → DUPLICATE_ERROR
POST /auth/device-login (deviceId_A) → NOT_FOUND (endpoint chưa có)
POST /auth/anonymous (deviceId_B mới) → VẪN DUPLICATE_ERROR ← BUG NGHIÊM TRỌNG!
```

### Vấn đề nghiêm trọng
- Device ID hoàn toàn MỚI `device_1768024248835_603` vẫn bị DUPLICATE_ERROR
- Điều này chứng tỏ có BUG trong backend logic

---

## Root Cause Analysis

### Khả năng cao nhất:
Backend đang check duplicate theo `deviceInfo` hoặc tổ hợp field khác, KHÔNG phải chỉ `deviceId`.

### Check lại code BE:

1. **Unique Index trên MongoDB** - Có index nào KHÔNG chỉ dựa trên `deviceIdHash`?
   ```javascript
   // Check schema User
   userSchema.index({ deviceIdHash: 1 }, { unique: true, sparse: true });
   // Có index nào khác gây duplicate không?
   ```

2. **Hash function** - Có đang hash cả deviceInfo không?
   ```javascript
   // ❌ SAI - sẽ khác nhau mỗi lần
   const hash = sha256(deviceId + JSON.stringify(deviceInfo));
   
   // ✅ ĐÚNG - luôn giống nhau cho cùng device
   const hash = sha256(deviceId);
   ```

3. **Unique constraint trên field khác** - Check xem có unique constraint nào trên field khác như `displayName` không?

---

## Yêu cầu Fix (CHỌN 1 TRONG 2)

### OPTION 1: Sửa `/auth/anonymous` (RECOMMENDED) ⭐

Logic mới: Nếu deviceId đã tồn tại → trả token của user cũ (giống login)

```javascript
// POST /auth/anonymous
exports.createAnonymousUser = async (req, res) => {
  try {
    const { deviceId, deviceInfo } = req.body;
    
    if (!deviceId) {
      return res.status(400).json({
        success: false,
        error: { message: 'deviceId is required', code: 'VALIDATION_ERROR' }
      });
    }
    
    // QUAN TRỌNG: Chỉ hash deviceId, KHÔNG hash deviceInfo
    const deviceIdHash = crypto.createHash('sha256').update(deviceId).digest('hex');
    
    // TÌM USER CŨ
    let user = await User.findOne({ deviceIdHash });
    let isNewUser = false;
    
    if (user) {
      // ============================================
      // THAY ĐỔI QUAN TRỌNG:
      // Thay vì throw DUPLICATE_ERROR → trả token
      // ============================================
      console.log(`Device ${deviceId} already exists, returning existing user`);
      
      // Update last login
      user.lastLoginAt = new Date();
      if (deviceInfo) {
        user.deviceInfo = deviceInfo;
      }
      await user.save();
      
    } else {
      // TẠO USER MỚI
      isNewUser = true;
      user = await User.create({
        deviceIdHash,
        deviceInfo,
        isAnonymous: true,
        status: 'active',
        displayName: `Người học #${Math.random().toString(36).substring(2, 8)}`,
        profile: {
          hskLevel: 1,
          dailyGoal: 10,
          targetMinutes: 10,
          dailyNewLimit: 10,
        }
      });
    }
    
    // GENERATE TOKENS
    const tokens = generateTokenPair(user._id);
    
    return res.json({
      success: true,
      data: {
        userId: user._id,
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        isAnonymous: user.isAnonymous,
        email: user.email || null,
        isNewUser: isNewUser // ← FE dùng flag này để biết cần show intro hay không
      }
    });
    
  } catch (error) {
    console.error('createAnonymousUser error:', error);
    
    // Nếu vẫn lỗi duplicate (race condition) → thử tìm lại
    if (error.code === 11000) {
      const deviceIdHash = crypto.createHash('sha256')
        .update(req.body.deviceId)
        .digest('hex');
      
      const existingUser = await User.findOne({ deviceIdHash });
      if (existingUser) {
        const tokens = generateTokenPair(existingUser._id);
        return res.json({
          success: true,
          data: {
            userId: existingUser._id,
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
            isAnonymous: existingUser.isAnonymous,
            email: existingUser.email || null,
            isNewUser: false
          }
        });
      }
    }
    
    return res.status(500).json({
      success: false,
      error: { message: error.message, code: 'SERVER_ERROR' }
    });
  }
};
```

### OPTION 2: Thêm endpoint `/auth/device-login`

Nếu muốn giữ `/auth/anonymous` chỉ tạo mới:

```javascript
// POST /auth/device-login
exports.deviceLogin = async (req, res) => {
  try {
    const { deviceId, deviceInfo } = req.body;
    
    if (!deviceId) {
      return res.status(400).json({
        success: false,
        error: { message: 'deviceId is required', code: 'VALIDATION_ERROR' }
      });
    }
    
    const deviceIdHash = crypto.createHash('sha256').update(deviceId).digest('hex');
    const user = await User.findOne({ deviceIdHash, status: 'active' });
    
    if (!user) {
      return res.status(404).json({
        success: false,
        error: { message: 'Device not found', code: 'DEVICE_NOT_FOUND' }
      });
    }
    
    // Update last login
    user.lastLoginAt = new Date();
    if (deviceInfo) {
      user.deviceInfo = deviceInfo;
    }
    await user.save();
    
    const tokens = generateTokenPair(user._id);
    
    return res.json({
      success: true,
      data: {
        userId: user._id,
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        isAnonymous: user.isAnonymous,
        email: user.email || null,
        isNewUser: false
      }
    });
    
  } catch (error) {
    console.error('deviceLogin error:', error);
    return res.status(500).json({
      success: false,
      error: { message: error.message, code: 'SERVER_ERROR' }
    });
  }
};

// Đăng ký route
router.post('/device-login', authController.deviceLogin);
```

---

## FE đang gửi data như thế nào

```json
{
  "deviceId": "device_1768024110214_155",
  "deviceInfo": {
    "platform": "ios",
    "osVersion": "Version 26.1 (Build 23B86)",
    "appVersion": "2.0.0",
    "model": "ios"
  }
}
```

- `deviceId` format: `device_{timestamp}_{random}` - unique mỗi lần generate
- `deviceId` được lưu trên device, sẽ không đổi trừ khi xóa app

---

## Flow mong đợi sau khi fix

```
┌────────────────────────────────────────────────────────────────────┐
│                     POST /auth/anonymous                            │
├────────────────────────────────────────────────────────────────────┤
│                                                                    │
│  Request: { deviceId: "device_xxx", deviceInfo: {...} }            │
│                                                                    │
│  ┌─────────────────────────────────────────────────────────┐       │
│  │ 1. deviceIdHash = sha256(deviceId)   ← CHỈ HASH deviceId│       │
│  └─────────────────────────────────────────────────────────┘       │
│                          │                                         │
│                          ▼                                         │
│           ┌──────────────────────────────┐                         │
│           │ User.findOne({ deviceIdHash })│                        │
│           └──────────────────────────────┘                         │
│                          │                                         │
│           ┌──────────────┴──────────────┐                          │
│           │                             │                          │
│           ▼                             ▼                          │
│     User EXISTS                   User NOT FOUND                   │
│           │                             │                          │
│           ▼                             ▼                          │
│   Return tokens                   Create new user                  │
│   isNewUser: false                isNewUser: true                  │
│                                                                    │
│  Response: {                                                       │
│    success: true,                                                  │
│    data: { userId, accessToken, refreshToken, isNewUser }          │
│  }                                                                 │
└────────────────────────────────────────────────────────────────────┘
```

---

## Test Cases cần pass

| Case | Input | Expected Output |
|------|-------|-----------------|
| 1. New device | deviceId chưa tồn tại | `{ success: true, isNewUser: true }` |
| 2. Existing device | deviceId đã tồn tại | `{ success: true, isNewUser: false }` |
| 3. Same device, different deviceInfo | deviceId cũ, deviceInfo mới | `{ success: true, isNewUser: false }` |
| 4. Linked account | deviceId có email linked | `{ success: true, isAnonymous: false }` |

---

## Checklist trước khi deploy

- [ ] Chỉ hash `deviceId`, KHÔNG hash `deviceInfo`
- [ ] Không throw DUPLICATE_ERROR, trả token thay vào
- [ ] Trả `isNewUser: true/false` để FE biết cần show intro hay không
- [ ] Handle race condition với error code 11000
- [ ] Test cả 4 case ở trên
- [ ] Deploy và verify với FE

---

## Liên hệ

Nếu có thắc mắc về logic FE, liên hệ team FE để clarify.
