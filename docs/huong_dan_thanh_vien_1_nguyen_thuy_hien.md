# 📖 HƯỚNG DẪN THỰC HIỆN NHIỆM VỤ: THÀNH VIÊN 1 - NGUYỄN THÚY HIỀN

> **Vai trò:** Phụ trách Tích hợp Model OCR & Luồng Xử Lý Ảnh (Qua 2 Giai đoạn)  
> **Thư mục làm việc chính:** [phase-1-web-demo/backend/ocr/](file:///c:/Users/Lenovo/Downloads/V%C3%AD%20Xinh/phase-1-web-demo/backend/ocr)

---

## 🎯 1. Chi Tiết Nhiệm Vụ Được Giao

### 🔹 Giai đoạn 1 (Web Demo - MVP):
1. **Tiền xử lý ảnh (Computer Vision):**
   - Viết các thuật toán làm sạch ảnh hóa đơn trước khi đưa vào mô hình nhận diện:
     - Tự động xoay thẳng ảnh bị chụp nghiêng (**Deskew**).
     - Khử bóng đổ phức tạp (**Shadow Removal**) khi chụp bằng điện thoại dưới ánh đèn.
     - Tăng cường độ tương phản (**CLAHE**) đối với các hóa đơn in nhiệt lâu ngày bị mờ chữ.
     - Nhị phân hóa thích nghi (**Adaptive Thresholding**) tách chữ đen trên nền giấy trắng.
2. **Tích hợp Model OCR:**
   - Kết nối thư viện OCR (Tesseract / EasyOCR) để đọc chữ tiếng Việt và tiếng Anh.
   - Trích xuất: Văn bản thô (**raw text**), Tọa độ khung bao (**Bounding Boxes**), Điểm tin cậy (**Confidence Score**).
3. **Đo lường & Đánh giá hiệu năng:**
   - Đo thời gian xử lý ảnh (tính bằng milliseconds).
   - Đánh giá chất lượng đọc chữ trên các nhóm ảnh: Rõ nét, Mờ, Nghiêng.

### 🔹 Giai đoạn 2 (App Di Động Hoàn Chỉnh):
- Chuyển đổi từ Tesseract Web sang **Google ML Kit Text Recognition** chạy On-Device trên Flutter/Android.
- Xây dựng camera quét hóa đơn trực tiếp, tự động nhận diện thời gian thực.

---

## 💻 2. Cấu Trúc Code Đã Được Xây Dựng Cho Thúy Hiền

Toàn bộ code đã được chuẩn bị sẵn trong thư mục `backend/ocr/`:

1. `image_preprocessing.py`:
   - Lớp `ImagePreprocessor` chứa đầy đủ các thuật toán: `read_image`, `deskew`, `remove_shadows`, `enhance_contrast`, `adaptive_threshold`.
   - Có cờ `save_debug=True` để tự động xuất các ảnh trung gian từng bước, giúp Thúy Hiền lấy ảnh minh họa đưa vào Báo cáo/Slide thuyết trình!
2. `ocr_engine.py`:
   - Lớp `OCREngine` tự động nhận diện môi trường, hỗ trợ đọc text có dấu tiếng Việt (`vie+eng`), tính toán confidence score và đo thời gian xử lý.
3. `test_ocr_standalone.py`:
   - Script chạy độc lập, Thúy Hiền chỉ cần gõ lệnh dòng lệnh để test ngay bất kỳ ảnh nào mà không cần khởi động toàn bộ server web.

---

## 🚀 3. Hướng Dẫn Thúy Hiền Chạy Thử Nghiệm

### Bước 1: Cài đặt thư viện OCR trên máy tính
Chạy lệnh trong terminal:
```bash
pip install opencv-python pytesseract pillow numpy
```

*(Lưu ý về Tesseract OCR Engine trên Windows):*
- Tesseract cần file thực thi trên máy để nhận diện tiếng Việt.
- Tải bộ cài Tesseract Windows: [https://github.com/UB-Mannheim/tesseract/wiki](https://github.com/UB-Mannheim/tesseract/wiki)
- Khi cài đặt, ở mục **Additional script data** và **Additional language data**, nhớ tích chọn **Vietnamese**.

### Bước 2: Chạy thử nghiệm một ảnh hóa đơn bất kỳ
```bash
cd phase-1-web-demo
python -m backend.ocr.test_ocr_standalone "duong_dan_anh_hoa_don.jpg"
```
Kết quả sẽ in ra:
- Thời gian tiền xử lý ảnh (ms)
- Thời gian OCR nhận diện (ms)
- Toàn bộ nội dung văn bản thô đọc được
- Xuất file ảnh đã qua xử lý (`preprocessed_debug.jpg`) để kiểm tra chất lượng.

---

## 📝 4. Nội Dung Thúy Hiền Cần Viết Vào Báo Cáo Đồ Án

Khi viết Báo cáo và Slide thuyết trình, Thúy Hiền sẽ phụ trách phần:
1. **Chương Cơ sở lý thuyết:**
   - Trình bày về công nghệ Thị giác máy tính (Computer Vision) và OCR.
   - Giải thích phương pháp biến đổi Radon/MinAreaRect để xoay thẳng ảnh.
   - Giải thích phương pháp nhị phân hóa Otsu và cân bằng sáng CLAHE.
2. **Chương Thiết kế & Cài đặt hệ thống:**
   - Sơ đồ Pipeline xử lý ảnh từ ảnh gốc đến văn bản thô.
   - Hình ảnh so sánh trước và sau khi tiền xử lý (ảnh chụp bị bóng -> ảnh sau lọc trắng đen rõ nét).
3. **Chương Thực nghiệm & Đánh giá:**
   - Bảng đo thời gian xử lý trung bình (ví dụ: tiền xử lý mất ~80ms, OCR mất ~450ms).
   - Tỷ lệ nhận diện chữ thành công trên tập hóa đơn thử nghiệm.
