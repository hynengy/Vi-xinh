# 📱 GIAI ĐOẠN 2: ỨNG DỤNG DI ĐỘNG HOÀN CHỈNH "VÍ XINH" (MOBILE APP)

> Phụ trách: **Cả 5 thành viên chuyển đổi từ Web sang Mobile theo phân công chi tiết.**

---

## 🎯 1. Mục Tiêu Giai Đoạn 2
- Xây dựng ứng dụng di động chính thức hoạt động trên Android & iOS (sử dụng **Flutter**).
- Thay thế thư viện OCR trên Web bằng **Google ML Kit Text Recognition (On-Device)**:
  - Tốc độ nhận diện tức thì (< 500ms).
  - Không cần gửi ảnh lên server, đảm bảo tính bảo mật và hoạt động offline không cần internet.
- Chụp ảnh hóa đơn trực tiếp bằng camera trên điện thoại với khung định vị thông minh (bounding guide).

---

## 👥 2. Phân Công Thành Viên Trong Giai Đoạn 2

| Thành Viên | Trách Nhiệm Giai Đoạn 2 |
|:---|:---|
| **Nguyễn Thúy Hiền** | Tích hợp thư viện `google_mlkit_text_recognition`, xây dựng module Camera Scan trên Flutter. |
| **Lê Thị Dịu** | Thiết kế CSDL local trên di động (SQLite / Isar / Hive), xử lý đồng bộ dữ liệu ví nhóm khi có mạng. |
| **Lê Tiến Quân** | Porting và tối ưu bộ thuật toán bóc tách Regex sang Dart, xử lý ngoại lệ hóa đơn chụp vội/nghiêng/mờ. |
| **Lê Ngọc Duy** | Thiết kế giao diện Mobile chuẩn UI/UX Material 3 / iOS Cuppertino, các animation chuyển cảnh mượt mà. |
| **Nguyễn Việt Anh** | Cấu hình build Android APK / iOS IPA, xử lý xung đột dependencies native code, test trên nhiều thiết bị thực. |

---

## 🛠️ 3. Các Package Flutter Dự Kiến Sử Dụng

```yaml
dependencies:
  flutter:
    sdk: flutter

  # 1. Camera & OCR (Thúy Hiền)
  camera: ^0.10.5+9
  google_mlkit_text_recognition: ^0.11.0
  image_picker: ^1.0.7

  # 2. Local Database & Sync (Thị Dịu)
  sqflite: ^2.3.2
  path: ^1.9.0

  # 3. State Management & Navigation (Việt Anh & Ngọc Duy)
  provider: ^6.1.2 # hoặc flutter_bloc
  intl: ^0.19.0
  fl_chart: ^0.66.0 # Vẽ biểu đồ chi tiêu
```

---

## 🚀 4. Lộ Trình Triển Khai
1. Khởi tạo dự án Flutter trong thư mục `mobile_src/`.
2. Tạo widget Camera Scanner tích hợp Google ML Kit.
3. Chuyển đổi bộ regex từ Python sang Dart.
4. Lắp ráp giao diện Dashboard, Review và Ví nhóm trên Mobile.
5. Kiểm thử thực tế trên các dòng máy Android và iPhone.
