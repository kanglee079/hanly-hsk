# Lịch Sử Thay Đổi Tên App

## Tên App Hiện Tại

**Tên hiển thị:** `Từ Vựng - Từ Điển HSK Chuyên Nghiệp XiKang`  
**Bundle ID:** `com.xikang.hskvocab`  
**Bundle Name:** `TuVungTuDienHSKXiKang`

## Lý Do Chọn Tên Này

1. **Tiếng Việt:** Phù hợp với người dùng Việt Nam
2. **Dài và đặc biệt:** 28 ký tự, ít khả năng trùng lặp
3. **Rõ ràng mục đích:** "Học Từ Vựng HSK Chuyên Nghiệp" thể hiện rõ chức năng
4. **Bundle ID độc đáo:** `chuyennghiep` (chuyên nghiệp) là từ tiếng Việt không dấu, độc đáo

## Lưu Ý Quan Trọng

### Về Lỗi "App Name Already Being Used"

Lỗi này xảy ra khi:
1. **Tên app đã tồn tại trong App Store Connect** (của bạn hoặc người khác)
2. **Tên app quá giống với app khác** (Apple có thể từ chối)
3. **Tên app vi phạm trademark** (thương hiệu đã đăng ký)

### Cách Tránh Lỗi

1. **Kiểm tra trước khi đặt tên:**
   - Search trên App Store với tên app
   - Kiểm tra App Store Connect xem tên đã được dùng chưa
   - Tránh các từ thông dụng như "HSK", "Vocabulary" đơn lẻ

2. **Chọn tên độc đáo:**
   - Kết hợp nhiều từ khóa
   - Thêm từ mô tả như "Chuyên Nghiệp", "Pro", "Master"
   - Sử dụng tiếng Việt để giảm khả năng trùng

3. **Bundle ID phải khác:**
   - Mỗi Bundle ID chỉ dùng được 1 lần
   - Nếu đã tạo app với Bundle ID cũ, phải xóa app cũ hoặc dùng Bundle ID mới

## Các File Đã Được Cập Nhật

### iOS
- `ios/Runner/Info.plist`
  - `CFBundleDisplayName`: "Học Từ Vựng HSK Chuyên Nghiệp"
  - `CFBundleName`: "HocTuVungHSKChuyenNghiep"
- `ios/Runner.xcodeproj/project.pbxproj`
  - `PRODUCT_BUNDLE_IDENTIFIER`: com.hskvocab.chuyennghiep

### Flutter
- `pubspec.yaml`: description
- `lib/app/core/config/app_config.dart`: appName
- `lib/app/core/constants/strings_vi.dart`: appName

### Documentation
- `README.md`: title
- `docs/TESTFLIGHT_SUBMISSION_GUIDE.md`: tất cả references

## Bước Tiếp Theo

1. **Trong App Store Connect:**
   - Tạo app mới với tên: "Học Từ Vựng HSK Chuyên Nghiệp"
   - Bundle ID: `com.hskvocab.chuyennghiep`
   - Nếu vẫn bị lỗi, thử thêm số hoặc ký tự đặc biệt vào cuối tên

2. **Trong Xcode:**
   - Kiểm tra Bundle Identifier: `com.hskvocab.chuyennghiep`
   - Clean Build Folder
   - Archive lại

3. **Nếu vẫn bị lỗi:**
   - Thử tên: "Học Từ Vựng HSK Chuyên Nghiệp 2025"
   - Hoặc: "Học Từ Vựng HSK - Chuyên Nghiệp"
   - Kiểm tra xem có app nào trong tài khoản của bạn đã dùng tên tương tự

