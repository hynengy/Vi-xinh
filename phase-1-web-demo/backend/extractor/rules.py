"""
Tập Luật Biểu Thức Chính Quy (Regex Rules) Cho Bóc Tách Hóa Đơn & Phiếu Chi
Phụ trách: Thành viên 3 - Lê Tiến Quân
Nhiệm vụ: Định nghĩa các mẫu regex để bắt Tên quán, Hotline, Địa chỉ, Ngày tháng, Tổng tiền, Món ăn
"""
import re

# 1. Từ khóa nhận diện dòng Tổng tiền
TOTAL_AMOUNT_KEYWORDS = [
    r"ti[ềêeéèẽẹ]n\s*thanh\s*to[áa]n",
    r"t[ổôoóòõọ]ng\s*thanh\s*to[áa]n",
    r"t[ổôoóòõọ]ng\s*ti[ềêeéèẽẹ]n\s*h[àa]ng",
    r"t[ổôoóòõọ]ng\s*(?:c[ộôo]ng|ti[ềêeéèẽẹ]n|chi\s*ph[íi]|thanh\s*to[áa]n)",
    r"t[ổôoóòõọ]ng\s*ti[ềêeéèẽẹ]n\s*(?:dv|d[ịi]ch\s*v[ụu]|ph[òo]ng)?",
    r"t[ổôoóòõọ]ng\s*ti[ềêeéèẽẹ]n\s*ph[òo]ng",
    r"t[ổôoóòõọ]ng\s*ti[ềêeéèẽẹ]n\s*dv",
    r"thanhto[áa]n",
    r"i[ềêeéèẽẹ]n\s*thanhto",
    r"i[ềêeéèẽẹ]n\s*thanh",
    r"thanh\s*to[áa]n",
    r"th[àa]nh\s*ti[ềêeéèẽẹ]n",
    r"t[ổôoóòõọ]ng\s*c[ảa]",
    r"t[ổôoóòõọ]ng",
    r"total",
    r"amount\s*due",
    r"grand\s*total",
    r"balance\s*due",
]

# Các từ khóa nhận diện dòng Header bảng
TABLE_HEADER_KEYWORDS = [
    "dịch vụ", "dich vu", "tiêu thụ", "tieu thu", "đơn giá", "don gia",
    "số lượng", "so luong", "chỉ số", "chi so", "cũ", "mới", "stt", "hàng hóa", "tên hàng",
    "thực đơn", "thuc don", "đv", "sl", "thành tiền", "thanh tien", "món ăn", "tên món",
    "diễn giải", "khoản chi", "quy cách"
]

# Pattern nhận diện số tiền: hỗ trợ cả phân cách dấu chấm (3.800.000), dấu phẩy (42,000), hoặc khoảng trắng (50 662 000)
AMOUNT_PATTERN = re.compile(
    r"(?:\d{1,3}(?:[.,\s]\d{3})+)\s*(?:[đ₫dD]|vn[dđ]|VN[DĐ]|dong)?|(?:\d{4,9})\s*(?:[đ₫dD]|vn[dđ]|VN[DĐ]|dong)?",
    re.IGNORECASE
)

# Pattern số bất kỳ dự phòng
FALLBACK_NUMBER_PATTERN = re.compile(r"\b\d{4,9}\b")

# Pattern nhận diện Hotline / Số điện thoại
HOTLINE_PATTERN = re.compile(
    r"(?:hotline|đt|dt|tel|phone|sđt|sdt|cskh|liên\s*hệ|lh)?\s*[:\s]*(\b(?:0[1-9]\d{1,2}[.\s-]?\d{3,4}[.\s-]?\d{3,4}|1[89]00[.\s-]?\d{4})\b)",
    re.IGNORECASE
)

# Pattern nhận diện Địa chỉ
ADDRESS_PREFIX_PATTERN = re.compile(
    r"^(?:địa\s*chỉ|dia\s*chi|đ\/c|đc|dc|address|add)\s*[:\s]*(.+)$",
    re.IGNORECASE
)

# 2. Pattern nhận diện Ngày tháng (DD/MM/YYYY, DD.MM.YYYY, MM/YYYY, YYYY-MM-DD,...)
DATE_PATTERNS = [
    re.compile(r"(\b\d{1,2}[./-]\d{1,2}[./-]\d{4}\b)"),
    re.compile(r"th[áa]ng\s*(\d{1,2})[/-](\d{4})", re.IGNORECASE),
    re.compile(r"(\b\d{4}[./-]\d{1,2}[./-]\d{1,2}\b)"),
    re.compile(r"ng[àa]y\s*(\d{1,2})\s*th[áa]ng\s*(\d{1,2})\s*n[ăa]m\s*(\d{4})", re.IGNORECASE),
]

# 3. Danh sách chuỗi thương hiệu phổ biến
KNOWN_MERCHANTS = [
    "HIGHLANDS COFFEE",
    "THE COFFEE HOUSE",
    "PHÚC LONG",
    "CIRCLE K",
    "WINMART+",
    "WINMART",
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
    "DING TEA",
    "KICHI-KICHI",
    "GOGI HOUSE",
    "HAIDILAO",
    "PIZZA 4P'S",
    "PIZZA HUT",
    "DOMINO'S PIZZA",
    "STARBUCKS",
    "TRUNG NGUYEN",
    "THAIHOAMART",
    "SIMPLE STAY",
]

# Từ khóa tiền tố xác định Nhà Hàng / Quán Ăn / Cửa Hàng
RESTAURANT_PREFIX_KEYWORDS = [
    "nhà hàng", "nha hang", "quán", "quan", "tiệm", "tiem",
    "cà phê", "ca phe", "coffee", "cafe", "trà sữa", "tra sua",
    "bánh mì", "banh mi", "bakery", "bếp", "bep", "ẩm thực", "am thuc",
    "hải sản", "hai san", "cơm", "com", "phở", "pho", "bún", "bun",
    "lẩu", "lau", "nướng", "nuong", "buffet", "bar", "pub", "bistro",
    "siêu thị", "sieu thi", "mart", "store", "shop"
]

# Các từ khóa bỏ qua khi tìm Tên Cửa Hàng
MERCHANT_IGNORE_KEYWORDS = [
    "phiếu thanh toán", "phieu thanh toan", "hóa đơn gtgt", "phiếu thu", "hóa đơn", "hoá đơn",
    "receipt", "invoice", "bill", "vat", "thu ngân", "thu ngan", "cashier",
    "nhân viên", "nhan vien", "bàn số", "ban so", "bàn:", "ban:", "khách hàng", "khach hang",
    "ngày", "ngay", "giờ", "gio", "stt", "đơn giá", "don gia", "số:", "so:", "bảng tính tiền", "order",
    "hotline", "điện thoại", "dien thoai", "đt:", "dt:", "tel:", "phone:", "sđt", "sdt:",
    "địa chỉ", "dia chi", "đ/c", "dc:", "đc:", "address", "addr",
    "mã số thuế", "ma so thue", "mst", "tax code",
    "website", "web:", "facebook", "fb:", "email", "wifi", "mật khẩu", "password", "pass:",
    "chúc quý khách", "cảm ơn quý khách", "cam on quy khach", "hẹn gặp lại", "hen gap lai",
    "tổng cộng", "tong cong", "thành tiền", "thanh tien", "thanh toan", "tien mat", "tiền mặt",
    "tiền thối", "tien thoi", "tiền thừa", "tien thua", "tích điểm", "tich diem"
]
