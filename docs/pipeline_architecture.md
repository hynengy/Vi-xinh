# KIẾN TRÚC PIPELINE XỬ LÝ KỸ THUẬT (HƯỚNG 3: LLM API)

Hệ thống trích xuất dữ liệu hóa đơn và quản trị chi tiêu **Ví Xinh** được xây dựng theo **Hướng 3: Ứng dụng mô hình ngôn ngữ lớn (LLM API)**, tập trung vào 3 trọng tâm kỹ thuật: **Thiết kế lời nhắc (Prompt Engineering)**, **Kiểm soát định dạng đầu ra (JSON Schema)**, và **Quản lý Chi phí & Độ trễ (Cost & Latency Management)**.

---

## Sơ Đồ Tuần Tự (Sequence Diagram)

```mermaid
sequenceDiagram
    autonumber
    actor User as Người dùng
    participant UI as Giao diện (Web / Flutter)
    participant Opt as Bộ Tối Ưu Hóa (Preprocess & Compress)
    participant LLM as Gemini Multimodal LLM API
    participant Val as JSON Schema Validator
    participant DB as CSDL SQLite

    User->>UI: 1. Tải ảnh hoặc Chụp ảnh hóa đơn
    UI->>Opt: Gửi ảnh gốc
    Opt->>Opt: Resize (max 1024px) & Nén JPEG (giảm latency)
    Opt->>LLM: Gửi ảnh đã nén + System Prompt & JSON Schema
    Note over LLM: Model: Gemini 1.5 Flash<br/>Suy luận ngữ nghĩa & Bóc tách cấu trúc
    LLM-->>Opt: Trả về JSON + Token Usage (Prompt & Output tokens)
    Opt->>Val: Kiểm tra tính hợp lệ của JSON Schema
    Val->>Val: Validate trường dữ liệu & kiểm tra logic (SL × ĐG = TT)
    Val->>UI: 2. Dữ liệu chuẩn hóa + Chỉ số Latency (ms) & Chi phí ($/VNĐ)
    UI->>User: Hiển thị Màn hình Review (Xác thực tương tác)
    User->>UI: Xác nhận lưu vào ví
    UI->>DB: 3. Ghi nhận giao dịch vào CSDL SQLite / Chia tiền nhóm
```

---

## Chi Tiết 5 Thành Phần Kỹ Thuật Trọng Tâm

### 1. Thu Nhận & Tối Ưu Hóa Dữ Liệu Đầu Vào (Image Compression & Latency Reduction)
* **Mục tiêu:** Giảm thiểu độ trễ mạng và tiết kiệm chi phí băng thông khi truyền ảnh lên Cloud LLM API.
* **Kỹ thuật:**
  * Giảm độ phân giải ảnh về mức tối ưu (chiều dài tối đa 1024px) - vừa đủ rõ nét để LLM đọc chữ nhỏ mà dung lượng file giảm từ ~5-8MB xuống chỉ còn ~150-250KB.
  * Tốc độ tải và phản hồi toàn trình (End-to-end latency) được rút ngắn xuống dưới 1.5 giây.

### 2. Thiết Kế Lời Nhắc (Prompt Engineering)
* **System Prompt:** Định hình vai trò chuyên gia phân tích dữ liệu hóa đơn tài chính Việt Nam.
* **Kỹ thuật Few-Shot & In-Context Learning:**
  * Hướng dẫn mô hình xử lý các trường hợp phức tạp: bảng sản phẩm có nhiều cột (Đơn vị tính, Số lượng, Đơn giá, Thành tiền).
  * Quy tắc bảo toàn số học: bắt buộc `Số lượng * Đơn giá = Thành tiền`.
  * Hóa đơn phòng trọ: tự động nhận diện tiền phòng, tiền điện, tiền nước theo chỉ số hoặc đơn giá/người.
  * Tự động gán danh mục tài chính phù hợp (`food`, `shopping`, `bills`, `transport`, `entertainment`, `other`).

### 3. Kiểm Soát Định Dạng Đầu Ra (Strict Structured JSON Output)
* Sử dụng tham số `response_mime_type="application/json"` để ép mô hình trả về chuỗi JSON thuần túy, tuyệt đối không chèn ký tự Markdown (` ```json `), lời chào hay văn bản tự do.
* Cấu trúc JSON Schema đầu ra:
  ```json
  {
    "merchant_name": "Tên cửa hàng / Đơn vị",
    "transaction_date": "YYYY-MM-DD",
    "transaction_time": "HH:MM",
    "total_amount": 0,
    "subtotal": 0,
    "discount": 0,
    "vat": 0,
    "category": "food",
    "payment_method": "Tiền mặt / Chuyển khoản",
    "items": [
      {
        "name": "Tên món / sản phẩm",
        "quantity": 1.0,
        "unit_price": 0,
        "amount": 0,
        "unit": "Kg / Đĩa / Lon"
      }
    ]
  }
  ```
* Tầng Validator tại Backend thực hiện đối soát lại kiểu dữ liệu trước khi đẩy vào hệ thống.

### 4. Quản Lý Chi Phí & Độ Trễ (Cost & Latency Tracking)
* **Lựa chọn Model:** Dùng `gemini-1.5-flash` / `gemini-flash-latest` (đáp ứng tiêu chí phản hồi nhanh, chi phí siêu rẻ).
* **Đo lường thời gian thực:**
  * `Latency (ms)`: Đo thời gian từ lúc gửi ảnh đến khi nhận phản hồi hoàn chỉnh.
  * `Token Usage`: Trích xuất số lượng `promptTokenCount` và `candidatesTokenCount` từ API `usageMetadata`.
  * `Cost Estimation`: Tính toán chi phí ước tính theo bảng giá Google Cloud/Gemini API ($0.075 / 1M prompt tokens và $0.30 / 1M output tokens), quy đổi sang VNĐ để hiển thị minh bạch.

### 5. AI Tóm Tắt & Đề Xuất Hành Động Tài Chính (Spending Summary & Advisor)
* Khai thác năng lực tổng hợp và lý giải của LLM trên dữ liệu lịch sử chi tiêu.
* Đọc dữ liệu chi tiêu trong tháng từ CSDL SQLite $\rightarrow$ Tổng hợp cơ cấu $\rightarrow$ LLM tóm tắt 3 điểm cốt lõi và đề xuất 3 hành động cụ thể giúp cá nhân/nhóm tiết kiệm chi tiêu hiệu quả.
