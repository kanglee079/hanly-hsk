# Backend Fix: DUPLICATE_ERROR Issue

## Vấn đề hiện tại

Khi FE gọi `POST /auth/anonymous` với một `deviceId` đã tồn tại, BE trả về lỗi:
```json
{
  "success": false,
  "error": {
    "message": "Duplicate entry",
    "code": "DUPLICATE_ERROR"
  }
}
```

**Điều này gây ra lỗi UX** vì user không thể:
1. Vào lại account cũ (không có cách nào để login với deviceId)
2. Tạo account mới (BE reject với DUPLICATE_ERROR)

## Yêu cầu sửa đổi

### Option 1: Sửa `/auth/anonymous` để tự động login nếu deviceId đã tồn tại (RECOMMENDED)

```javascript
// POST /auth/anonymous
async function handleAnonymousAuth(req, res) {
  const { deviceId, deviceInfo } = req.body;
  
  // Hash ONLY deviceId (không hash deviceInfo)
  const deviceIdHash = crypto.createHash('sha256').update(deviceId).digest('hex');
  
  // Tìm user với deviceIdHash này
  const existingUser = await User.findOne({ deviceIdHash });
  
  if (existingUser) {
    // ✅ THAY VÌ throw DUPLICATE_ERROR
    // → Trả tokens của user cũ (giống như login)
    const tokens = generateTokens(existingUser);
    
    // Update deviceInfo nếu có thay đổi
    existingUser.lastLoginAt = new Date();
    await existingUser.save();
    
    return res.json({
      success: true,
      data: {
        userId: existingUser._id,
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        isAnonymous: existingUser.isAnonymous,
        isNewUser: false, // Flag để FE biết đây là user cũ
        createdAt: existingUser.createdAt
      }
    });
  }
  
  // Tạo user mới nếu deviceId chưa tồn tại
  const newUser = await User.create({
    deviceIdHash,
    isAnonymous: true,
    displayName: `Người học #${generateRandomId()}`,
    // ...other fields
  });
  
  const tokens = generateTokens(newUser);
  
  return res.json({
    success: true,
    data: {
      userId: newUser._id,
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      isAnonymous: true,
      isNewUser: true, // Flag để FE biết đây là user mới
      createdAt: newUser.createdAt
    }
  });
}
```

### Option 2: Tạo endpoint mới `/auth/device-login`

Nếu muốn giữ logic `/auth/anonymous` chỉ tạo mới:

```javascript
// POST /auth/device-login
async function handleDeviceLogin(req, res) {
  const { deviceId, deviceInfo } = req.body;
  
  const deviceIdHash = crypto.createHash('sha256').update(deviceId).digest('hex');
  const user = await User.findOne({ deviceIdHash });
  
  if (!user) {
    return res.status(404).json({
      success: false,
      error: {
        message: "Device not registered",
        code: "DEVICE_NOT_FOUND"
      }
    });
  }
  
  // Login existing user
  const tokens = generateTokens(user);
  user.lastLoginAt = new Date();
  await user.save();
  
  return res.json({
    success: true,
    data: {
      userId: user._id,
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      isAnonymous: user.isAnonymous,
      createdAt: user.createdAt
    }
  });
}
```

## Kiểm tra deviceIdHash

**QUAN TRỌNG**: Đảm bảo `deviceIdHash` chỉ được tính từ `deviceId`, KHÔNG bao gồm `deviceInfo`:

```javascript
// ✅ Đúng
const deviceIdHash = hash(deviceId);

// ❌ Sai - sẽ gây ra bug khi deviceInfo thay đổi
const deviceIdHash = hash(deviceId + JSON.stringify(deviceInfo));
```

## FE đang gửi gì

```json
{
  "deviceId": "device_1767981872267_870",
  "deviceInfo": {
    "platform": "ios",
    "osVersion": "Version 26.1 (Build 23B86)",
    "appVersion": "2.0.0",
    "model": "ios"
  }
}
```

`deviceId` là unique per device, được generate bằng: `device_${timestamp}_${random}`

## Expected Flow sau khi fix

```
┌─────────────────────────────────────────────────────────────┐
│                   POST /auth/anonymous                       │
├─────────────────────────────────────────────────────────────┤
│  Input: { deviceId, deviceInfo }                             │
│                                                              │
│  1. Hash deviceId → deviceIdHash                             │
│  2. Check database:                                          │
│     ├── deviceIdHash exists → Return existing user's tokens  │
│     └── deviceIdHash not found → Create new user             │
│  3. Return: { success, tokens, userId, isNewUser }           │
└─────────────────────────────────────────────────────────────┘
```

## Test Cases

1. **New device** → Create new user → Return tokens
2. **Existing device** → Login to existing user → Return tokens
3. **Existing device with linked email** → Return tokens with `isAnonymous: false`
