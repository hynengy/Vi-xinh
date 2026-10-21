# 📋 BẢN PHÂN CÔNG NHIỆM VỤ NHÓM 05

* **Đề tài:** Ứng dụng quản lý tài chính "Ví Xinh" sử dụng thị giác máy tính và OCR
* **Lớp:** 23CN1 — **Nhóm:** 05

---

## 1. Lộ Trình 2 Giai Đoạn (Milestones)

| Giai Đoạn | Nền Tảng | Mục Tiêu Chính | Công Nghệ Chủ Đạo | Trạng Thái |
|:---|:---|:---|:---|:---:|
| **Giai đoạn 1** | **Web Demo (MVP)** | Kiểm chứng pipeline OCR, trích xuất dữ liệu hóa đơn, CSDL và logic chia tiền ví nhóm. | Python (Flask), OpenCV, Tesseract, SQLite, HTML5/CSS/JS. |  **Hoàn thành** |
| **Giai đoạn 2** | **Mobile App** | Đóng gói ứng dụng di động hoàn chỉnh, quét hóa đơn bằng camera on-device siêu tốc, bảo mật sinh trắc học. | Flutter 3.x, Google ML Kit Text Recognition, `sqflite`, Provider. |  **Hoàn thành** |

---

## 2. Chi Tiết Nhiệm Vụ Từng Thành Viên

### 👤 Thành viên 1: Nguyễn Thúy Hiền
* **Vai trò:** OCR & Thị Giác Máy Tính (Computer Vision)
* **Nhiệm vụ Giai đoạn 1 (Web):** Thiết lập môi trường OCR (Tesseract/OpenCV), xây dựng tiền xử lý ảnh (Deskew, khử bóng, Adaptive Thresholding) tại `backend/ocr/`.
* **Nhiệm vụ Giai đoạn 2 (Mobile):** Tích hợp Google ML Kit Text Recognition chạy On-Device trên Flutter (`services/mlkit_ocr_service.dart`), tối ưu hóa camera scanner thời gian thực.

### 👤 Thành viên 2: Lê Thị Dịu
* **Vai trò:** Cơ Sở Dữ Liệu & Quản Lý Ví Nhóm
* **Nhiệm vụ Giai đoạn 1 (Web):** Thiết kế ERD CSDL SQLite, xây dựng bảng và logic chia tiền ví nhóm (`backend/database/`).
* **Nhiệm vụ Giai đoạn 2 (Mobile):** Cài đặt `sqflite` local database trên di động (`services/database_helper.dart`), quản lý công nợ phòng trọ, đồng bộ quỹ nhóm.

### 👤 Thành viên 3: Lê Tiến Quân
* **Vai trò:** Trích Xuất Dữ Liệu & NLP Regex
* **Nhiệm vụ Giai đoạn 1 (Web):** Xây dựng bộ quy tắc biểu thức chính quy (Regex) bóc tách Tên cửa hàng, Ngày giờ, Tổng tiền từ văn bản thô OCR (`backend/extractor/`).
* **Nhiệm vụ Giai đoạn 2 (Mobile):** Porting và tối ưu hóa bộ lọc Regex sang ngôn ngữ Dart (`extractor/dart_receipt_extractor.dart`), xử lý ngoại lệ hóa đơn mờ hoặc chụp nghiêng.

### 👤 Thành viên 4: Lê Ngọc Duy
* **Vai trò:** Thiết Kế & Lập Trình Giao Diện (UI/UX)
* **Nhiệm vụ Giai đoạn 1 (Web):** Thiết kế giao diện Web Dashboard, Màn hình xác thực & review kết quả OCR, biểu đồ tài chính.
* **Nhiệm vụ Giai đoạn 2 (Mobile):** Lập trình toàn bộ giao diện Flutter theo chuẩn Siêu ứng dụng (Dark / Rose Gold UI), màn hình Camera Scanner và Ví Nhóm.

### 👤 Thành viên 5: Nguyễn Việt Anh
* **Vai trò:** Kỹ Thuật Hệ Thống & Tích Hợp Đa Nền Tảng
* **Nhiệm vụ Giai đoạn 1 (Web):** Kết nối API Backend giữa OCR, Extractor, CSDL và Frontend Web; tối ưu hiệu năng và bảo mật.
* **Nhiệm vụ Giai đoạn 2 (Mobile):** Quản lý cấu hình dependencies (`pubspec.yaml`), cấu hình Gradle/iOS, quản lý build APK và CI/CD.

---

## 3. Trách Nhiệm Chung Toàn Nhóm
1. **Dữ liệu kiểm thử:** Cùng thu thập tập ảnh hóa đơn thực tế (rõ nét, mờ, góc nghiêng) vào `data/sample_receipts/`.
2. **Kiểm thử hệ thống:** Đo đạc độ chính xác bóc tách, thời gian xử lý và kiểm thử trải nghiệm trên các thiết bị.
3. **Báo cáo & Thuyết trình:** Đóng góp nội dung báo cáo tổng kết, hoàn thiện slide trình chiếu đồ án.
