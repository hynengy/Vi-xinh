# 📋 BẢN PHÂN CÔNG NHIỆM VỤ CHI TIẾT CHO NHÓM 05 THÀNH VIÊN

* **Đề tài:** Xây dựng ứng dụng quản lý tài chính cá nhân và nhóm "Ví Xinh" sử dụng thị giác máy tính và công nghệ OCR.
* **Lớp:** 23CN1 — **Nhóm:** 05
* **Tên ứng dụng:** Ví Xinh

---

## 1. LỘ TRÌNH TRIỂN KHAI 2 GIAI ĐOẠN

### 1.1. Giai đoạn 1 (Web Demo - Xây dựng MVP)
- Phát triển ứng dụng trên nền tảng Web (sử dụng Python/Flask hoặc FastAPI + HTML/JS) giúp tích hợp nhanh mô hình OCR, kiểm thử thuật toán trích xuất dữ liệu, hoàn thiện cơ sở dữ liệu và giao diện quản lý tài chính cá nhân/nhóm.
- Phục vụ cho việc demo, báo cáo tiến độ và kiểm tra độ chính xác ban đầu của hệ thống.

### 1.2. Giai đoạn 2 (App Di động Hoàn chỉnh - Mobile App)
- Chuyển đổi và phát triển ứng dụng di động chính thức chạy trên Android/iOS (sử dụng Flutter hoặc Native) tích hợp trực tiếp Google ML Kit OCR chạy on-device.
- Hoàn thiện trải nghiệm người dùng tối ưu theo phong cách siêu ứng dụng (chụp ảnh hóa đơn trực tiếp bằng camera, giao diện mượt mà, thông báo thời gian thực).

---

## 2. PHÂN CÔNG NHIỆM VỤ CHI TIẾT TỪNG THÀNH VIÊN

### 👤 Thành viên 1: Nguyễn Thúy Hiền
* **Nhiệm vụ chính:** Phụ trách Tích hợp Model OCR & Luồng Xử lý Ảnh qua 2 giai đoạn.
* **Công việc cụ thể:**
  * **Giai đoạn 1:** Thiết lập môi trường, tích hợp thư viện OCR vào Web Demo; xây dựng chức năng tải ảnh hóa đơn lên web và gọi model nhận diện văn bản thô (raw text).
  * **Giai đoạn 2:** Chuyển đổi tích hợp Google ML Kit Text Recognition chạy on-device trên ứng dụng di động; tối ưu hóa luồng chụp ảnh trực tiếp từ camera.

### 👤 Thành viên 2: Lê Thị Dịu
* **Nhiệm vụ chính:** Phụ trách Cơ sở dữ liệu, Logic Ví Nhóm & Tính năng Chia Tiền.
* **Công việc cụ thể:**
  * **Giai đoạn 1:** Thiết kế cơ sở dữ liệu (SQLite/MongoDB) lưu trữ thông tin giao dịch cá nhân, danh mục chi tiêu và cấu trúc thành viên nhóm trên nền tảng web. Xây dựng logic nghiệp vụ chia tiền chung cho nhóm.
  * **Giai đoạn 2:** Đồng bộ cơ sở dữ liệu lên app di động, hoàn thiện các API/Local storage, đảm bảo tính ổn định và bảo mật dữ liệu cho người dùng.

### 👤 Thành viên 3: Lê Tiến Quân
* **Nhiệm vụ chính:** Phụ trách Xử lý Văn bản & Thuật toán Trích xuất Thông tin (Regex).
* **Công việc cụ thể:**
  * **Giai đoạn 1:** Phân tích các mẫu hóa đơn thực tế, xây dựng bộ Biểu thức chính quy (Regex) và thuật toán bóc tách chính xác các trường: Tổng tiền, Ngày giao dịch, Tên cửa hàng từ văn bản thô của OCR trên web.
  * **Giai đoạn 2:** Tối ưu hóa và tích hợp bộ lọc Regex vào mã nguồn di động, xử lý các trường hợp ngoại lệ (ảnh mờ, sai định dạng ngày/tiền).

### 👤 Thành viên 4: Lê Ngọc Duy
* **Nhiệm vụ chính:** Phụ trách Thiết kế & Lập trình Giao diện UI/UX (Web Demo & App Di động).
* **Công việc cụ thể:**
  * **Giai đoạn 1:** Thiết kế giao diện Web Demo "Ví Xinh" trực quan (Dashboard trang chủ, màn hình xác thực kết quả OCR để người dùng sửa tay, biểu đồ thống kê).
  * **Giai đoạn 2:** Chuyển đổi và phát triển giao diện sang ứng dụng di động (Flutter/App) theo chuẩn UI/UX hiện đại, mượt mà, trực quan.

### 👤 Thành viên 5: Nguyễn Việt Anh
* **Nhiệm vụ chính:** Phụ trách Hỗ trợ kỹ thuật hệ thống & Đồng chủ trì khâu Tích hợp.
* **Công việc cụ thể:**
  * **Giai đoạn 1:** Phối hợp cùng Thành viên 1 và 3 trong việc kết nối module OCR, kiểm tra luồng dữ liệu truyền nhận trên Web Demo.
  * **Giai đoạn 2:** Hỗ trợ cấu hình build ứng dụng di động, xử lý các lỗi xung đột thư viện giữa các nền tảng (Android/iOS).

---

## 3. PHẦN CÔNG VIỆC CHUNG CỦA TOÀN NHÓM (ĐÁNH GIÁ & KIỂM THỬ)
* **Đối tượng thực hiện:** Toàn bộ 05 thành viên cùng tham gia.
* **Nội dung công việc xuyên suốt:**
  1. **Xây dựng Test Cases:** Cùng nhau chuẩn bị tập dữ liệu ảnh hóa đơn thực tế (ảnh rõ, ảnh mờ, góc nghiêng) để kiểm thử qua cả 2 giai đoạn.
  2. **Kiểm thử hệ thống & Đo đạc hiệu năng:** Cả nhóm cùng chạy thử nghiệm Web Demo và App di động "Ví Xinh", đo lường độ chính xác bóc tách thông tin, tốc độ phản hồi và khắc phục lỗi.
  3. **Tổng hợp Báo cáo & Thuyết trình:** Cùng nhau đóng góp nội dung, hoàn thiện file báo cáo đồ án chi tiết, biên soạn slide và chuẩn bị nội dung bảo vệ trước hội đồng.
