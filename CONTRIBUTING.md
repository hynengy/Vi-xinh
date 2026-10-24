# 🤝 HƯỚNG DẪN ĐÓNG GÓP & QUY TẮC LÀM VIỆC NHÓM (GIT CONVENTION)

Nhằm đảm bảo quá trình làm việc nhóm 05 thành viên trên GitHub không bị xung đột (conflict) mã nguồn và dễ dàng theo dõi lịch sử commit, toàn bộ thành viên tuân thủ các quy tắc sau:

---

## 🌿 1. Quy Tắc Phân Nhánh (Git Branching Strategy)

- **`main` / `master`**: Nhánh ổn định cao nhất, chỉ merge khi tính năng đã hoàn thiện và được kiểm thử kỹ lưỡng.
- **`develop`**: Nhánh phát triển chung.
- **Nhánh tính năng (`feature/`)**: Mỗi thành viên khi làm nhiệm vụ của mình sẽ tạo branch riêng từ `develop`:
  - `feature/llm-prompt-pipeline`
  - `feature/diu-database-splitbill` (Lê Thị Dịu)
  - `feature/quan-regex-extractor` (Lê Tiến Quân)
  - `feature/duy-ui-dashboard` (Lê Ngọc Duy)
  - `feature/vietanh-backend-integration` (Nguyễn Việt Anh)
- **Nhánh sửa lỗi (`bugfix/`)**: `bugfix/fix-receipt-date-parsing`

---

## 💬 2. Chuẩn Thông Điệp Commit (Conventional Commits)

Định dạng commit:
```
<loại>: <mô tả ngắn gọn bằng tiếng Việt hoặc tiếng Anh>
```

### Các tiền tố:
- `feat:` Thêm tính năng mới (Ví dụ: `feat: tích hợp module ocr với easyocr`)
- `fix:` Sửa lỗi (Ví dụ: `fix: sửa lỗi regex bóc tách tổng tiền có dấu chấm thập phân`)
- `docs:` Cập nhật tài liệu (Ví dụ: `docs: bổ sung sơ đồ CSDL ví nhóm`)
- `style:` Chỉnh sửa giao diện, CSS, format code không đổi logic
- `refactor:` Tái cấu trúc mã nguồn, tối ưu hiệu năng
- `test:` Thêm hoặc cập nhật unit test, test case hóa đơn

---

## 🔄 3. Quy Trình Đẩy Code & Pull Request (PR)

1. Cập nhật nhánh nhánh chính trước khi code:
   ```bash
   git checkout develop
   git pull origin develop
   ```
2. Tạo nhánh riêng và làm việc:
   ```bash
   git checkout -b feature/ten-tinh-nang
   ```
3. Commit và push lên GitHub:
   ```bash
   git add .
   git commit -m "feat: mo ta cong viec vua lam"
   git push origin feature/ten-tinh-nang
   ```
4. Tạo **Pull Request (PR)** trên GitHub vào nhánh `develop`, gắn tag người hỗ trợ kỹ thuật (Nguyễn Việt Anh) hoặc nhóm trưởng để review code trước khi gộp (merge).
