"""
Tập Luật Biểu Thức Chính Quy (Regex Rules) Cho Bóc Tách Hóa Đơn
Phụ trách: Thành viên 3 - Lê Tiến Quân
Nhiệm vụ: Định nghĩa các mẫu regex để bắt Tên quán, Ngày tháng, Tổng tiền
"""
import re

# 1. Từ khóa nhận diện dòng Tổng tiền
TOTAL_AMOUNT_KEYWORDS = [
    r"t[ổo]ng\s*c[ộo]ng",
    r"t[ổo]ng\s*ti[ềe]n",
    r"th[àa]nh\s*ti[ềe]n",
    r"thanh\s*to[áa]n",
    r"t[ổo]ng\s*ti[ềe]n\s*thanh\s*to[áa]n",
    r"total",
    r"amount\s*due",
    r"grand\s*total",
    r"ti[ềe]n\s*m[ặa]t",
    r"cash",
]

# Pattern nhận diện số tiền (ví dụ: 150.000, 150,000, 150000, 45.000d, 50,000 VND)
AMOUNT_PATTERN = re.compile(
    r"(?:(?:\d{1,3}(?:[.,]\d{3})+)|(?:\d+))\s*(?:[đ₫dD]|vn[dđ]|VN[DĐ]|dong)?",
    re.IGNORECASE
)

# 2. Pattern nhận diện Ngày tháng (DD/MM/YYYY, DD-MM-YYYY, YYYY-MM-DD,...)
DATE_PATTERNS = [
    re.compile(r"(\b\d{1,2}[/-]\d{1,2}[/-]\d{4}\b)"),          # 25/12/2026 hoặc 25-12-2026
    re.compile(r"(\b\d{4}[/-]\d{1,2}[/-]\d{1,2}\b)"),          # 2026/12/25 hoặc 2026-12-25
    re.compile(r"ng[àa]y\s*(\d{1,2})\s*th[áa]ng\s*(\d{1,2})\s*n[ăa]m\s*(\d{4})", re.IGNORECASE),
]

# Pattern nhận diện Giờ giao dịch (HH:MM:SS hoặc HH:MM)
TIME_PATTERN = re.compile(r"(\b\d{1,2}:\d{2}(?::\d{2})?\b)")

# 3. Danh sách chuỗi cửa hàng phổ biến ở Việt Nam (đối sánh ưu tiên)
KNOWN_MERCHANTS = [
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
    "PIZZA HUT",
    "DOMINO'S PIZZA",
    "TOCOTOCO",
    "MIXUE",
    "KICHI-KICHI",
    "GOGI HOUSE",
]

# Các từ khóa bỏ qua khi tìm Tên Cửa Hàng
MERCHANT_IGNORE_KEYWORDS = [
    "hóa đơn", "phiếu thanh toán", "hóa đơn gtgt", "phiếu thu",
    "receipt", "invoice", "vat", "thu ngân", "nhân viên", "bàn số",
    "ngày", "giờ", "stt", "đơn giá", "thành tiền", "số:"
]
