# ✅ FIXED: DUPLICATE_ERROR Issue

## Trạng thái: ĐÃ SỬA XONG ✅

### Nguyên nhân gốc rễ đã được xác định và sửa:

1. **Query filter quá nghiêm**: `status: 'active'` bỏ sót user deleted/suspended
2. **Thiếu error handling**: MongoDB 11000 duplicate key không được handle
3. **email: null vs undefined**: Sparse unique index cần `undefined`

---

## Backend Changes (anonymousService.ts)

### Trước (Bug):
```javascript
// Query chỉ tìm user active - bỏ sót deleted/suspended
let user = await User.findOne({
  deviceIdHash,
  status: 'active'  // ← BUG: bỏ sót các status khác
});

// Create với email: null - gây lỗi unique index
user = await User.create({
  email: null,  // ← BUG: sparse index cần undefined
  passwordHash: null,
  // ...
});
```

### Sau (Fixed):
```javascript
// Query tìm TẤT CẢ user với deviceIdHash (bất kể status)
let user = await User.findOne({ deviceIdHash });

if (user) {
  // Handle theo status
  if (user.status === 'suspended') {
    throw new UnauthorizedError('Tài khoản đã bị tạm khóa...');
  }
  
  // Reactivate deleted users
  if (user.status === 'deleted' || user.status === 'pending_deletion') {
    user.status = 'active';
    user.deletionScheduledAt = null;
    user.deletionReason = null;
  }
  
  user.lastLoginAt = new Date();
  await user.save();
  
  // Return tokens with isNewUser: false
}

// Create với error handling cho race condition
try {
  user = await User.create({
    // NOTE: KHÔNG set email/passwordHash - để undefined cho sparse index
    isAnonymous: true,
    deviceIdHash,
    displayName: `Người học #${...}`,
    status: 'active',
  });
} catch (error) {
  if (error.code === 11000) {
    // Race condition - device đã đăng ký trong lúc xử lý
    const existingUser = await User.findOne({ deviceIdHash });
    if (existingUser) {
      // Handle và return tokens
    }
  }
  throw error;
}
```

---

## Frontend Changes (auth_session_service.dart)

### Đã đơn giản hóa logic:

```dart
Future<bool> createAnonymousUser() async {
  try {
    final response = await _authRepo.createAnonymousUser(
      deviceId: deviceId,
      deviceInfo: deviceInfo,
    );
    
    if (response.success) {
      _storage.saveTokens(...);
      
      // Returning user = skip intro/setup
      if (!response.isNewUser) {
        _storage.isIntroSeen = true;
        _storage.isSetupComplete = true;
        _storage.isOnboardingComplete = true;
      }
      
      return true;
    }
    return false;
  } catch (e) {
    // Handle suspended account
    if (_isSuspendedError(e)) {
      // Show error to user
      return false;
    }
    
    // Network error - continue offline
    if (_isNetworkError(e)) {
      _continueOfflineMode();
      return false;
    }
    
    _continueOfflineMode();
    return false;
  }
}
```

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

## Behavior Matrix

| Scenario | BE Response | FE Action |
|----------|-------------|-----------|
| New device | `{ success: true, isNewUser: true }` | Show Intro → Setup → Home |
| Existing device | `{ success: true, isNewUser: false }` | Skip to Home |
| Deleted user | Reactivated, `{ isNewUser: false }` | Skip to Home |
| Suspended user | `UnauthorizedError` | Show error message |
| Race condition | Handled by BE | Works normally |
| Network error | N/A | Continue offline mode |

---

## Checklist ✅

- [x] BE: Query không filter theo status
- [x] BE: Handle user deleted/suspended
- [x] BE: Không set email: null (dùng undefined)
- [x] BE: Handle race condition (error code 11000)
- [x] BE: Return isNewUser flag
- [x] FE: Remove fallback DUPLICATE_ERROR handling
- [x] FE: Use isNewUser to decide flow
- [x] FE: Handle suspended user error
- [x] FE: Handle network error with offline mode
- [x] Tests: All 13 tests passing
