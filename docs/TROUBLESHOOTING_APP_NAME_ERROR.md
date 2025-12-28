# Hướng Dẫn Khắc Phục Lỗi "App Name Already Being Used"

## 🔍 Nguyên Nhân Của Lỗi

Lỗi **"App Record Creation failed due to request containing an attribute already in use"** có thể xảy ra do các nguyên nhân sau:

### 1. **Tên App Đã Tồn Tại Trong App Store Connect Của Bạn** ⚠️ (Nguyên nhân phổ biến nhất)
- Bạn đã tạo app với tên này trước đó trong tài khoản của mình
- App có thể đang ở trạng thái "Prepare for Submission", "Waiting for Review", hoặc đã bị xóa nhưng vẫn còn trong hệ thống

### 2. **Bundle ID Đã Được Đăng Ký**
- Bundle ID `com.hskvocab.chuyennghiep` đã được tạo trong Apple Developer Portal
- Hoặc đã được sử dụng trong một app khác trong tài khoản của bạn

### 3. **SKU Trùng Lặp**
- SKU (Stock Keeping Unit) phải là duy nhất trong tài khoản của bạn
- Nếu bạn đã tạo app với SKU tương tự trước đó, sẽ bị lỗi

### 4. **Tên App Đã Tồn Tại Trên App Store**
- Có app khác trên App Store đã sử dụng tên tương tự
- Apple có thể từ chối nếu tên quá giống nhau

## ✅ Cách Kiểm Tra Và Khắc Phục

### Bước 1: Kiểm Tra App Store Connect

1. **Đăng nhập vào App Store Connect:**
   - Truy cập: https://appstoreconnect.apple.com
   - Đăng nhập với tài khoản Apple Developer của bạn

2. **Kiểm tra danh sách app hiện có:**
   - Vào **My Apps**
   - Xem tất cả các app trong tài khoản của bạn
   - Kiểm tra xem có app nào đã dùng:
     - Tên: "Học Từ Vựng HSK Chuyên Nghiệp" hoặc tên tương tự
     - Bundle ID: `com.hskvocab.chuyennghiep` hoặc Bundle ID tương tự

3. **Kiểm tra app đã bị xóa:**
   - Trong App Store Connect, có thể có app đã bị xóa nhưng vẫn còn trong hệ thống
   - Kiểm tra cả các app ở trạng thái "Removed from Sale"

### Bước 2: Kiểm Tra Apple Developer Portal

1. **Kiểm tra Bundle ID:**
   - Truy cập: https://developer.apple.com/account/resources/identifiers/list/bundleId
   - Tìm kiếm: `com.hskvocab.chuyennghiep`
   - Nếu đã tồn tại, bạn có 2 lựa chọn:
     - **Option 1:** Xóa Bundle ID cũ (nếu chưa được sử dụng)
     - **Option 2:** Tạo Bundle ID mới hoàn toàn

### Bước 3: Giải Pháp

#### Giải Pháp 1: Xóa App Cũ Trong App Store Connect (Nếu có)

1. Vào App Store Connect → My Apps
2. Tìm app có tên hoặc Bundle ID trùng
3. Nếu app chưa được submit lên App Store, bạn có thể xóa nó
4. **Lưu ý:** Nếu app đã được submit, không thể xóa, chỉ có thể "Remove from Sale"

#### Giải Pháp 2: Tạo Bundle ID Mới Hoàn Toàn

Nếu Bundle ID đã được sử dụng, tạo Bundle ID mới:

1. **Tạo Bundle ID mới trong Apple Developer Portal:**
   - Vào: https://developer.apple.com/account/resources/identifiers/add/bundleId
   - Tạo Bundle ID mới: `com.hskvocab.professional` hoặc `com.hskvocab.master`
   - Description: "HSK Vocabulary Learning App"

2. **Cập nhật trong Xcode:**
   - Mở `ios/Runner.xcworkspace`
   - Vào Target → General → Bundle Identifier
   - Đổi thành Bundle ID mới

3. **Cập nhật trong project:**
   - Cập nhật `ios/Runner.xcodeproj/project.pbxproj`
   - Cập nhật tất cả references

