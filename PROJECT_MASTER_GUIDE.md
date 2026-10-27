# 📖 CẨM NANG TOÀN DIỆN DỰ ÁN "VÍ XINH" (PROJECT MASTER GUIDE)

> **Dành cho:** Báo cáo tiến độ, viết báo cáo đồ án, giải thích mã nguồn và chuẩn bị vấn đáp bảo vệ đồ án.  
> **Tên đồ án:** Ứng Dụng Quản Lý Tài Chính & Trích Xuất Dữ Liệu Hóa Đơn Bằng Mô Hình Ngôn Ngữ Lớn (LLM API)  
> **Định hướng đề tài:** **Hướng 3 — Ứng dụng Mô hình Ngôn ngữ lớn qua API (Gemini API)**  
> **Lớp:** 23CN1 — **Nhóm:** 05  
> **Phiên bản:** 2.0 (Hỗ trợ Cloud Database Neon PostgreSQL + Google AI Studio Gemini Flash Lite (`gemini-flash-lite-latest`) + Regex Fallback + 50/50 Tests Passed)

---

## MỤC LỤC
1. [TỔNG QUAN ĐỀ TÀI & Ý NGHĨA KHOA HỌC](#1-tổng-quan-đề-tài--ý-nghĩa-khoa-học)
2. [PHÂN CÔNG NHIỆM VỤ THÀNH VIÊN THEO CHUẨN HƯỚNG 3](#2-phân-công-nhiệm-vụ-thành-viên-theo-chuẩn-hướng-3)
3. [SƠ ĐỒ KIẾN TRÚC TỔNG THỂ HỆ THỐNG](#3-sơ-đồ-kiến-trúc-tổng-thể-hệ-thống)
4. [TỪ ĐIỂN TẤT CẢ CÁC FILE MÃ NGUỒN TRONG DỰ ÁN](#4-từ-điển-tất-cả-các-file-mã-nguồn-trong-dự-án)
5. [GIẢI THÍCH CHI TIẾT CÁC LUỒNG XỬ LÝ KỸ THUẬT CỐT LÕI](#5-giải-thích-chi-tiết-các-luồng-xử-lý-kỹ-thuật-cốt-lõi)
   - [5.1. Pipeline Bóc Tách Hóa Đơn Bằng Multimodal LLM & Regex Validator](#51-pipeline-bóc-tách-hóa-đơn-bằng-multimodal-llm--regex-validator)
   - [5.2. Giải Thuật Xử Lý Hóa Đơn Tiền Trọ Có 2 Phần Tổng Tiền Kép](#52-giải-thuật-xử-lý-hóa-đơn-tiền-trọ-có-2-phần-tổng-tiền-kép)
   - [5.3. Hệ Thống Đo Lường Chi Phí & Độ Trễ (Cost & Latency Management)](#53-hệ-thống-đo-lường-chi-phí--độ-trễ-cost--latency-management)
   - [5.4. Kiến Trúc Cơ Sở Dữ Liệu Lai (Cloud Neon PostgreSQL + SQLite Fallback)](#54-kiến-trúc-cơ-sở-dữ-liệu-lai-cloud-neon-postgresql--sqlite-fallback)
   - [5.5. Quản Lý Ngân Sách Cá Nhân & Hũ Tiết Kiệm Mục Tiêu](#55-quản-lý-ngân-sách-cá-nhân--hũ-tiết-kiệm-mục-tiêu)
   - [5.6. Xác Thực Tài Khoản & Gửi Mã OTP Qua Email (SMTP)](#56-xác-thực-tài-khoản--gửi-mã-otp-qua-email-smtp)
6. [HƯỚNG DẪN KHỞI CHẠY & KIỂM THỬ (AUTOMATED TESTING)](#6-hướng-dẫn-khởi-chạy--kiểm-thử-automated-testing)
7. [BỘ CÂU HỎI VẤN ĐÁP THƯỜNG GẶP KHI BẢO VỆ ĐỒ ÁN (FAQ DEFENSE)](#7-bộ-câu-hỏi-vấn-đáp-thường-gặp-khi-bảo-vệ-đồ-án-faq-defense)

---

## 1. TỔNG QUAN ĐỀ TÀI & Ý NGHĨA KHOA HỌC

### 1.1. Bối cảnh & Vấn đề
- Quản lý tài chính cá nhân là nhu cầu thiết yếu, nhưng việc nhập liệu thủ công từng khoản chi từ hóa đơn giấy (siêu thị, quán ăn, tiền trọ, điện nước) rất tốn thời gian, dễ sai sót và gây nản lòng cho người dùng.
- Các ứng dụng OCR truyền thống (Tesseract OCR thuần, Regex đơn giản) gặp khó khăn lớn trước hóa đơn Việt Nam: chữ in nhiệt bị mờ, giấy nhăn, bố cục bảng phức tạp, và đặc biệt là hóa đơn có tổng tiền kép (như tiền trọ gồm *tiền phòng* và *tiền dịch vụ* chuyển vào 2 tài khoản khác nhau).

### 1.2. Giải pháp của dự án "Ví Xinh"
- **Khai thác Mô hình Ngôn ngữ lớn đa phương thức (Multimodal LLM — Google AI Studio Gemini Flash Lite):** Đọc hiểu ngữ nghĩa hình ảnh hóa đơn trực tiếp bằng mô hình `gemini-flash-lite-latest`, tự động bóc tách cấu trúc JSON hoàn hảo gồm: Tên quán, ngày giờ, số tiền, chi tiết từng món hàng kèm số lượng & đơn giá, thuế VAT, tiền giảm giá.
- **Ràng buộc định dạng bằng JSON Schema (Structured Output):** Loại bỏ hoàn toàn lỗi sinh văn bản tự do (hallucination), đảm bảo 100% dữ liệu sẵn sàng lưu trữ vào CSDL.
- **Tối ưu Chi phí & Độ trễ:** Nén ảnh thích ứng để tiết kiệm Token tiêu thụ, giảm độ trễ API xuống dưới 2-3s, hiển thị số liệu minh bạch cho người dùng.
- **Bộ máy Regex Fallback Engine:** Chạy song song làm lớp thẩm định tính toàn vẹn số học ($Số lượng \times Đơn giá = Thành tiền$) và làm phương án dự phòng khi mất kết nối mạng hoặc hết quota API.

---

## 2. PHÂN CÔNG NHIỆM VỤ THÀNH VIÊN THEO CHUẨN HƯỚNG 3

| STT | Thành Viên | Module Phụ Trách | Nhiệm Vụ Kỹ Thuật Chi Tiết | File Mã Nguồn Đại Diện |
|:---:|:---|:---|:---|:---|
| 1 | **Nguyễn Thúy Hiền** | **Prompt Engineering & Model Evaluator** | Thiết kế System Prompt đóng vai chuyên gia tài chính; xây dựng tập luật trích xuất Few-shot rules; đánh giá chất lượng phản hồi của Gemini qua các kịch bản hóa đơn. | `backend/prompts/receipt_prompt.py` |
| 2 | **Lê Thị Dịu** | **Database & Financial Analytics** | Thiết kế CSDL quan hệ lưu trữ JSON hóa đơn; thuật toán quản lý ngân sách cá nhân, thống kê thu chi, chi phí định kỳ và đồng bộ giao dịch. | `backend/database/db_manager.py`<br>`backend/core/wallet_logic.py` |
| 3 | **Lê Tiến Quân** | **Structured Output & Schema Validation** | Xây dựng JSON Schema kiểm soát đầu ra; phát triển bộ lọc Regex Validator dự phòng (`ReceiptParser`), kiểm tra toàn vẹn số học và xử lý hóa đơn phức tạp (tiền trọ, VAT, giảm giá). | `backend/extractor/regex_parser.py`<br>`backend/extractor/rules.py` |
| 4 | **Lê Ngọc Duy** | **Giao Diện UI/UX (Web & Flutter)** | Thiết kế Dashboard tương tác, bảng Review 4 cột kiểm tra hóa đơn, bảng hiển thị chỉ số đo lường Latency (ms), Token Usage, Chi phí và AI tư vấn tài chính. | `frontend/index.html`<br>`review.html`<br>`phase-2-mobile-app/` |
| 5 | **Nguyễn Việt Anh** | **LLM Backend & Cost/Latency Optimization** | Tích hợp Google Gemini API; thuật toán nén ảnh giảm latency; đo token count / chi phí API; tích hợp AI Financial Advisor; quản trị CI/CD và triển khai Vercel. | `backend/llm/gemini_extractor.py`<br>`backend/llm/image_preprocessing.py`<br>`api/index.py` |

---

## 3. SƠ ĐỒ KIẾN TRÚC TỔNG THỂ HỆ THỐNG

```mermaid
graph TD
    Client[Người Dùng: Web PWA / Flutter Mobile] -->|1. Upload ảnh hóa đơn| API[API Gateway: FastAPI / Flask Serverless]
    
    subgraph LLM_Pipeline [Pipeline Bóc Tách Hướng 3]
        API -->|2. Nén & Tối ưu kích thước| Preproc[Image Preprocessing<br/>Giảm Token & Latency]
        Preproc -->|3. Gửi ảnh + Prompt| LLM[Google AI Studio Gemini Flash Lite API<br/>(gemini-flash-lite-latest)]
        Prompt[System Prompt & Strict JSON Schema] -.-> LLM
        LLM -->|4. Phản hồi JSON có cấu trúc| Validator[Schema Validator & Mathematical Checker]
        
        API -.->|Dự phòng khi lỗi mạng/LLM| Fallback[Regex Parser Engine<br/>receipt_parser.py]
        Fallback -.-> Validator
    end
    
    Validator -->|5. Trả dữ liệu hiển thị| ReviewUI[Bảng Kiểm Tra Hóa Đơn 4 Cột<br/>Hiển thị ms, Tokens, Chi phí VNĐ]
    ReviewUI -->|6. Người dùng xác nhận lưu| DBAdapter[Database Manager]
    
    subgraph Data_Storage [Hệ Thống Lưu Trữ Lai]
        DBAdapter -->|Môi trường Online| CloudDB[(Cloud Database: Neon PostgreSQL)]
        DBAdapter -.->|Môi trường Offline/Local| LocalDB[(Local SQLite Fallback)]
    end
    
    DBAdapter --> FinancialAI[AI Phân Tích & Cố Vấn Tiết Kiệm]
    DBAdapter --> BudgetManager[Quản Trị Ngân Sách & Hũ Tiết Kiệm]
```

---

## 4. TỪ ĐIỂN TẤT CẢ CÁC FILE MÃ NGUỒN TRONG DỰ ÁN

### 📁 Thư mục Gốc (Root)
- **`index.html`**: Giao diện ứng dụng chính trên nền Web (Dashboard tài chính, danh sách giao dịch, biểu đồ thu chi, modal quét hóa đơn, giao diện AI phân tích).
- **`review.html`**: Giao diện kiểm tra và chỉnh sửa dữ liệu hóa đơn sau khi quét (Review 4 cột: Tên món, Đơn vị, Số lượng, Đơn giá, Thành tiền) kèm bảng thông số Latency, Tokens và Chi phí.
- **`vercel.json`**: Tệp cấu hình triển khai Serverless trên hạ tầng Vercel Cloud (định tuyến `/api/(.*)` sang `api/index.py`).
- **`requirements.txt`**: Danh sách thư viện Python phụ thuộc (`google-genai`, `fastapi`, `uvicorn`, `psycopg2-binary`, `pillow`, `pytest`...).
- **`Procfile`**: Tệp chỉ dẫn khởi chạy ứng dụng khi deploy lên PaaS (Heroku/Render).
- **`manifest.webmanifest` & `service-worker.js`**: Cấu hình PWA (Progressive Web App) giúp ứng dụng có thể cài đặt như Native App trên điện thoại và chạy offline.

---

### 📁 Thư mục `phase-1-web-demo/backend/` (Trái Tim Backend)

#### 1. Module LLM & AI (`backend/llm/`)
- **[`gemini_extractor.py`](file:///c:/Users/Lenovo/Downloads/Ví%20Xinh/phase-1-web-demo/backend/llm/gemini_extractor.py)**:
  - Khởi tạo kết nối Gemini API Client bằng Google API Key.
  - Tích hợp System Prompt và JSON Schema vào request `generate_content`.
  - Đo thời gian xử lý thực tế ($\text{Latency} = t_{end} - t_{start}$ tính bằng mili-giây).
  - Đếm số lượng Token đầu vào (Prompt Tokens), Token đầu ra (Candidates Tokens) và quy đổi chi phí theo biểu giá chính thức của Google ($0.075 / 1M input tokens, $0.30 / 1M output tokens).
- **[`image_preprocessing.py`](file:///c:/Users/Lenovo/Downloads/Ví%20Xinh/phase-1-web-demo/backend/llm/image_preprocessing.py)**:
  - Tự động kiểm tra kích thước ảnh hóa đơn.
  - Nếu ảnh vượt quá ngưỡng (ví dụ > 1600px), thực hiện nén thích ứng (Adaptive Resizing) giữ nguyên tỷ lệ khung hình và tối ưu hóa JPEG chất lượng 85%.
  - Giảm dung lượng ảnh từ 5MB - 10MB xuống còn < 500KB $\rightarrow$ Giúp giảm số lượng Image Tokens gửi lên API từ 1000+ tokens xuống ~258 tokens $\rightarrow$ Tăng tốc độ phản hồi gấp 3 lần.

#### 2. Module Prompts & Schema (`backend/prompts/`)
- **[`receipt_prompt.py`](file:///c:/Users/Lenovo/Downloads/Ví%20Xinh/phase-1-web-demo/backend/prompts/receipt_prompt.py)**:
  - **`RECEIPT_EXTRACTION_SYSTEM_PROMPT`**: Định nghĩa vai trò chuyên gia bóc tách hóa đơn tài chính Việt Nam, thiết lập quy tắc số học bất biến ($SL \times Đơn giá = Thành tiền$), hướng dẫn bóc tách hóa đơn tiền trọ compound 2 phần (DV + Phòng).
  - **`RECEIPT_JSON_SCHEMA`**: Cấu trúc JSON Schema nghiêm ngặt (các trường bắt buộc: `merchant_name`, `total_amount`, `transaction_date`, `items`...).
  - **`FINANCIAL_ADVISOR_PROMPT`**: Lời nhắc chuyên biệt hướng dẫn AI đọc dữ liệu chi tiêu trong tháng, tìm ra 3 khoản chi lớn nhất, danh mục chi tiêu bất thường và đưa ra 3 lời khuyên tài chính cá nhân hóa.

#### 3. Module Bóc Tách & Thẩm Định Regex (`backend/extractor/`)
- **[`regex_parser.py`](file:///c:/Users/Lenovo/Downloads/Ví%20Xinh/phase-1-web-demo/backend/extractor/regex_parser.py)**:
  - Bộ máy bóc tách và chuẩn hóa dữ liệu tài chính toàn diện bằng biểu thức chính quy.
  - `clean_text`: Lọc bỏ đường kẻ phân cách, chuẩn hóa ký tự tiếng Việt.
  - `extract_merchant`: Nhận diện chuỗi cửa hàng, tên quán, phòng trọ.
  - `extract_totals_full`: Nhận diện tổng tiền kép (tiền trọ), tính toán thực chi (tiền khách đưa - tiền thối).
  - `extract_line_items`: Bóc tách chi tiết từng dòng mặt hàng, phân tách cột bảng `|`, ghép cặp 2 dòng, nhận diện dịch vụ phòng trọ và dịch vụ 0đ.
  - `_detect_item_icon`: Gắn icon emoji tương ứng theo danh mục món ăn/dịch vụ.
  - `parse_all`: Điều phối luồng và đối chiếu số học hai chiều.
- **[`rules.py`](file:///c:/Users/Lenovo/Downloads/Ví%20Xinh/phase-1-web-demo/backend/extractor/rules.py)**:
  - Tập hợp từ khóa Regex chuẩn hóa cho thị trường Việt Nam: Từ khóa khách phải trả (`DUE_AMOUNT_KEYWORDS`), tiền đã nhận (`PAID_AMOUNT_KEYWORDS`), tiền thối (`CHANGE_KEYWORDS`), giảm giá (`DISCOUNT_KEYWORDS`), thuế VAT (`VAT_KEYWORDS`), tiêu đề bảng (`TABLE_HEADER_KEYWORDS`), số hóa đơn...

#### 4. Module Cơ Sở Dữ Liệu (`backend/database/`)
- **[`db_manager.py`](file:///c:/Users/Lenovo/Downloads/Ví%20Xinh/phase-1-web-demo/backend/database/db_manager.py)**:
  - Kiến trúc Dual-Database Adapter: Tự động phát hiện biến môi trường `DATABASE_URL` để kết nối **Cloud PostgreSQL (Neon.tech / Supabase)** qua `psycopg2`.
  - Cơ chế **Zero-Downtime Fallback**: Nếu Cloud Database mất kết nối hoặc không có Internet, tự động chuyển về **SQLite cục bộ** (`data/app.db`), không bao giờ để ứng dụng bị crash.
  - Các hàm quản trị CSDL: Quản lý người dùng, giao dịch cá nhân, ngân sách chi tiêu, chi tiết từng món hàng trong hóa đơn.

#### 5. Module Dịch Vụ Cốt Lõi (`backend/core/`)
- **[`pipeline.py`](file:///c:/Users/Lenovo/Downloads/Ví%20Xinh/phase-1-web-demo/backend/core/pipeline.py)**:
  - Xâu chuỗi toàn bộ quy trình: Nhận ảnh $\rightarrow$ Nén ảnh $\rightarrow$ Gọi Multimodal LLM $\rightarrow$ Đối chiếu Regex Validator $\rightarrow$ Trả kết quả chuẩn hóa cho Frontend.
- **[`wallet_logic.py`](file:///c:/Users/Lenovo/Downloads/Ví%20Xinh/phase-1-web-demo/backend/core/wallet_logic.py)**:
  - Thuật toán quản lý thu chi, tính toán số dư và tổng hợp báo cáo chi tiêu cá nhân.
  - Phân tích hạn mức ngân sách và tính toán phần trăm hoàn thành theo từng danh mục.
- **[`email_service.py`](file:///c:/Users/Lenovo/Downloads/Ví%20Xinh/phase-1-web-demo/backend/core/email_service.py)**:
  - Tích hợp giao thức SMTP gửi email mã OTP xác thực 6 số khi người dùng đăng ký hoặc khôi phục mật khẩu.
  - Có chế độ Mock Fallback khi chưa cấu hình tài khoản Gmail.

---

### 📁 Thư mục `api/` & `run.py`
- **[`api/index.py`](file:///c:/Users/Lenovo/Downloads/Ví%20Xinh/api/index.py)**: Serverless Entry Point chạy trên Vercel. Chứa toàn bộ các RESTful API: `/api/ocr/upload`, `/api/transactions`, `/api/auth/register`, `/api/auth/login`, `/api/advisor/analyze`...
- **`run.py`**: Script chạy server cục bộ trên máy tính (chạy cổng `http://localhost:5000`).

---

### 📁 Thư mục `tests/` (Hệ Thống Kiểm Thử Tự Động)
- **[`test_database.py`](file:///c:/Users/Lenovo/Downloads/Ví%20Xinh/tests/test_database.py)**: 17 test cases kiểm tra CSDL (tạo người dùng, đăng nhập bảo mật, thêm/sửa/xóa giao dịch, thống kê ngân sách cá nhân).
- **[`test_email_service.py`](file:///c:/Users/Lenovo/Downloads/Ví%20Xinh/tests/test_email_service.py)**: 5 test cases kiểm tra dịch vụ gửi email OTP và fallback an toàn.
- **[`test_extractor.py`](file:///c:/Users/Lenovo/Downloads/Ví%20Xinh/tests/test_extractor.py)**: 22 test cases kiểm tra toàn diện bộ trích xuất hóa đơn: WinMart, Highlands Coffee, Hóa đơn nhà hàng VIP 50 triệu, KiotViet mờ nhăn.
- **[`test_wallet_logic.py`](file:///c:/Users/Lenovo/Downloads/Ví%20Xinh/tests/test_wallet_logic.py)**: 6 test cases kiểm tra thuật toán quản lý thu chi và ngân sách cá nhân.
- 👉 **Tổng cộng: 50/50 test cases đều đạt 100% PASSED.**

---

### 📁 Thư mục `phase-2-mobile-app/` (Ứng Dụng Flutter Mobile)
- **`lib/main.dart`**: Khởi chạy ứng dụng Flutter, thiết lập theme và Provider.
- **`lib/providers/`**: Quản lý trạng thái ứng dụng (`auth_provider.dart`, `transaction_provider.dart`).
- **`lib/screens/`**: Các màn hình trên điện thoại: Đăng nhập, Trang chủ Dashboard, Chụp ảnh quét hóa đơn, Quản lý ngân sách.
- **`lib/services/`**: Giao tiếp RESTful API với Backend serverless.

---

## 5. GIẢI THÍCH CHI TIẾT CÁC LUỒNG XỬ LÝ KỸ THUẬT CỐT LÕI

### 5.1. Pipeline Bóc Tách Hóa Đơn Bằng Multimodal LLM & Regex Validator
1. **Bước 1 (Client Upload):** Người dùng chụp ảnh hóa đơn từ Web hoặc Mobile gửi đến API `/api/ocr/upload`.
2. **Bước 2 (Image Preprocessing):** Backend kiểm tra kích thước. Nếu ảnh quá lớn, hàm `compress_and_resize_image` sẽ nén về độ phân giải tối ưu, chuyển về RGB.
3. **Bước 3 (Gemini Multimodal Inference):** Ảnh nén kèm `RECEIPT_EXTRACTION_SYSTEM_PROMPT` và `RECEIPT_JSON_SCHEMA` được gửi đến mô hình `gemini-flash-lite-latest` (hoặc `gemini-flash-latest`).
4. **Bước 4 (Structured Extraction & Cost Tracking):**
   - Gemini đọc trực tiếp văn bản từ ảnh và trả về JSON thuần chuẩn xác.
   - Hệ thống ghi nhận: $t_{latency} = t_1 - t_0$, đếm `prompt_token_count` và `candidates_token_count`, tính chi phí VNĐ.
5. **Bước 5 (Regex Cross-Validation & Fallback):**
   - Dữ liệu được đưa qua `ReceiptParser.parse_all` để thẩm định tính toàn vẹn: Kiểm tra từng dòng $SL \times Đơn giá = Thành tiền$, đối chiếu tổng tiền hóa đơn với tổng các món.
   - Nếu LLM gặp sự cố (mất mạng/hết quota), bộ máy Regex sẽ tự động bóc tách từ văn bản OCR thô làm phương án dự phòng.
6. **Bước 6 (Review UI):** Dữ liệu được trả về giao diện `review.html` dưới dạng bảng 4 cột để người dùng kiểm tra trước khi bấm "Lưu vào ví".

---

### 5.2. Giải Thuật Xử Lý Hóa Đơn Tiền Trọ Có 2 Phần Tổng Tiền Kép
* **Thực trạng bài toán:** Hóa đơn tiền trọ/chung cư thực tế tại Việt Nam thường có 2 phần riêng biệt:
  1. `TỔNG TIỀN DV` (Điện, nước, wifi, máy giặt, thang máy, để xe...) $\rightarrow$ Chuyển vào STK 1.
  2. `TỔNG TIỀN PHÒNG` (Tiền thuê phòng cố định) $\rightarrow$ Chuyển vào STK 2.
  - Không có dòng "Tổng cộng" in sẵn trên giấy.
* **Giải pháp thuật toán trong `regex_parser.py`:**
  - Hàm `extract_totals_full` quét và phát hiện cả `room_service_total` và `room_rent_total`.
  - Khi phát hiện có đủ 2 khoản, thuật toán **không lấy đơn lẻ** một khoản nào làm `due_payment`, mà tự động tính:
    $$\text{final\_total} = \text{room\_service\_total} + \text{room\_rent\_total}$$
    *(Ví dụ: $3.365.800 + 3.800.000 = 7.165.800\text{ đ}$)*
  - Trong phần breakdown, lưu rõ ràng:
    + *Tổng tiền dịch vụ:* `3.365.800 đ`
    + *Tổng tiền phòng:* `3.800.000 đ`
    + *Tổng thanh toán (Phòng + Dịch vụ):* `7.165.800 đ`
  - Trong `extract_line_items`: Hỗ trợ tham số `allow_zero=True` để nhận diện dịch vụ `Để xe | 0 đ` là dịch vụ miễn phí, không làm nuốt hoặc lệch giá của dòng `Thang máy 250.000 đ` kế tiếp. Tách riêng cột ghi chú số tài khoản bên phải.

---

### 5.3. Hệ Thống Đo Lường Chi Phí & Độ Trễ (Cost & Latency Management)
Theo đúng yêu cầu nghiên cứu của **Hướng 3**, ứng dụng không chỉ gọi API mà phải quản lý được tài nguyên:
- **Thời gian xử lý (Latency):** Đo bằng đồng hồ thời gian thực (`time.perf_counter()`), tính theo mili-giây (ms).
- **Token Usage:** Trích xuất từ đối tượng `response.usage_metadata`:
  - `prompt_token_count`: Số token của ảnh và prompt đầu vào.
  - `candidates_token_count`: Số token của JSON kết quả trả về.
- **Ước tính Chi Phí:**
  $$\text{Cost} (\$) = \left(\frac{\text{Prompt Tokens}}{1.000.000} \times 0.075\right) + \left(\frac{\text{Candidate Tokens}}{1.000.000} \times 0.30\right)$$
  $$\text{Cost (VNĐ)} = \text{Cost} (\$) \times 25.400$$
- Toàn bộ 3 chỉ số này được hiển thị nổi bật trên banner giao diện review hóa đơn.

---

### 5.4. Kiến Trúc Cơ Sở Dữ Liệu Lai (Cloud Neon PostgreSQL + SQLite Fallback)
* **Vấn đề của kiến trúc Serverless (Vercel):** Mỗi request là một môi trường không trạng thái (stateless/ephemeral container). Nếu dùng file SQLite cục bộ thì mỗi lần server khởi động lại, dữ liệu người dùng và giao dịch sẽ bị xóa sạch.
* **Giải pháp:**
  - Kết nối đến **Cloud Database PostgreSQL tập trung (Neon.tech)** qua chuỗi kết nối bảo mật SSL.
  - Mọi dữ liệu đăng ký tài khoản, thêm giao dịch từ Web hay Điện thoại đều được đồng bộ thời gian thực vào Cloud DB.
  - Bộ điều hợp `db_manager.py` tự động chuyển đổi giữa cú pháp SQLite (`?`, `AUTOINCREMENT`) và PostgreSQL (`%s`, `SERIAL`) một cách trong suốt.
  - Nếu mất mạng, hệ thống tự động lưu vào SQLite local tạm thời mà không báo lỗi sập ứng dụng.

---

### 5.5. Quản Lý Ngân Sách Cá Nhân & Hũ Tiết Kiệm Mục Tiêu
- Người dùng có thể thiết lập hạn mức chi tiêu cho từng danh mục riêng biệt (Ăn uống, Mua sắm, Di chuyển, Giải trí, Hóa đơn...).
- Cơ chế kiểm soát tự động:
  - Khi chi tiêu trong tháng vượt 80% hạn mức: Thanh tiến độ chuyển sang màu vàng cảnh báo.
  - Khi vượt 100%: Tự động kích hoạt cảnh báo nguy cấp (đỏ) trên bảng điều khiển Dashboard và gửi thông báo vào Trung tâm Thông báo.
  - Tích hợp tính năng tạo các Hũ Tiết Kiệm (Savings Goals) với tiến độ phần trăm trực quan, giúp người dùng theo đuổi các kế hoạch tài chính cá nhân dài hạn.

---

## 6. HƯỚNG DẪN KHỞI CHẠY & KIỂM THỬ (AUTOMATED TESTING)

### 6.1. Khởi chạy ứng dụng Web cục bộ
```bash
# 1. Kích hoạt môi trường ảo Python
cd "Ví Xinh"
# Windows:
.\phase-1-web-demo\venv\Scripts\activate

# 2. Chạy ứng dụng
python phase-1-web-demo/run.py
```
👉 Mở trình duyệt truy cập: `http://localhost:5000`

### 6.2. Chạy bộ kiểm thử tự động (Pytest)
```bash
pytest -v
```
👉 Kết quả chuẩn: **`50 passed in ~20s`** (100% xanh).

### 6.3. Triển khai lên Vercel
```bash
git add .
git commit -m "feat: deploy production"
git push origin main
```
👉 Hệ thống CI/CD của Vercel sẽ tự động build và cập nhật phiên bản mới nhất tại `https://vi-xinh.vercel.app`.

---

## 7. BỘ CÂU HỎI VẤN ĐÁP THƯỜNG GẶP KHI BẢO VỆ ĐỒ ÁN (FAQ DEFENSE)

### ❓ Câu 1: Tại sao nhóm chọn Gemini Flash Lite (`gemini-flash-lite-latest`) qua Google AI Studio mà không dùng GPT-4o hay Tesseract OCR truyền thống?
> **Trả lời:**
> 1. *So với Tesseract OCR truyền thống:* Tesseract chỉ nhận dạng chữ cái đơn thuần, không hiểu ngữ nghĩa, gặp hóa đơn nhàu nát hay hóa đơn tiền trọ phức tạp sẽ cho ra văn bản rác và phải viết hàng nghìn dòng regex chắp vá. Gemini là Multimodal LLM có khả năng hiểu bố cục không gian hình ảnh và ngữ nghĩa tiếng Việt cực tốt.
> 2. *So với GPT-4o và các model lớn khác:* Mô hình `gemini-flash-lite-latest` (Gemini Flash Lite thế hệ mới của Google AI Studio) có tốc độ xử lý nhanh hơn 2-3 lần (độ trễ chỉ ~1.5 - 2.5s), chi phí cực kỳ rẻ ($0.0375 - $0.075 / triệu token so với $2.5 - $5 của GPT-4o), rất phù hợp với bài toán thực tế của ứng dụng tài chính cần phản hồi nhanh và tiết kiệm chi phí vận hành.
> 3. *Về tên gọi kỹ thuật:* Google AI Studio đã chuẩn hóa endpoint thế hệ mới sang `gemini-flash-lite-latest` và `gemini-flash-latest` (thay vì alias cũ `gemini-1.5-flash` vốn trả về 404 trên API v1beta đối với các gói dự án mới). Hệ thống của nhóm tự động ưu tiên `gemini-flash-lite-latest` và tự động fallback tuần tự sang các model Flash khác nếu cần.

### ❓ Câu 2: Nhóm làm thế nào để đảm bảo LLM không bị "ảo giác" (Hallucination) và luôn trả về JSON chuẩn?
> **Trả lời:**
> Nhóm áp dụng kỹ thuật **Structured Outputs bằng JSON Schema**:
> - Khai báo một `RECEIPT_JSON_SCHEMA` định nghĩa rõ từng kiểu dữ liệu (`STRING`, `NUMBER`, `ARRAY`), các trường bắt buộc (`required`) và quy định $SL \times Đơn giá = Thành tiền$.
> - Thiết lập `response_mime_type="application/json"` và truyền schema trực tiếp vào cấu hình sinh của Gemini API. Mô hình bị cưỡng chế xuất ra JSON hợp lệ 100%, không sinh thêm văn bản chào hỏi hay ký tự markdown dư thừa.

### ❓ Câu 3: Làm thế nào ứng dụng hoạt động nếu mất kết nối mạng hoặc hết hạn mức API Gemini?
> **Trả lời:**
> Nhóm đã xây dựng cơ chế **Dual Engine Fallback**:
> - Pipeline có sẵn module `ReceiptParser` sử dụng biểu thức chính quy tiếng Việt thuần túy.
> - Nếu cuộc gọi API Gemini gặp timeout hoặc lỗi HTTP 429/500, hệ thống tự động kích hoạt `ReceiptParser` để bóc tách từ văn bản OCR thô, đảm bảo người dùng luôn nhận được kết quả mà ứng dụng không bị dừng đột ngột.

### ❓ Câu 4: Nhóm xử lý bài toán hóa đơn tiền trọ có tổng kép (tiền DV + tiền phòng) như thế nào?
> **Trả lời:**
> Trong hàm `extract_totals_full` của file `regex_parser.py`:
> - Nhận diện sự xuất hiện đồng thời của `room_service_total` và `room_rent_total`.
> - Tự động cộng gộp $\text{Tổng thanh toán} = \text{Tiền DV} + \text{Tiền Phòng}$ thay vì chỉ lấy một dòng tổng con.
> - Trong danh sách chi tiết, hỗ trợ `allow_zero=True` để nhận diện các dịch vụ miễn phí (như Để xe 0đ) mà không làm nhảy lệch số tiền của các dịch vụ thang máy hay máy giặt phía sau.

### ❓ Câu 5: Dữ liệu người dùng được lưu trữ và bảo mật như thế nào?
> **Trả lời:**
> - Mật khẩu người dùng được băm một chiều bảo mật bằng thuật toán **SHA-256 kết hợp mã Salt ngẫu nhiên**.
> - Dữ liệu được lưu trữ trên **Cloud Database PostgreSQL (Neon.tech)** kết nối qua giao thức mã hóa SSL.
> - Hệ thống có cơ chế tự động chuyển về SQLite khi chạy offline hoặc chạy test tự động.

---
*Tài liệu được biên soạn và chuẩn hóa toàn diện cho dự án Ví Xinh.*
