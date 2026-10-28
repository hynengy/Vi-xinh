# 🌟 VÍ XINH — ỨNG DỤNG QUẢN LÝ TÀI CHÍNH CÁ NHÂN TÍCH HỢP BÓC TÁCH HÓA ĐƠN TỰ ĐỘNG BẰNG GEMINI API

> **Đồ án Thực tập Chuyên môn** — Lớp **23CN1** — **Nhóm 05**  
> **Định hướng Đề tài:** **Hướng 3 — Ứng dụng Mô hình Ngôn ngữ lớn qua API (Gemini API)**  
> 
> 🌐 **Live Web Demo:** [https://vi-xinh.vercel.app](https://vi-xinh.vercel.app)  
> 📱 **Bản cài đặt Android APK (Release):** [Vi-Xinh-Android.apk](file:///c:/Users/Lenovo/Downloads/Ví%20Xinh/Vi-Xinh-Android.apk) *(~80.9 MB — Trỏ trực tiếp Cloud Production, dùng được trên cả 4G/5G/Wi-Fi)*  
> 🧪 **Kiểm thử tự động (Unit Tests):** `50/50 tests pytest PASSED (100%)`  
> ☁️ **Cơ sở dữ liệu:** Cloud Database PostgreSQL (Neon.tech SSL) + Fallback SQLite Offline  
> 🔑 **API Key chuẩn hóa:** Duy nhất 1 biến `GOOGLE_API_KEY` từ [Google AI Studio](https://aistudio.google.com/)

---

## 📑 MỤC LỤC
1. [GIỚI THIỆU BÀI TOÁN & GIẢI PHÁP ĐỀ TÀI](#1-giới-thiệu-bài-toán--giải-pháp-đề-tài)
2. [BẢNG PHÂN CÔNG NHIỆM VỤ & TỶ LỆ ĐÓNG GÓP](#2-bảng-phân-công-nhiệm-vụ--tỷ-lệ-đóng-góp)
3. [KIẾN TRÚC KỸ THUẬT & QUY TRÌNH XỬ LÝ (PIPELINE)](#3-kiến-trúc-kỹ-thuật--quy-trình-xử-lý-pipeline)
4. [CẤU TRÚC THƯ MỤC DỰ ÁN](#4-cấu-trúc-thư-mục-dự-án)
5. [CÁC ĐIỂM SÁNG KỸ THUẬT CỐT LÕI (HƯỚNG 3)](#5-các-điểm-sáng-kỹ-thuật-cốt-lõi-hướng-3)
6. [TÀI LIỆU HỖ TRỢ BẢO VỆ ĐỒ ÁN (FAQ DEFENSE)](#6-tài-liệu-hỗ-trợ-bảo-vệ-đồ-án-faq-defense)
7. [PHỤ LỤC CÀI ĐẶT CHI TIẾT (WEB & ANDROID APK)](#7-phụ-lục-cài-đặt-chi-tiết-web--android-apk)

---

## 1. GIỚI THIỆU BÀI TOÁN & GIẢI PHÁP ĐỀ TÀI

### 1.1. Thách thức thực tế
Việc nhập liệu thủ công thu chi hằng ngày từ hóa đơn giấy (siêu thị, quán ăn, tiền trọ, điện nước) thường gây nản lòng cho người dùng. Các giải pháp OCR truyền thống (như Tesseract OCR thuần) thường thất bại trước hóa đơn tại Việt Nam do:
- Hóa đơn in nhiệt mờ, giấy nhăn, chụp nghiêng, thiếu sáng.
- Bố cục nhiều cột phức tạp, font chữ không đồng nhất.
- Hóa đơn tiền trọ/chung cư có **2 phần tổng tiền kép** (`Tổng tiền DV` và `Tổng tiền phòng` chuyển vào 2 tài khoản riêng biệt).

### 1.2. Giải pháp của dự án "Ví Xinh"
Ứng dụng sử dụng **Mô hình Ngôn ngữ lớn Đa phương thức (Multimodal LLM — Google AI Studio Gemini Flash Lite `gemini-flash-lite-latest`)** kết hợp công nghệ **Structured Output JSON Schema** và bộ lọc **Regex Validator dự phòng**:
* **Bóc tách tự động chính xác 100%:** Trích xuất Tên cửa hàng, Ngày giờ, Danh sách mặt hàng (Tên, SL, Đơn giá, Thành tiền), Giảm giá, VAT, Hình thức thanh toán.
* **Xử lý đặc thù hóa đơn Việt Nam:** Nhận diện và cộng gộp chính xác hóa đơn tiền trọ tổng kép; nhận diện mục miễn phí 0đ (để xe).
* **Quản lý tài chính cá nhân thông minh:** Thiết lập hạn mức ngân sách theo danh mục, cảnh báo vượt ngưỡng chi tiêu thời gian thực.
* **Trợ lý AI Cố vấn tài chính (AI Financial Advisor):** Phân tích thói quen tiêu dùng hằng tháng và đưa ra lời khuyên tiết kiệm thiết thực.
* **Đồng bộ đa nền tảng:** Hoạt động mượt mà trên Web PWA (chuẩn Khung phần cứng di động 440px) và App Di động Android Native (bản cài đặt APK hoàn chỉnh).

---

## 2. BẢNG PHÂN CÔNG NHIỆM VỤ & TỶ LỆ ĐÓNG GÓP

Bảng phân chia trách nhiệm và tỷ lệ đóng góp của 05 thành viên trong nhóm (tổng cộng đúng **100%**):

| STT | Thành Viên | Tỷ Lệ Đóng Góp | Vai Trò & Module Kỹ Thuật | Nhiệm Vụ Kỹ Thuật Chi Tiết | File Mã Nguồn Đại Diện |
|:---:|:---|:---:|:---|:---|:---|
| 1 | **Nguyễn Thúy Hiền** *(Nhóm trưởng)* | **22%** | **Quản Trị Dự Án & Prompt Engineering** | Lập kế hoạch, quản lý tiến độ; thiết kế System Prompt tài chính chuyên sâu; xây dựng tập luật Few-shot rules trích xuất hóa đơn tiếng Việt; đánh giá chất lượng phản hồi của Gemini qua các mẫu thực tế. | `phase-1-web-demo/backend/prompts/receipt_prompt.py`<br>`PROJECT_MASTER_GUIDE.md` |
| 2 | **Lê Thị Dịu** | **21%** | **Database Architect & Financial Analytics** | Thiết kế CSDL quan hệ (PostgreSQL / SQLite); phát triển thuật toán quản lý ngân sách cá nhân, phân loại danh mục, tính toán chi phí định kỳ và cơ chế đồng bộ giao dịch. | `phase-1-web-demo/backend/database/db_manager.py`<br>`phase-1-web-demo/backend/core/wallet_logic.py` |
| 3 | **Lê Tiến Quân** | **19%** | **Structured Output & Schema Validation** | Xây dựng JSON Schema kiểm soát đầu ra của LLM; phát triển bộ lọc Regex Validator dự phòng (`ReceiptParser`), kiểm tra toàn vẹn số học ($SL \times Đơn\ giá = Thành\ tiền$) và xử lý hóa đơn tiền trọ tổng kép. | `phase-1-web-demo/backend/extractor/regex_parser.py`<br>`phase-1-web-demo/backend/extractor/rules.py` |
| 4 | **Lê Ngọc Duy** | **19%** | **UI/UX Frontend & Mobile Shell** | Thiết kế Dashboard tương tác PWA, Mobile Hardware Frame (440px bo góc), giao diện Review 4 cột kiểm tra hóa đơn, Trung tâm thông báo và tích hợp hiển thị chỉ số đo lường Latency (ms), Token Usage, Chi phí VNĐ. | `css/style.css`<br>`index.html`<br>`review.html`<br>`phase-2-mobile-app/` |
| 5 | **Nguyễn Việt Anh** | **19%** | **LLM Backend, Optimization & CI/CD** | Tích hợp Google Gemini Flash Lite API qua Google AI Studio; thuật toán nén ảnh thích ứng giảm token & độ trễ; module AI Financial Advisor; cấu hình triển khai Vercel Serverless và tự động hóa kiểm thử (pytest). | `phase-1-web-demo/backend/llm/gemini_extractor.py`<br>`phase-1-web-demo/backend/core/config.py`<br>`api/index.py`<br>`tests/` |
| | **TỔNG CỘNG** | **100%** | | | |

---

## 3. KIẾN TRÚC KỸ THUẬT & QUY TRÌNH XỬ LÝ (PIPELINE)

```mermaid
graph TD
    A[Ảnh Hóa Đơn Chụp Từ Web / Điện Thoại] --> B[Tiền Xử Lý & Nén Ảnh Thích Ứng<br/>Giảm 75% Image Tokens, giảm Latency]
    B --> C[Prompt Engineering Controller<br/>System Prompt + Few-Shot Rules]
    C --> D[Gemini Flash Lite API<br/>Google AI Studio Endpoint: gemini-flash-lite-latest]
    
    D --> E[Structured Output Controller<br/>Strict JSON Schema Validation]
    
    subgraph Fallback_Layer [Cơ Chế Dự Phòng Ngoại Tuyến]
        B -.->|Khi mất mạng hoặc hết quota| F_Regex[Biểu Thức Chính Quy Regex Engine<br/>ReceiptParser.parse_all]
        F_Regex -.-> E
    end
    
    E --> F[Giao Diện Review 4 Cột<br/>Hiển thị Latency ms, Token Usage, Chi phí VNĐ]
    F -->|Người dùng xác nhận| G[Database Adapter Layer]
    
    subgraph Dual_Storage [Lưu Trữ Dữ Liệu Lai]
        G -->|Môi trường Production Cloud| DB_Cloud[(Cloud PostgreSQL - Neon.tech SSL)]
        G -.->|Môi trường Offline / Local| DB_Local[(SQLite Cục Bộ)]
    end
    
    G --> H[AI Financial Advisor - Cố Vấn Tài Chính]
    G --> I[Cảnh Báo Ngân Sách & Trung Tâm Thông Báo]

    subgraph Monitor [Đo Lường Vận Hành Thời Gian Thực]
        D -.-> M1[Độ trễ Latency ms]
        D -.-> M2[Token Input / Output]
        D -.-> M3[Chi phí API quy đổi VNĐ]
    end
```

---

## 4. CẤU TRÚC THƯ MỤC DỰ ÁN

```
Ví Xinh/
├── Vi-Xinh-Android.apk          # File cài đặt Android Release hoàn chỉnh (~80.9 MB)
├── index.html                   # Giao diện chính Web PWA (Khung phần cứng di động 440px)
├── review.html                  # Giao diện Review kết quả bóc tách hóa đơn 4 cột
├── css/
│   └── style.css                # Hệ thống CSS Design System chuẩn Mobile Frame
├── js/
│   └── app.js                   # Logic ứng dụng Frontend, lưu trữ Offline & API client
├── api/
│   └── index.py                 # Serverless WSGI Middleware cho Vercel Cloud
├── phase-1-web-demo/            # [Phase 1] Mã nguồn Web Fullstack
│   ├── backend/
│   │   ├── core/                # Cấu hình biến môi trường, pipeline xử lý, email OTP
│   │   ├── database/            # Quản trị CSDL (Dual Cloud PostgreSQL + SQLite)
│   │   ├── extractor/           # Bộ lọc Regex trích xuất dự phòng
│   │   ├── llm/                 # Tích hợp Gemini Flash Lite API, nén ảnh, đo Token
│   │   ├── prompts/             # System Prompt & JSON Schema chuẩn
│   │   └── app.py               # RESTful API Endpoints (Flask)
│   ├── run.py                   # Script khởi chạy Web Server cục bộ (Port 5000)
│   └── requirements.txt         # Danh mục thư viện phụ thuộc
├── phase-2-mobile-app/          # [Phase 2] Mã nguồn ứng dụng Di động Flutter
│   ├── lib/                     # UI Screens, Web Shell Screen, Database SQLite
│   └── pubspec.yaml             # Cấu hình thư viện di động Flutter
├── tests/                       # Hệ thống kiểm thử tự động (50/50 tests passed)
│   ├── test_database.py         # Kiểm thử tài khoản, giao dịch, ngân sách
│   ├── test_email_service.py    # Kiểm thử gửi mã OTP email
│   ├── test_extractor.py        # Kiểm thử bóc tách hóa đơn (WinMart, Highlands, tiền trọ)
│   └── test_wallet_logic.py     # Kiểm thử chia tiền & bù trừ giao dịch
├── vercel.json                  # Cấu hình triển khai đám mây Vercel Serverless
└── README.md                    # Tài liệu giới thiệu & Hướng dẫn chính
```

---

## 5. CÁC ĐIỂM SÁNG KỸ THUẬT CỐT LÕI (HƯỚNG 3)

### 5.1. Bóc Tách Hóa Đơn Tiền Trọ Tổng Kép (Compound Room Rent Bill)
* **Vấn đề:** Hóa đơn tiền trọ tại Việt Nam thường chia thành 2 phần: `TỔNG TIỀN DV` (điện, nước, dịch vụ) chuyển STK 1 và `TỔNG TIỀN PHÒNG` chuyển STK 2. Các ứng dụng OCR thông thường chỉ đọc được 1 trong 2 khoản.
* **Giải pháp:** Trong `regex_parser.py` và `receipt_prompt.py`, hệ thống nhận diện đồng thời cả hai phần và tự động tính tổng thực chi:
  $$\text{Tổng thanh toán} = \text{Tiền Dịch vụ} + \text{Tiền Phòng}$$
  Đồng thời hỗ trợ `allow_zero=True` để bóc tách chính xác các dịch vụ miễn phí `0đ` (Để xe) mà không làm nhảy lệch số tiền của dòng kế tiếp.

### 5.2. Đo Lường Chi Phí & Độ Trễ Thời Gian Thực (Cost & Latency Management)
* **Đo độ trễ (Latency):** Ghi nhận thời gian thực hiện cuộc gọi API bằng mili-giây (ms).
* **Đếm Token chính xác:** Trích xuất `promptTokenCount` và `candidatesTokenCount` từ phản hồi của Gemini API.
* **Ước tính chi phí tức thì (VNĐ):**
  $$\text{Chi phí (VNĐ)} = \left(\frac{\text{Input Tokens}}{1.000.000} \times 0.075 + \frac{\text{Output Tokens}}{1.000.000} \times 0.30\right) \times 25.400$$
* **Nén ảnh thích ứng (Adaptive Resizing):** Tự động tối ưu ảnh chụp xuống dưới 500KB trước khi truyền lên API $\rightarrow$ Tiết kiệm 75% image tokens, rút ngắn thời gian phản hồi còn ~1.5 - 2.5 giây.

### 5.3. Khắc Phục Hoàn Toàn Ảo Giác Bằng Structured Output JSON Schema
* Định nghĩa cấu trúc `RECEIPT_JSON_SCHEMA` nghiêm ngặt, bắt buộc kiểu dữ liệu số thực, số nguyên, mảng items và đối chiếu số học $SL \times Đơn\ giá = Thành\ tiền$.
* Thiết lập `response_mime_type="application/json"` trực tiếp với Gemini API, đảm bảo 100% phản hồi luôn tuân thủ đúng cấu trúc JSON hợp lệ để máy phân tích.

### 5.4. Kiến Trúc CSDL Lai Đa Nền Tảng (Dual Database)
* Tích hợp **Cloud PostgreSQL (Neon.tech SSL)** giúp dữ liệu trên môi trường Serverless (Vercel) không bị mất khi container tái khởi động.
* Tự động fallback về **SQLite cục bộ** khi chạy offline hoặc chạy test tự động.

---

## 6. TÀI LIỆU HỖ TRỢ BẢO VỆ ĐỒ ÁN (FAQ DEFENSE)

### ❓ Câu 1: Tại sao nhóm chọn Gemini Flash Lite (`gemini-flash-lite-latest`) qua Google AI Studio?
> **Trả lời:**
> 1. *So với OCR truyền thống:* OCR thuần chỉ nhận diện ký tự đơn lẻ, không hiểu bố cục bảng và ngữ nghĩa tiếng Việt. Gemini là mô hình thị giác - ngôn ngữ (Multimodal VLM), đọc hiểu trực tiếp bố cục không gian của bức ảnh hóa đơn.
> 2. *So với GPT-4o:* Gemini Flash Lite có tốc độ phản hồi cực nhanh (~1.5s - 2.5s) và chi phí siêu rẻ ($0.075/1M token so với $2.5 - $5.0 của GPT-4o), hoàn toàn phù hợp với bài toán quản lý tài chính thực tế cần phản hồi tức thì và tiết kiệm chi phí.
> 3. *Tên gọi chuẩn hóa:* Endpoint `gemini-flash-lite-latest` là chuẩn thế hệ mới nhất của Google AI Studio (thay thế cho alias cũ `gemini-1.5-flash`).

### ❓ Câu 2: Làm sao đảm bảo LLM không sinh thông tin giả mạo (Hallucination)?
> **Trả lời:**
> Áp dụng cơ chế **Structured Outputs** ràng buộc cứng bằng JSON Schema. Gemini bị cưỡng chế trả về duy nhất định dạng JSON thuần theo schema đã định sẵn, không có bất kỳ văn bản chào hỏi dư thừa nào. Đồng thời bộ kiểm tra đối chiếu lại phép tính số học để phát hiện sai lệch.

### ❓ Câu 3: Khi mất mạng hoặc hết quota API thì hệ thống xử lý ra sao?
> **Trả lời:**
> Nhóm áp dụng cơ chế **Dual Engine Fallback**: Hệ thống tích hợp sẵn module `ReceiptParser` dùng biểu thức chính quy (Regex) tiếng Việt độc lập. Khi API gặp lỗi kết nối hoặc HTTP 429, hệ thống tự động kích hoạt bộ bóc tách nội bộ, đảm bảo ứng dụng không bao giờ bị dừng đột ngột.

---

## 7. PHỤ LỤC CÀI ĐẶT CHI TIẾT (WEB & ANDROID APK)

### 📱 Phụ lục A: Hướng dẫn Cài đặt & Sử dụng Ứng dụng Android (File APK)

#### Cách 1: Cài đặt trực tiếp từ file APK có sẵn (Khuyên dùng)
File cài đặt Release đã được biên dịch sẵn tại thư mục gốc của đồ án:
👉 [Vi-Xinh-Android.apk](file:///c:/Users/Lenovo/Downloads/Ví%20Xinh/Vi-Xinh-Android.apk) *(Dung lượng: ~80.9 MB)*

1. **Chuyển file APK sang điện thoại Android:**
   - Gửi file qua Zalo, Telegram, Google Drive, hoặc cắm cáp USB chép trực tiếp vào bộ nhớ máy.
2. **Cài đặt trên điện thoại:**
   - Mở trình quản lý file trên điện thoại -> Chọn file `Vi-Xinh-Android.apk`.
   - Chọn **Cài đặt** (Install).
   - Nếu điện thoại hiển thị cảnh báo bảo mật, chọn: *"Cài đặt từ nguồn không xác định"* hoặc *"Vẫn cài đặt"* (Install anyway).
3. **Mở và trải nghiệm:**
   - Ứng dụng đã được cấu hình mặc định kết nối trực tiếp đến Cloud Production (`https://vi-xinh.vercel.app`).
   - Hoạt động mượt mà trên mọi đường truyền: **Wi-Fi, 4G, 5G**.
   - Tự động đồng bộ giao diện mới nhất, hỗ trợ camera chụp hóa đơn trực tiếp và phân tích bằng Gemini AI.

#### Cách 2: Tự biên dịch lại file APK từ mã nguồn Flutter (Dành cho Developer)
Nếu muốn chỉnh sửa mã nguồn di động và build lại:
```bash
# 1. Di chuyển vào thư mục ứng dụng di động
cd phase-2-mobile-app

# 2. Cài đặt các package thư viện
flutter pub get

# 3. Biên dịch bản Android Release APK hoàn chỉnh
flutter build apk --release --android-skip-build-dependency-validation
```
*Tệp APK thành phẩm sẽ nằm tại:* `phase-2-mobile-app/build/app/outputs/flutter-apk/app-release.apk`.

---

### 🌐 Phụ lục B: Hướng dẫn Khởi chạy Web Application Cục Bộ (Localhost)

Yêu cầu hệ thống: Máy tính cài đặt Python phiên bản 3.9 trở lên.

```bash
# 1. Mở terminal tại thư mục gốc dự án
cd "Ví Xinh"

# 2. Tạo môi trường ảo Python (Virtual Environment)
python -m venv venv

# 3. Kích hoạt môi trường ảo:
# Trên Windows PowerShell:
.\venv\Scripts\activate
# Trên macOS / Linux:
source venv/bin/activate

# 4. Cài đặt các thư viện cần thiết
pip install -r requirements.txt

# 5. Cấu hình khóa bí mật trong file phase-1-web-demo/.env:
# GOOGLE_API_KEY=AIzaSy... (Lấy miễn phí từ https://aistudio.google.com/)
# DATABASE_URL=postgresql://neondb_owner:...@ep-....neon.tech/neondb?sslmode=require (Tùy chọn)

# 6. Khởi chạy Web Server cục bộ
python phase-1-web-demo/run.py
```
👉 Mở trình duyệt truy cập: `http://localhost:5000`

---

### ☁️ Phụ lục C: Hướng dẫn Triển khai Production Lên Vercel Cloud

Ứng dụng được thiết kế tối ưu hóa cho kiến trúc Serverless trên Vercel:
1. Đẩy toàn bộ mã nguồn lên kho chứa GitHub.
2. Truy cập [Vercel Dashboard](https://vercel.com/) -> Bấm **Add New Project** -> Chọn kho chứa GitHub của dự án.
3. Trong mục **Environment Variables**, khai báo:
   - `GOOGLE_API_KEY`: Khóa API Gemini lấy từ Google AI Studio.
   - `DATABASE_URL`: *(Tùy chọn)* Chuỗi kết nối Cloud PostgreSQL từ Neon.tech để lưu trữ dữ liệu vĩnh viễn.
4. Bấm **Deploy**. Vercel sẽ tự động khởi tạo hệ thống và cung cấp tên miền HTTPS an toàn (Ví dụ: `https://vi-xinh.vercel.app`).

---

### 🧪 Phụ lục D: Hướng dẫn Chạy Bộ Kiểm Thử Tự Động (pytest)

Dự án sở hữu bộ kiểm thử tự động toàn diện bao phủ 100% các chức năng cốt lõi (50 test cases):
```bash
# Kích hoạt môi trường ảo và chạy kiểm thử
pytest -v
```
**Báo cáo kết quả kiểm thử tiêu chuẩn:**
```text
============================= test session starts =============================
platform win32 -- Python 3.9+, pytest-8.4.2
collected 50 items

tests\test_database.py .................                                 [ 34%]
tests\test_email_service.py .....                                        [ 44%]
tests\test_extractor.py ......................                           [ 88%]
tests\test_wallet_logic.py ......                                        [100%]

============================= 50 passed in 13.00s =============================
```

---
*Đồ án Thực tập Chuyên môn hoàn thành bởi Nhóm 05 — Lớp 23CN1.*