#### Giải Pháp 3: Đổi Tên App Hoàn Toàn Mới

Tạo tên app mới, độc đáo hơn:

**Gợi ý tên mới:**
- "Học Từ Vựng HSK Chuyên Nghiệp 2025"
- "Từ Vựng HSK - Ứng Dụng Học Tiếng Trung"
- "HSK Vocabulary Master - Tiếng Trung"
- "Học Từ Vựng HSK Pro - Tiếng Trung"
- "Từ Vựng Tiếng Trung HSK Chuyên Nghiệp"

**Lưu ý:** Tên app phải:
- Không trùng với bất kỳ app nào trong tài khoản của bạn
- Không quá giống với app khác trên App Store
- Trong giới hạn 30 ký tự

#### Giải Pháp 4: Sử Dụng SKU Mới

Khi tạo app mới trong App Store Connect:
- SKU phải là duy nhất trong tài khoản của bạn
- Gợi ý: `hsk-vocab-pro-2025` hoặc `hsk-vocab-master-001`

## 🔧 Checklist Trước Khi Tạo App Mới

- [ ] Đã kiểm tra App Store Connect → My Apps (không có app trùng tên)
- [ ] Đã kiểm tra Apple Developer Portal → Bundle IDs (không có Bundle ID trùng)
- [ ] Đã search trên App Store (không có app trùng tên)
- [ ] Đã chuẩn bị SKU mới (chưa được sử dụng)
- [ ] Bundle ID trong Xcode khớp với Bundle ID trong Apple Developer Portal
- [ ] Tên app trong Info.plist khớp với tên sẽ dùng trong App Store Connect

## 📝 Quy Trình Tạo App Mới Đúng Cách

### 1. Tạo Bundle ID Trước (Trong Apple Developer Portal)

1. Vào: https://developer.apple.com/account/resources/identifiers/add/bundleId
2. Chọn: **App IDs** → **App**
3. Description: "HSK Vocabulary Learning App"
4. Bundle ID: `com.hskvocab.professional` (hoặc tên khác)
5. Capabilities: Chọn các capabilities cần thiết
6. Click **Continue** → **Register**

### 2. Tạo App Trong App Store Connect

1. Vào: https://appstoreconnect.apple.com/apps
2. Click **+** → **New App**
3. Điền thông tin:
   - **Platform:** iOS
   - **Name:** Tên app mới (ví dụ: "Học Từ Vựng HSK Chuyên Nghiệp 2025")
   - **Primary Language:** Vietnamese
   - **Bundle ID:** Chọn Bundle ID vừa tạo
   - **SKU:** `hsk-vocab-pro-2025` (phải unique)
4. Click **Create**

### 3. Upload Archive Từ Xcode

1. Mở Xcode → Product → Archive
2. Chọn archive → **Distribute App**
3. Chọn **App Store Connect**
4. Chọn **Upload**
5. Chọn app vừa tạo trong App Store Connect

## ⚠️ Lưu Ý Quan Trọng

1. **Không thể đổi Bundle ID sau khi đã tạo app:**
   - Bundle ID là vĩnh viễn, không thể thay đổi
   - Nếu cần đổi, phải tạo app mới

2. **Tên app có thể đổi sau:**
   - Có thể đổi tên app trong App Store Connect
   - Nhưng phải đợi review lại

3. **Kiểm tra quyền tài khoản:**
   - Đảm bảo tài khoản có quyền "Admin" hoặc "App Manager"
   - Nếu không có quyền, sẽ không thể tạo app

## 🆘 Nếu Vẫn Bị Lỗi

1. **Kiểm tra lại tất cả apps trong tài khoản:**
   - Có thể có app ở trạng thái ẩn hoặc đã bị xóa nhưng vẫn còn trong hệ thống

2. **Liên hệ Apple Support:**
   - Nếu chắc chắn không có app trùng, liên hệ Apple Developer Support
   - Email: developer@apple.com

3. **Thử tạo app với tên và Bundle ID hoàn toàn khác:**
   - Tên: "HSK Vocab Pro 2025"
   - Bundle ID: `com.hskvocab.pro2025`

