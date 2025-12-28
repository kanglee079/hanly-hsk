# Hướng Dẫn Upload App Lên TestFlight và App Store

## 📋 Tổng Quan

Hướng dẫn này sẽ giúp bạn upload ứng dụng **Từ Vựng - Từ Điển HSK Chuyên Nghiệp XiKang** lên TestFlight và sau đó lên App Store một cách đầy đủ và tránh bị reject.

---

## ✅ Bước 1: Chuẩn Bị Tài Khoản Apple Developer

### 1.1. Kiểm tra tài khoản
- Đảm bảo bạn có **Apple Developer Account** (99$/năm)
- Đăng nhập vào [developer.apple.com](https://developer.apple.com)
- Kiểm tra trạng thái membership còn hiệu lực

### 1.2. Tạo App ID (nếu chưa có)
1. Vào [App Store Connect](https://appstoreconnect.apple.com)
2. Chọn **My Apps** → **+** → **New App**
3. Điền thông tin:
   - **Platform**: iOS
   - **Name**: Từ Vựng - Từ Điển HSK Chuyên Nghiệp XiKang
   - **Primary Language**: Vietnamese
   - **Bundle ID**: `com.xikang.hskvocab` (đã được cấu hình)
   - **SKU**: `hanly-hsk-001` (hoặc bất kỳ mã nào bạn muốn)

---

## ✅ Bước 2: Cấu Hình Xcode Project

### 2.1. Mở project trong Xcode
```bash
cd /Users/vuonghykhang/Documents/hanly-hsk
open ios/Runner.xcworkspace
```

**LƯU Ý**: Phải mở `.xcworkspace`, KHÔNG phải `.xcodeproj`

### 2.2. Kiểm tra Signing & Capabilities
1. Chọn **Runner** target trong Project Navigator
2. Vào tab **Signing & Capabilities**
3. Chọn **Automatically manage signing**
4. Chọn **Team** của bạn (Apple Developer Account)
5. Xác nhận **Bundle Identifier**: `com.xikang.hskvocab`

### 2.3. Kiểm tra Build Settings
1. Vào tab **Build Settings**
2. Tìm **iOS Deployment Target**: Đảm bảo là **13.0** hoặc cao hơn
3. Tìm **Version**: Đảm bảo là `1.0.0` (hoặc version bạn muốn)
4. Tìm **Build**: Đảm bảo là số (ví dụ: `1`)

### 2.4. Kiểm tra App Icon
1. Vào `Runner/Assets.xcassets/AppIcon.appiconset`
2. Đảm bảo tất cả các icon đã được generate (đã chạy script)
3. Icon 1024x1024 là **BẮT BUỘC** cho App Store

---

## ✅ Bước 3: Build Archive cho TestFlight

### 3.1. Clean build folder
Trong Xcode: **Product** → **Clean Build Folder** (Shift + Cmd + K)

### 3.2. Chọn Device
- Chọn **Any iOS Device (arm64)** trong device selector (không chọn simulator)

### 3.3. Tạo Archive
1. **Product** → **Archive**
2. Đợi quá trình build hoàn tất (có thể mất 5-10 phút)
3. Window **Organizer** sẽ tự động mở

### 3.4. Validate Archive (Tùy chọn nhưng khuyến nghị)
1. Trong Organizer, chọn archive vừa tạo
2. Click **Validate App**
3. Chọn **Automatically manage signing**
4. Click **Next** và đợi validation hoàn tất
5. Nếu có lỗi, sửa và archive lại

### 3.5. Distribute App
1. Trong Organizer, chọn archive
2. Click **Distribute App**
3. Chọn **App Store Connect**
4. Click **Next**
5. Chọn **Upload** (không phải Export)
6. Chọn **Automatically manage signing**
7. Click **Next** → **Upload**
8. Đợi upload hoàn tất (có thể mất 10-30 phút tùy kích thước app)

---

## ✅ Bước 4: Cấu Hình App Store Connect

### 4.1. Điền Thông Tin App (App Information)
1. Vào [App Store Connect](https://appstoreconnect.apple.com)
2. Chọn app của bạn
3. Vào tab **App Information**
4. Điền đầy đủ:
   - **Category**: Education (hoặc phù hợp)
   - **Subcategory**: (tùy chọn)
   - **Privacy Policy URL**: (BẮT BUỘC - cần có URL)

### 4.2. Pricing and Availability
1. Vào tab **Pricing and Availability**
2. Chọn **Price**: Free (hoặc giá bạn muốn)
3. Chọn **Availability**: Tất cả các quốc gia (hoặc chọn cụ thể)

### 4.3. Prepare for Submission - Version Information

#### 4.3.1. Screenshots (BẮT BUỘC)
Cần screenshots cho các kích thước:
- **iPhone 6.7" Display** (iPhone 14 Pro Max): 1290 x 2796 pixels
- **iPhone 6.5" Display** (iPhone 11 Pro Max): 1242 x 2688 pixels
- **iPhone 5.5" Display** (iPhone 8 Plus): 1242 x 2208 pixels
- **iPad Pro (12.9-inch)** (3rd generation): 2048 x 2732 pixels

**Tối thiểu**: Cần ít nhất 1 bộ screenshots cho 1 kích thước màn hình

#### 4.3.2. App Preview (Tùy chọn nhưng khuyến nghị)
Video giới thiệu app (tối đa 30 giây)

#### 4.3.3. Description
- **Name**: Từ Vựng - Từ Điển HSK Chuyên Nghiệp XiKang (Lưu ý: Tên này dài hơn 30 ký tự, App Store có thể yêu cầu rút ngắn)
- **Subtitle**: (tùy chọn, tối đa 30 ký tự)
- **Description**: Mô tả chi tiết về app (tối đa 4000 ký tự)
- **Keywords**: Từ khóa tìm kiếm (tối đa 100 ký tự, phân cách bằng dấu phẩy)
- **Promotional Text**: (tùy chọn, tối đa 170 ký tự)
- **Support URL**: URL hỗ trợ (BẮT BUỘC)
- **Marketing URL**: (tùy chọn)

#### 4.3.4. Version Information
- **Version**: 1.0.0 (phải khớp với pubspec.yaml)
- **Copyright**: © 2025 HanLy (hoặc tên công ty của bạn)

#### 4.3.5. App Review Information
- **Contact Information**: Email và số điện thoại
- **Demo Account**: (nếu app cần đăng nhập)
- **Notes**: Ghi chú cho reviewer (nếu cần)

#### 4.3.6. Version Release
- **Automatically release this version**: Chọn nếu muốn tự động release
- **Manually release this version**: Chọn nếu muốn release thủ công

---

## ✅ Bước 5: Submit cho TestFlight

### 5.1. Chờ Build Processing
1. Sau khi upload archive, vào tab **TestFlight**
2. Build sẽ ở trạng thái **Processing** (có thể mất 10-30 phút)
3. Khi xong, build sẽ chuyển sang **Ready to Submit**

### 5.2. Export Compliance
Apple sẽ hỏi về Export Compliance:
- **Does your app use encryption?**: Chọn **No** (vì đã set `ITSAppUsesNonExemptEncryption = false` trong Info.plist)
- Nếu chọn **Yes**, cần điền thêm thông tin

### 5.3. Add Test Information (Beta App Review)
1. Vào tab **TestFlight** → **Test Information**
2. Điền:
   - **Beta App Description**: Mô tả ngắn về app
   - **Feedback Email**: Email nhận feedback
   - **Marketing URL**: (tùy chọn)
   - **Privacy Policy URL**: (BẮT BUỘC)

### 5.4. Add Internal Testers (Tùy chọn)
1. Vào **Users and Access** trong App Store Connect
2. Thêm email của bạn hoặc team members
3. Vào **TestFlight** → **Internal Testing**
4. Chọn build và thêm testers

### 5.5. Submit for Review
1. Vào tab **TestFlight**
2. Chọn build **Ready to Submit**
3. Click **Submit for Review**
4. Điền thông tin Export Compliance (nếu chưa điền)
5. Click **Submit**

---

## ✅ Bước 6: Chờ Review và Test

### 6.1. Trạng thái Review
- **Waiting for Review**: Đang chờ Apple review
- **In Review**: Apple đang review (thường 24-48 giờ)
- **Ready to Test**: Đã được approve, có thể test
- **Rejected**: Bị reject, cần sửa và submit lại

### 6.2. Test trên TestFlight
1. Tải app **TestFlight** từ App Store (nếu chưa có)
2. Mở email invitation từ Apple
3. Hoặc vào link: `https://testflight.apple.com/join/[CODE]`
4. Install và test app

---

## ✅ Bước 7: Submit cho App Store (Sau khi TestFlight OK)

### 7.1. Chuyển từ TestFlight sang App Store
1. Vào tab **App Store** trong App Store Connect
2. Đảm bảo tất cả thông tin đã điền đầy đủ (Bước 4)
3. Click **Submit for Review**

### 7.2. Chờ Review
- Thời gian review: 24-48 giờ (thường)
- Có thể bị reject nếu thiếu thông tin hoặc vi phạm guidelines

---

## ⚠️ Các Lỗi Thường Gặp và Cách Sửa

### Lỗi 1: Missing Compliance
**Lỗi**: "Missing Export Compliance Information"
**Giải pháp**: Đảm bảo `ITSAppUsesNonExemptEncryption = false` trong Info.plist

### Lỗi 2: Missing Privacy Policy
**Lỗi**: "Missing Privacy Policy URL"
**Giải pháp**: Thêm Privacy Policy URL trong App Store Connect

### Lỗi 3: Invalid Bundle Identifier
**Lỗi**: "Bundle identifier không khớp"
**Giải pháp**: Kiểm tra Bundle ID trong Xcode và App Store Connect phải giống nhau

### Lỗi 4: Missing App Icon
**Lỗi**: "Missing 1024x1024 icon"
**Giải pháp**: Đảm bảo icon 1024x1024 đã được generate và đặt đúng vị trí

### Lỗi 5: Missing Screenshots
**Lỗi**: "Missing screenshots"
**Giải pháp**: Upload ít nhất 1 bộ screenshots cho 1 kích thước màn hình

### Lỗi 6: Missing Usage Descriptions
**Lỗi**: "Missing usage description for [permission]"
**Giải pháp**: Đảm bảo tất cả permissions đã có description trong Info.plist

---

## 📝 Checklist Trước Khi Submit

- [ ] App icon 1024x1024 đã được tạo và đặt đúng
- [ ] Tất cả icon sizes đã được generate
- [ ] Info.plist có đầy đủ usage descriptions
- [ ] Bundle ID khớp giữa Xcode và App Store Connect
- [ ] Version và Build number đã được set đúng
- [ ] Archive build thành công không có lỗi
- [ ] Privacy Policy URL đã được thêm
- [ ] Support URL đã được thêm
- [ ] Screenshots đã được upload (ít nhất 1 bộ)
- [ ] App description đã được điền
- [ ] Keywords đã được điền
- [ ] Export Compliance đã được khai báo
- [ ] Test Information đã được điền trong TestFlight

---

## 🔗 Links Hữu Ích

- [App Store Connect](https://appstoreconnect.apple.com)
- [Apple Developer](https://developer.apple.com)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [TestFlight Documentation](https://developer.apple.com/testflight/)

---

## 📞 Hỗ Trợ

Nếu gặp vấn đề, kiểm tra:
1. [Apple Developer Forums](https://developer.apple.com/forums/)
2. [Stack Overflow](https://stackoverflow.com/questions/tagged/app-store-connect)
3. Email support: support@apple.com

---

**Chúc bạn thành công! 🚀**

