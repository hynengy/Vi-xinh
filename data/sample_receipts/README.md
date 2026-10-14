# 📸 BỘ DỮ LIỆU HÓA ĐƠN MẪU (TEST CASES)

> Phụ trách: **Toàn bộ 05 thành viên nhóm cùng thu thập và đóng góp.**

## 1. Yêu cầu tập dữ liệu kiểm thử
Để đánh giá toàn diện độ chính xác của Pipeline OCR và Regex qua cả 2 giai đoạn, nhóm cần thu thập tối thiểu 20-30 ảnh hóa đơn thực tế theo các phân loại sau:

1. **Nhóm A: Hóa đơn chuẩn (Rõ nét, thẳng góc)**
   - Hóa đơn siêu thị (WinMart, Co.opmart), cửa hàng tiện lợi (Circle K, 7-Eleven).
   - In rõ nét, không bị nhăn, ánh sáng đều.
2. **Nhóm B: Hóa đơn mờ / Mất nét**
   - Hóa đơn in nhiệt lâu ngày, chữ bị mờ, nét đứt đoạn.
3. **Nhóm C: Hóa đơn góc nghiêng / Ánh sáng phức tạp**
   - Chụp góc xiên, bị đổ bóng, nền có hoa văn phức tạp.

## 2. Quy ước đặt tên file ảnh
```
receipt_<loại>_<số_thứ_tự>_<tên_quán>.jpg
```
Ví dụ:
- `receipt_clear_01_circle_k.jpg`
- `receipt_faded_02_highlands.jpg`
- `receipt_skewed_03_winmart.jpg`

## 3. Bảng Ground Truth (Đối soát kết quả)
Các thành viên khi thêm ảnh cần ghi lại thông tin thực tế vào file `ground_truth.json` để chạy bài test tự động tính toán tỷ lệ nhận diện chính xác (Accuracy / F1-Score).
