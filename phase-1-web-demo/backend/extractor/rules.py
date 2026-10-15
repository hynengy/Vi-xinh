"""
Tập Luật Biểu Thức Chính Quy (Regex Rules) Cho Bóc Tách Hóa Đơn & Phiếu Chi
Phụ trách: Thành viên 3 - Lê Tiến Quân
Nhiệm vụ: Định nghĩa các mẫu regex để bắt Tên quán, Ngày tháng, Tổng tiền, Tiền trọ
"""
import re

# 1. Từ khóa nhận diện dòng Tổng tiền (Hỗ trợ cả không dấu, có dấu, gõ sai dấu OCR)
TOTAL_AMOUNT_KEYWORDS = [
    r"t[ổôoóòõọ]ng\s*(?:c[ộôo]ng|ti[ềêeéèẽẹ]n|chi\s*ph[íi]|thanh\s*to[áa]n)",
    r"t[ổôoóòõọ]ng\s*ti[ềêeéèẽẹ]n\s*(?:dv|d[ịi]ch\s*v[ụu]|ph[òo]ng)?",
    r"t[ổôoóòõọ]ng\s*ti[ềêeéèẽẹ]n\s*ph[òo]ng",
    r"t[ổôoóòõọ]ng\s*ti[ềêeéèẽẹ]n\s*dv",
    r"thanh\s*to[áa]n",
    r"th[àa]nh\s*ti[ềêeéèẽẹ]n",
    r"t[ổôoóòõọ]ng\s*c[ảa]",
    r"t[ổôoóòõọ]ng",
    r"total",
    r"amount\s*due",
    r"grand\s*total",
    r"balance\s*due",
]

# Các từ khóa nhận diện dòng Header bảng (để tránh nhận nhầm cột "Thành Tiền" là tổng tiền)
TABLE_HEADER_KEYWORDS = [
    "dịch vụ", "dich vu", "tiêu thụ", "tieu thu", "đơn giá", "don gia",
    "số lượng", "so luong", "chỉ số", "chi so", "cũ", "mới", "stt", "hàng hóa", "tên hàng"
]

# Pattern nhận diện số tiền (ví dụ: 3.800.000 đ, 3.365.800, 150,000, 45.000d, 50,000 VND)
# Bắt buộc ít nhất có phân cách hàng nghìn hoặc có ký hiệu tiền tệ để tránh bắt nhầm số công tơ điện (như 17247, 17738)
AMOUNT_PATTERN = re.compile(
    r"(?:\d{1,3}(?:[.,]\d{3})+)\s*(?:[đ₫dD]|vn[dđ]|VN[DĐ]|dong)?|(?:\d{4,9})\s*(?:[đ₫dD]|vn[dđ]|VN[DĐ]|dong)",
    re.IGNORECASE
)

# Pattern số bất kỳ dự phòng
FALLBACK_NUMBER_PATTERN = re.compile(r"\b\d{4,9}\b")

# 2. Pattern nhận diện Ngày tháng (DD/MM/YYYY, MM/YYYY, YYYY-MM-DD,...)
DATE_PATTERNS = [
    re.compile(r"(\b\d{1,2}[/-]\d{1,2}[/-]\d{4}\b)"),          # 25/12/2026 hoặc 25-12-2026
    re.compile(r"th[áa]ng\s*(\d{1,2})[/-](\d{4})", re.IGNORECASE),  # Tháng 10/2026
    re.compile(r"(\b\d{4}[/-]\d{1,2}[/-]\d{1,2}\b)"),          # 2026/12/25 hoặc 2026-12-25
    re.compile(r"ng[àa]y\s*(\d{1,2})\s*th[áa]ng\s*(\d{1,2})\s*n[ăa]m\s*(\d{4})", re.IGNORECASE),
]

# 3. Danh sách chuỗi thương hiệu / Nhà trọ phổ biến
KNOWN_MERCHANTS = [
    "SIMPLE STAY",
    "THÔNG BÁO TIỀN TRỌ",
    "TIỀN PHÒNG TRỌ",
    "CIRCLE K",
    "HIGHLANDS COFFEE",
    "PHÚC LONG",
    "THE COFFEE HOUSE",
    "WINMART",
    "WINMART+",
    "CO.OPMART",
    "7-ELEVEN",
    "MINISTOP",
    "GS25",
    "FAMILYMART",
    "LOTTE MART",
    "BIG C",
    "GO!",
    "KFC",
    "LOTTERIA",
    "JOLLIBEE",
    "TOCOTOCO",
    "MIXUE",
    "KICHI-KICHI",
]

# Các từ khóa bỏ qua khi tìm Tên Cửa Hàng
MERCHANT_IGNORE_KEYWORDS = [
    "phiếu thanh toán", "hóa đơn gtgt", "phiếu thu",
    "receipt", "invoice", "vat", "thu ngân", "nhân viên", "bàn số",
    "ngày", "giờ", "stt", "đơn giá", "số:", "bảng tính tiền"
]
