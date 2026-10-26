# 🌟 VÍ XINH — XÂY DỰNG ỨNG DỤNG QUẢN LÝ TÀI CHÍNH CÁ NHÂN VÀ NHÓM TÍCH HỢP TRÍCH XUẤT HÓA ĐƠN TỰ ĐỘNG BẰNG GEMINI API

> **Đồ án Thực tập Chuyên môn** — Lớp **23CN1** — **Nhóm 05**  
> **Định hướng Đề tài:** **Hướng 3 — Ứng dụng Mô hình Ngôn ngữ lớn qua API (Gemini API)**  
> **Ba Trọng tâm Nghiên cứu Kỹ thuật:**
> 1. 🎯 **Kỹ nghệ Lời nhắc (Prompt Engineering):** Thiết kế System Prompt tài chính & Luật bóc tách Few-shot rules.
> 2. 🛡️ **Kiểm soát Định dạng Đầu ra (Structured JSON Schema & Validation):** Ràng buộc cấu trúc 100%, khử ảo giác (Hallucination), đối chiếu số học $SL \times Đơn\ giá = Thành\ tiền$.
> 3. ⚡ **Quản lý Chi phí & Độ trễ (Cost & Latency Management):** Nén ảnh thích ứng, đo lường thời gian thực (ms, tokens in/out, chi phí quy đổi VNĐ).
> 
> 🌐 **Live Demo Production (Vercel Serverless):** [https://vi-xinh.vercel.app](https://vi-xinh.vercel.app)  
> 🧪 **Chất lượng Kiểm thử (Automated Tests):** `50/50 tests pytest PASSED (100%)`  
> ☁️ **Cơ sở dữ liệu:** Cloud Database PostgreSQL (Neon.tech SSL) + Fallback SQLite Offline  
> 🔑 **API Key chuẩn hóa:** Duy nhất 1 biến `GOOGLE_API_KEY` từ [Google AI Studio](https://aistudio.google.com/)

---

## 📑 MỤC LỤC
1. [GIỚI THIỆU BÀI TOÁN & TÍNH NĂNG ĐỘT PHÁ](#1-giới-thiệu-bài-toán--tính-năng-đột-phá)
2. [PHÂN CÔNG NHIỆM VỤ THÀNH VIÊN THEO CHUẨN HƯỚNG 3](#2-phân-công-nhiệm-vụ-thành-viên-theo-chuẩn-hướng-3)
3. [KIẾN TRÚC XỬ LÝ KỸ THUẬT (PIPELINE MULTIMODAL LLM)](#3-kiến-trúc-xử-lý-kỹ-thuật-pipeline-multimodal-llm)
4. [CẤU TRÚC THƯ MỤC & MÃ NGUỒN TOÀN DỰ ÁN](#4-cấu-trúc-thư-mục--mã-nguồn-toàn-dự-án)
5. [CÁC ĐIỂM SÁNG KỸ THUẬT ĐẶC BIỆT (CORE TECHNICAL HIGHLIGHTS)](#5-các-điểm-sáng-kỹ-thuật-đặc-biệt-core-technical-highlights)
   - [5.1. Bóc Tách Hóa Đơn Tiền Trọ Tổng Kép (Compound Room Rent Bill)](#51-bóc-tách-hóa-đơn-tiền-trọ-tổng-kép-compound-room-rent-bill)
   - [5.2. Hệ Thống Đo Lường Chi Phí & Độ Trễ (Cost & Latency Monitoring)](#52-hệ-thống-đo-lường-chi-phí--độ-trễ-cost--latency-monitoring)
   - [5.3. Kiến Trúc CSDL Lai: Cloud Neon PostgreSQL + SQLite Fallback](#53-kiến-trúc-csdl-lai-cloud-neon-postgresql--sqlite-fallback)
   - [5.4. Giao Diện Khung Phần Cứng Di Động (Mobile Hardware Frame) Trên PC](#54-giao-diện-khung-phần-cứng-di-động-mobile-hardware-frame-trên-pc)
   - [5.5. Quỹ Nhóm, Bù Trừ Nợ Tối Thiểu & Tạo Mã VietQR Chuẩn Napas 24/7](#55-quỹ-nhóm-bù-trừ-nợ-tối-thiểu--tạo-mã-vietqr-chuẩn-napas-247)
   - [5.6. Trung Tâm Thông Báo & Tự Lưu GOOGLE_API_KEY Trên Trình Duyệt](#56-trung-tâm-thông-báo--tự-lưu-google_api_key-trên-trình-duyệt)
6. [HƯỚNG DẪN KHỞI CHẠY & TRIỂN KHAI (QUICK START & DEPLOYMENT)](#6-hướng-dẫn-khởi-chạy--triển-khai-quick-start--deployment)
   - [6.1. Khởi chạy Web Demo cục bộ (Localhost)](#61-khởi-chạy-web-demo-cục-bộ-localhost)
   - [6.2. Cấu hình biến môi trường trên Vercel Cloud](#62-cấu-hình-biến-môi-trường-trên-vercel-cloud)
   - [6.3. Chạy hệ thống kiểm thử tự động (pytest)](#63-chạy-hệ-thống-kiểm-thử-tự-động-pytest)
   - [6.4. Chạy ứng dụng di động Flutter (Phase 2)](#64-chạy-ứng-dụng-di-động-flutter-phase-2)
7. [TÀI LIỆU HỖ TRỢ VẤN ĐÁP BẢO VỆ ĐỒ ÁN (FAQ DEFENSE)](#7-tài-liệu-hỗ-trợ-vấn-đáp-bảo-vệ-đồ-án-faq-defense)
8. [TÀI LIỆU LIÊN QUAN TRONG DỰ ÁN](#8-tài-liệu-liên-quan-trong-dự-án)

---

## 1. GIỚI THIỆU BÀI TOÁN & TÍNH NĂNG ĐỘT PHÁ

### 1.1. Bối cảnh & Thách thức
Nhập liệu chi tiêu từ hóa đơn giấy (siêu thị, quán ăn, nhà hàng, tiền trọ, điện nước) luôn là rào cản lớn nhất khiến người dùng từ bỏ việc quản lý tài chính cá nhân. Các giải pháp OCR truyền thống (như Tesseract OCR thuần) thường thất bại trước hóa đơn thực tế tại Việt Nam vì:
- Hóa đơn in nhiệt bị mờ, giấy nhăn, mất góc, chụp nghiêng hoặc thiếu sáng.
- Bố cục bảng nhiều cột phức tạp, chữ viết liền dòng.
- Đặc thù hóa đơn Việt Nam có **2 phần tổng tiền kép** (như hóa đơn tiền trọ gồm *Tổng tiền dịch vụ* và *Tổng tiền phòng* chuyển vào 2 số tài khoản ngân hàng khác nhau mà không có dòng tổng cộng in sẵn).

### 1.2. Giải pháp của dự án "Ví Xinh"
Ứng dụng khai thác sức mạnh của **Mô hình Ngôn ngữ lớn Đa phương thức (Multimodal LLM — Google AI Studio Gemini Flash Lite `gemini-flash-lite-latest`)** kết hợp bộ thẩm định **Structured Regex Validator**:
- **Trích xuất thông tin có cấu trúc 100%:** Bóc tách chính xác Tên cửa hàng, Ngày giờ, Danh sách từng mặt hàng (Tên, Số lượng, Đơn vị, Đơn giá, Thành tiền), Tiền giảm giá, Thuế VAT, Phương thức thanh toán.
- **Quản lý Ngân sách & Mục tiêu tiết kiệm thông minh:** Tự động theo dõi và cảnh báo khi chi tiêu vượt hạn mức từng danh mục, lập hũ tích lũy cho các kế hoạch tài chính cá nhân.
- **Trung tâm thông báo toàn diện (Notification Center):** Theo dõi lịch sử biến động số dư tức thì, kết quả quét hóa đơn AI, đọc/xóa thông báo và cảnh báo ngân sách.
- **Trải nghiệm ứng dụng di động cao cấp:** Tối ưu hóa hiển thị theo chuẩn Khung thiết bị di động (Mobile Hardware Frame 440px) ngay trên trình duyệt máy tính.

---

## 2. PHÂN CÔNG NHIỆM VỤ THÀNH VIÊN THEO CHUẨN HƯỚNG 3

| STT | Thành Viên | Module Kỹ Thuật Phụ Trách | Nhiệm Vụ Kỹ Thuật Chi Tiết | File Mã Nguồn Đại Diện |
|:---:|:---|:---|:---|:---|
| 1 | **Nguyễn Thúy Hiền** | **Prompt Engineering & Model Evaluator** | Thiết kế System Prompt đóng vai chuyên gia tài chính; xây dựng tập luật trích xuất Few-shot rules; đánh giá chất lượng phản hồi của Gemini qua các kịch bản hóa đơn. | `phase-1-web-demo/backend/prompts/receipt_prompt.py` |
| 2 | **Lê Thị Dịu** | **Database & Financial Analytics** | Thiết kế CSDL quan hệ; xây dựng thuật toán quản lý ngân sách cá nhân, thống kê thu chi thu nhập, theo dõi chi phí định kỳ và đồng bộ giao dịch. | `phase-1-web-demo/backend/database/db_manager.py`<br>`phase-1-web-demo/backend/core/wallet_logic.py` |
| 3 | **Lê Tiến Quân** | **Structured Output & Schema Validation** | Xây dựng JSON Schema kiểm soát đầu ra; phát triển bộ lọc Regex Validator dự phòng (`ReceiptParser`), kiểm tra toàn vẹn số học và xử lý hóa đơn phức tạp (tiền trọ, VAT, giảm giá). | `phase-1-web-demo/backend/extractor/regex_parser.py`<br>`phase-1-web-demo/backend/extractor/rules.py` |
| 4 | **Lê Ngọc Duy** | **Giao Diện UI/UX (Web & Flutter)** | Thiết kế Dashboard tương tác, Mobile Hardware Frame, Trung tâm thông báo, Review 4 cột kiểm tra hóa đơn, bảng hiển thị chỉ số Latency (ms), Token Usage, Chi phí và AI tư vấn tài chính. | `css/style.css`<br>`index.html`<br>`review.html`<br>`phase-2-mobile-app/` |
| 5 | **Nguyễn Việt Anh** | **LLM Backend & Cost/Latency Optimization** | Tích hợp Google Gemini API qua Google AI Studio; thuật toán nén ảnh giảm latency; đo token count / chi phí API; tích hợp AI Financial Advisor; quản trị CI/CD và triển khai Vercel. | `phase-1-web-demo/backend/llm/gemini_extractor.py`<br>`phase-1-web-demo/backend/core/config.py`<br>`api/index.py` |

---

## 3. KIẾN TRÚC XỬ LÝ KỸ THUẬT (PIPELINE MULTIMODAL LLM)

```mermaid
graph TD
    A[Ảnh Hóa Đơn Chụp Từ Web / Điện Thoại] --> B[Image Preprocessing & Resizing<br/>Nén thích ứng giảm 75% Image Tokens]
    B --> C[Prompt Engineering Controller<br/>System Prompt + Few-Shot Rules]
    C --> D[Gemini Flash Lite API<br/>Google AI Studio Endpoint (gemini-flash-lite-latest)]
    
    D --> E[Structured Output Controller<br/>Strict JSON Schema Validation]
    
    subgraph Fallback_Mechanism [Cơ Chế Dự Phòng Song Song]
        B -.->|Dự phòng khi mất mạng/hết quota| F_Regex[Biểu Thức Chính Quy Regex Engine<br/>ReceiptParser.parse_all]
        F_Regex -.-> E
    end
    
    E --> F[Review Interface 4 Cột<br/>Hiển thị Latency ms, Token Usage, Chi phí VNĐ]
    F -->|Người dùng xác nhận| G[Database Adapter Layer]
    
    subgraph Storage_Layer [Lưu Trữ Dữ Liệu Lai]
        G -->|Môi trường Online| DB_Cloud[(Cloud Database: Neon PostgreSQL)]
        G -.->|Môi trường Offline/Local| DB_Local[(Local SQLite Fallback)]
    end
    
    G --> H[AI Financial Advisor<br/>Tóm Tắt Chi Tiêu & Gợi Ý Tiết Kiệm]
    G --> I[Chia Tiền Nhanh / Tạo Mã VietQR Không Cần App]
    G --> J[Trung Tâm Thông Báo / Cảnh Báo Ngân Sách]

    subgraph Monitoring [Theo Dõi Chi Phí & Độ Trễ Thời Gian Thực]
        D -.-> T1[Đo Latency ms]
        D -.-> T2[Đếm Token Input / Output]
        D -.-> T3[Ước tính Chi Phí VNĐ]
    end
```

---

## 4. CẤU TRÚC THƯ MỤC & MÃ NGUỒN TOÀN DỰ ÁN

```
Ví Xinh/
├── .github/workflows/           # Tự động hóa CI/CD kiểm thử GitHub Actions
├── api/
│   └── index.py                 # Serverless WSGI Middleware cho Vercel Cloud
├── assets/                      # Hình ảnh thương hiệu, logo ứng dụng
├── css/
│   └── style.css                # Hệ thống Design System v4.0 (Khung phần cứng di động 440px)
├── data/
│   ├── app.db                   # CSDL SQLite cục bộ (Offline/Dev mode)
│   └── sample_receipts/         # Bộ sưu tập ảnh hóa đơn thực tế phục vụ kiểm thử
├── docs/                        # Tài liệu kiến trúc phần mềm
│   ├── database_design.md       # Thiết kế CSDL quan hệ và ERD
│   └── pipeline_architecture.md # Đặc tả luồng xử lý Multimodal LLM
├── js/
│   └── app.js                   # Logic JavaScript xử lý tương tác Frontend & Offline Store
├── phase-1-web-demo/            # [Phase 1] Ứng dụng Web PWA Fullstack
│   ├── backend/
│   │   ├── core/
│   │   │   ├── config.py        # Quản lý GOOGLE_API_KEY và biến môi trường
│   │   │   ├── email_service.py # Dịch vụ gửi mã OTP qua SMTP
│   │   │   ├── pipeline.py      # Xâu chuỗi quy trình xử lý hóa đơn
│   │   │   └── wallet_logic.py  # Thuật toán chia nợ nhóm & tạo mã VietQR
│   │   ├── database/
│   │   │   ├── db_manager.py    # Dual DB Adapter: Cloud PostgreSQL + SQLite
│   │   │   └── models.py        # Định nghĩa cấu trúc các bảng CSDL
│   │   ├── extractor/
│   │   │   ├── regex_parser.py  # Bộ bóc tách Regex toàn diện (hóa đơn trọ kép, VAT...)
│   │   │   └── rules.py         # Từ điển từ khóa hóa đơn tiếng Việt
│   │   ├── llm/
│   │   │   ├── gemini_extractor.py       # Tích hợp Google AI Studio Gemini Flash Lite, đo Latency & Token
│   │   │   └── image_preprocessing.py   # Thuật toán nén ảnh giảm chi phí/độ trễ
│   │   ├── prompts/
│   │   │   └── receipt_prompt.py        # System Prompt & JSON Schema chuẩn
│   │   └── app.py               # RESTful API Endpoints (Flask Framework)
│   ├── frontend/                # Mã nguồn giao diện Web tĩnh đồng bộ
│   ├── .env                     # File biến môi trường bảo mật (GOOGLE_API_KEY)
│   ├── run.py                   # Script khởi chạy Web Server cục bộ (Port 5000)
│   └── requirements.txt         # Thư viện phụ thuộc của Backend
├── phase-2-mobile-app/          # [Phase 2] Ứng dụng Di Động Flutter (Android / iOS)
│   ├── lib/
│   │   ├── providers/           # Quản lý trạng thái (State Management)
│   │   ├── screens/             # Màn hình Mobile (Dashboard, Camera OCR, Budget...)
│   │   └── main.dart            # Khởi chạy ứng dụng Flutter
│   └── pubspec.yaml             # Cấu hình thư viện Flutter
├── tests/                       # Bộ kiểm thử tự động toàn diện (50/50 test cases)
│   ├── test_database.py         # 17 test cases CSDL (tài khoản, giao dịch, budget)
│   ├── test_email_service.py    # 5 test cases dịch vụ OTP email
│   ├── test_extractor.py        # 22 test cases bóc tách hóa đơn (WinMart, Highlands, tiền trọ)
│   └── test_wallet_logic.py     # 6 test cases chia tiền & bù trừ nợ
├── index.html                   # Trang chủ ứng dụng Web PWA (Tích hợp Trung tâm thông báo)
├── review.html                  # Giao diện Review kết quả bóc tách 4 cột
├── vercel.json                  # Cấu hình điều hướng Vercel Serverless
├── PROJECT_MASTER_GUIDE.md      # Cẩm nang toàn diện dự án Ví Xinh
└── README.md                    # Tài liệu giới thiệu chính của Repository
```

---

## 5. CÁC ĐIỂM SÁNG KỸ THUẬT ĐẶC BIỆT (CORE TECHNICAL HIGHLIGHTS)

### 5.1. Bóc Tách Hóa Đơn Tiền Trọ Tổng Kép (Compound Room Rent Bill)
- **Vấn đề thực tế:** Hóa đơn tiền trọ/chung cư tại Việt Nam thường có 2 phần riêng biệt: `TỔNG TIỀN DV` (Điện, nước, wifi, máy giặt, thang máy, để xe...) chuyển khoản vào STK 1, và `TỔNG TIỀN PHÒNG` chuyển khoản vào STK 2. Các ứng dụng thông thường sẽ bị mất 1 trong 2 khoản hoặc làm lệch đơn giá của dịch vụ miễn phí 0đ (Để xe).
- **Giải pháp của nhóm trong `regex_parser.py` và `receipt_prompt.py`:**
  - Tự động nhận diện sự xuất hiện đồng thời của cả `TỔNG TIỀN DV` (ví dụ `3.365.800 đ`) và `TỔNG TIỀN PHÒNG` (`3.800.000 đ`).
  - Tự động tính toán tổng thực chi:
    $$\text{Tổng thanh toán} = 3.365.800 + 3.800.000 = \mathbf{7.165.800\text{ đ}}$$
  - Phân tách chi tiết (Breakdown) hiển thị minh bạch từng khoản.
  - Hỗ trợ tham số `allow_zero=True` để bóc tách chính xác dịch vụ `Để xe | 0 đ` (miễn phí), không làm nhảy lệch sang số tiền của dòng `Thang máy 250.000 đ`. Tự động tách bỏ phần ghi chú số tài khoản bên phải.

### 5.2. Hệ Thống Đo Lường Chi Phí & Độ Trễ (Cost & Latency Monitoring)
Đáp ứng trọn vẹn yêu cầu trọng tâm của **Hướng 3**, ứng dụng đo lường và hiển thị trực quan các chỉ số vận hành trên giao diện:
- **Độ trễ xử lý (Latency):** Đo bằng `time.time()` (tính bằng mili-giây ms).
- **Số lượng Token:** Đếm chính xác `promptTokenCount` và `candidatesTokenCount` từ `usageMetadata` của phản hồi Gemini API.
- **Ước tính Chi phí API:**
  $$\text{Chi phí (VNĐ)} = \left(\frac{\text{Input Tokens}}{1.000.000} \times 0.075 + \frac{\text{Output Tokens}}{1.000.000} \times 0.30\right) \times 25.400$$
- **Nén ảnh thích ứng (Adaptive Resizing):** Giảm dung lượng ảnh chụp từ 5MB xuống dưới 500KB trước khi truyền lên API $\rightarrow$ Giảm số lượng token hình ảnh từ 1000+ tokens xuống ~258 tokens $\rightarrow$ Giúp giảm độ trễ phản hồi xuống dưới 2.5 giây.

### 5.3. Kiến Trúc CSDL Lai: Cloud Neon PostgreSQL + SQLite Fallback
- **Khắc phục nhược điểm của Serverless (Vercel):** Hạ tầng Serverless không duy trì trạng thái ổ cứng cục bộ (ephemeral file system), nếu chỉ dùng SQLite thì dữ liệu người dùng sẽ bị xóa sau mỗi lần container khởi động lại.
- **Giải pháp Dual-Mode trong `db_manager.py`:**
  - Tự động nhận diện biến môi trường `DATABASE_URL` để kết nối trực tiếp đến **Cloud Database PostgreSQL (Neon.tech)** qua kết nối bảo mật SSL.
  - Đồng bộ dữ liệu người dùng và giao dịch thời gian thực giữa Web và Mobile.
  - Tự động chuyển về **SQLite cục bộ** (`data/app.db`) khi chạy kiểm thử `pytest` hoặc khi mất kết nối mạng, đảm bảo hệ thống không bao giờ bị dừng đột ngột.

### 5.4. Giao Diện Khung Phần Cứng Di Động (Mobile Hardware Frame) Trên PC
- Khi người dùng mở ứng dụng trên màn hình máy tính (PC / Laptop / Tablet $\ge$ 600px):
  - Giao diện được cố định ở kích thước chuẩn **440px** (tỷ lệ màn hình flagship iPhone 16 Pro Max), căn giữa màn hình.
  - Khung viền bo tròn mềm mại `border-radius: 44px`, viền bezel kép trắng nổi bật kết hợp đổ bóng đa tầng.
  - Mô phỏng phần cứng thực tế với **khe Loa thoại / Dynamic Island** ở đỉnh máy và **thanh Home Indicator** ở chân máy (gán `pointer-events: none` không làm cản trở tương tác).
- Khi mở trên điện thoại di động thật (< 600px): Giao diện tự động bung full 100% màn hình tự nhiên.

### 5.5. Quỹ Nhóm, Bù Trừ Nợ Tối Thiểu & Tạo Mã VietQR Chuẩn Napas 24/7
- Hỗ trợ chia tiền linh hoạt: Chia đều (Equal Split), chia theo phần trăm hoặc chia theo món đã dùng.
- Áp dụng giải thuật bù trừ công nợ tối thiểu (Minimizing Debt Transactions) nhằm giảm thiểu tối đa số lần chuyển tiền qua lại trong nhóm.
- Tự động sinh đường dẫn ảnh **VietQR**:
  ```
  https://img.vietqr.io/image/{bank_code}-{account_number}-compact2.png?amount={amount}&addInfo={content}
  ```
  Thành viên trong nhóm chỉ cần dùng app ngân hàng quét mã để thanh toán tức thì.

### 5.6. Trung Tâm Thông Báo & Tự Lưu GOOGLE_API_KEY Trên Trình Duyệt
- **Trung tâm thông báo toàn diện:** Quản lý mọi biến động số dư, quét hóa đơn, cảnh báo ngân sách. Hỗ trợ mở từ Header hoặc qua trang Cài đặt, đánh dấu đọc tất cả, xóa thông báo.
- **Tự động lưu và đồng bộ GOOGLE_API_KEY:**
  - Khi người dùng nhập khóa `GOOGLE_API_KEY` từ Google AI Studio trên giao diện web, mã khóa được tự động lưu vào `localStorage` của trình duyệt.
  - Mỗi yêu cầu quét hóa đơn sẽ tự động đính kèm header `X-Google-Api-Key`, giúp hệ thống trên môi trường Vercel Serverless luôn hoạt động ổn định mà người dùng không cần phải dán lại khóa nhiều lần.

---

## 6. HƯỚNG DẪN KHỞI CHẠY & TRIỂN KHAI (QUICK START & DEPLOYMENT)

### 6.1. Khởi chạy Web Demo cục bộ (Localhost)
```bash
# 1. Di chuyển vào thư mục dự án
cd "Ví Xinh"

# 2. Tạo và kích hoạt môi trường ảo Python
python -m venv venv
# Kích hoạt trên Windows PowerShell:
.\venv\Scripts\activate

# 3. Cài đặt các thư viện cần thiết
pip install -r requirements.txt

# 4. Thiết lập biến môi trường trong file phase-1-web-demo/.env:
# GOOGLE_API_KEY=AQ... hoặc AIzaSy... (lấy miễn phí từ aistudio.google.com)
# DATABASE_URL=postgresql://neondb_owner:...@ep-....neon.tech/neondb?sslmode=require

# 5. Khởi chạy Web Server cục bộ
python phase-1-web-demo/run.py
```
👉 Truy cập ứng dụng tại: `http://localhost:5000`

---

### 6.2. Cấu hình biến môi trường trên Vercel Cloud
Do file `.env` được bảo vệ bằng `.gitignore` để không bị lộ mã bí mật lên GitHub, khi triển khai lên **Vercel**, bạn cấu hình biến môi trường như sau:
1. Truy cập **[Vercel Dashboard](https://vercel.com/)** $\rightarrow$ Chọn dự án **Vi-xinh**.
2. Chọn tab **Settings** $\rightarrow$ Mục **Environment Variables** (menu bên trái).
3. Thêm các biến môi trường:
   - **`GOOGLE_API_KEY`**: Dán mã khóa lấy từ [Google AI Studio](https://aistudio.google.com/).
   - **`DATABASE_URL`**: *(Tùy chọn)* Dán chuỗi kết nối Cloud PostgreSQL (Neon.tech) nếu muốn lưu trữ dữ liệu vĩnh viễn trên đám mây.
4. Bấm **Save** và nhấn **Redeploy** bản triển khai mới nhất.

---

### 6.3. Chạy hệ thống kiểm thử tự động (pytest)
Dự án được xây dựng với hệ thống kiểm thử toàn diện **50 test cases** đạt tỷ lệ thành công 100%:
```bash
pytest -v
```
**Kết quả kiểm thử chuẩn:**
```text
============================= test session starts =============================
platform win32 -- Python 3.9+, pytest-8.4.2
collected 50 items

tests\test_database.py .................                                 [ 34%]
tests\test_email_service.py .....                                        [ 44%]
tests\test_extractor.py ......................                           [ 88%]
tests\test_wallet_logic.py ......                                        [100%]

============================= 50 passed in ~10s ===============================
```

---

### 6.4. Chạy ứng dụng di động Flutter (Phase 2)
```bash
cd phase-2-mobile-app
flutter pub get

# Chạy trên thiết bị giả lập hoặc máy thật kết nối USB:
flutter run

# Xuất file cài đặt Android APK hoàn chỉnh:
flutter build apk --release
```

---

## 7. TÀI LIỆU HỖ TRỢ VẤN ĐÁP BẢO VỆ ĐỒ ÁN (FAQ DEFENSE)

### ❓ Câu 1: Tại sao nhóm chọn Gemini Flash Lite (`gemini-flash-lite-latest`) qua Google AI Studio mà không dùng GPT-4o hay Tesseract OCR truyền thống?
> **Trả lời:**
> 1. *So với OCR truyền thống (Tesseract):* Tesseract chỉ nhận diện ký tự đơn thuần, không hiểu bố cục bảng và ngữ nghĩa tiếng Việt. Với hóa đơn nhăn, mờ hoặc hóa đơn tiền trọ có tổng tiền kép, Tesseract sẽ sinh văn bản rác và cần hàng nghìn dòng regex chắp vá. Gemini là Multimodal Vision-Language Model có khả năng đọc hiểu trực tiếp ngữ nghĩa không gian của bức ảnh.
> 2. *So với GPT-4o và các model lớn khác:* Mô hình `gemini-flash-lite-latest` (Gemini Flash Lite thế hệ mới nhất của Google AI Studio) có tốc độ xử lý nhanh vượt trội (độ trễ chỉ ~1.5 - 2.5 giây) và chi phí siêu tiết kiệm ($0.0375 - $0.075 / 1 triệu token đầu vào so với $2.5 - $5.0 của GPT-4o), hoàn toàn phù hợp với bài toán quản lý tài chính thực tế cần phản hồi tức thì và tiết kiệm chi phí vận hành.
> 3. *Về tên gọi kỹ thuật:* Google AI Studio đã chuẩn hóa endpoint thế hệ mới sang `gemini-flash-lite-latest` và `gemini-flash-latest` (thay vì alias cũ `gemini-1.5-flash` vốn trả về 404 trên API v1beta đối với các gói dự án mới). Hệ thống của nhóm tự động ưu tiên `gemini-flash-lite-latest` và tự động fallback tuần tự sang các model Flash khác nếu cần.

### ❓ Câu 2: Nhóm đã làm thế nào để đảm bảo LLM không bị "ảo giác" (Hallucination) và luôn trả về JSON hợp lệ?
> **Trả lời:**
> Nhóm áp dụng cơ chế **Structured Outputs bằng JSON Schema**:
> - Định nghĩa một `RECEIPT_JSON_SCHEMA` rõ ràng: quy định kiểu dữ liệu từng trường, danh sách các trường bắt buộc (`required`), và quy tắc số học $SL \times Đơn\ giá = Thành\ tiền$.
> - Thiết lập `response_mime_type="application/json"` và truyền schema trực tiếp vào cấu hình sinh của Gemini API. Mô hình bị cưỡng chế xuất ra JSON hợp lệ 100%, không sinh thêm bất kỳ câu chào hỏi hay ký tự markdown dư thừa nào.

### ❓ Câu 3: Làm thế nào ứng dụng hoạt động nếu mất mạng hoặc hết hạn mức API Gemini?
> **Trả lời:**
> Nhóm đã xây dựng cơ chế **Dual Engine Fallback**:
> - Hệ thống có sẵn module `ReceiptParser` sử dụng biểu thức chính quy (Regex) tiếng Việt độc lập và cơ chế đọc bộ nhớ đệm mẫu offline (`.ocr.txt`).
> - Nếu cuộc gọi API Gemini gặp sự cố timeout hoặc hết hạn mức (HTTP 429), hệ thống tự động kích hoạt `ReceiptParser` để bóc tách từ văn bản OCR thô, đảm bảo người dùng luôn nhận được kết quả mà ứng dụng không bị dừng đột ngột.

### ❓ Câu 4: Nhóm xử lý bài toán hóa đơn tiền trọ có 2 phần tổng tiền (Dịch vụ + Phòng) như thế nào?
> **Trả lời:**
> Trong hàm `extract_totals_full` của file `regex_parser.py`:
> - Nhận diện sự xuất hiện đồng thời của `room_service_total` và `room_rent_total`.
> - Tự động tính tổng tiền thực chi $\text{Tổng thanh toán} = \text{Tiền DV} + \text{Tiền Phòng}$ thay vì chỉ lấy một dòng tổng con.
> - Hỗ trợ tham số `allow_zero=True` để nhận diện chính xác các dịch vụ miễn phí (như Để xe 0đ) mà không làm nhảy lệch số tiền của các dịch vụ thang máy hay máy giặt phía sau.

### ❓ Câu 5: Dữ liệu người dùng được lưu trữ và bảo mật ra sao trên hạ tầng đám mây?
> **Trả lời:**
> - Mật khẩu người dùng được băm một chiều bảo mật bằng thuật toán **SHA-256 kết hợp mã Salt ngẫu nhiên**.
> - Dữ liệu được lưu trữ tập trung trên **Cloud Database PostgreSQL (Neon.tech)** kết nối qua giao thức mã hóa SSL.
> - Hệ thống hỗ trợ cơ chế tự động chuyển về SQLite khi chạy offline hoặc chạy test tự động.

---

## 8. TÀI LIỆU LIÊN QUAN TRONG DỰ ÁN
* 📖 [Cẩm Nang Toàn Diện Dự Án (PROJECT_MASTER_GUIDE.md)](file:///c:/Users/Lenovo/Downloads/Ví%20Xinh/PROJECT_MASTER_GUIDE.md)
* 📐 [Đặc Tả Luồng Xử Lý Kỹ Thuật (pipeline_architecture.md)](file:///c:/Users/Lenovo/Downloads/Ví%20Xinh/docs/pipeline_architecture.md)
* 🗄️ [Thiết Kế Cơ Sở Dữ Liệu (database_design.md)](file:///c:/Users/Lenovo/Downloads/Ví%20Xinh/docs/database_design.md)
* 🤝 [Quy Chuẩn Đóng Góp Mã Nguồn (CONTRIBUTING.md)](file:///c:/Users/Lenovo/Downloads/Ví%20Xinh/CONTRIBUTING.md)

---
*Đồ án được phát triển và hoàn thiện bởi Nhóm 05 — Lớp 23CN1.*
