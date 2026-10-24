"""
Tập Luật Biểu Thức Chính Quy (Regex Rules) Cho Bóc Tách Hóa Đơn & Phiếu Chi
Phụ trách: Thành viên 3 - Lê Tiến Quân
Nhiệm vụ: Định nghĩa các mẫu regex để bắt Tên quán, Hotline, Địa chỉ, Ngày tháng, Tổng tiền, Món ăn
"""
import re

# 1. Từ khóa nhận diện số tiền Khách phải trả (Ưu tiên số 1 - Net Amount Due)
# Lưu ý: Tuyệt đối không để 'thanh toán' đơn độc vì sẽ bắt nhầm 'Hóa đơn thanh toán'
DUE_AMOUNT_KEYWORDS = [
    r"kh[áa]ch\s*ph[ảa]i\s*tr[ảa]",
    r"ti[ềe]n\s*c[ầa]n\s*thanh\s*to[áa]n",
    r"c[ầa]n\s*thanh\s*to[áa]n",
    r"ph[ảa]i\s*thanh\s*to[áa]n",
    r"t[ổôoóòõọ]ng\s*thanh\s*to[áa]n",
    r"t[ổôoóòõọ]ng\s*ti[ềêeéèẽẹ]n\s*thanh\s*to[áa]n",
    r"ti[ềêeéèẽẹ]n\s*thanh\s*to[áa]n",
    r"t[ổôoóòõọ]ng\s*c[ộôo]ng",
    r"t[ổôoóòõọ]ng\s*ti[ềêeéèẽẹ]n",
    r"amount\s*due",
    r"net\s*amount",
    r"grand\s*total",
    r"balance\s*due",
    r"total\s*payment",
    r"t[ổôoóòõọ]ng\s*c[ảa]",
]

# Từ khóa tiền khách đưa / tiền đã nhận (Cash / Card given / Tiền đã nhận)
PAID_AMOUNT_KEYWORDS = [
    r"ti[ềe]n\s*đ[ãa]\s*nh[ậa]n",
    r"đ[ãa]\s*nh[ậa]n",
    r"ti[ềe]n\s*nh[ậa]n",
    r"s[ốo]\s*ti[ềe]n\s*nh[ậa]n",
    r"nh[ậa]n\s*c[ủu]a\s*kh[áa]ch",
    r"ti[ềe]n\s*kh[áa]ch\s*đ[ưt][aơ]",
    r"kh[áa]ch\s*đ[ưt][aơ]",
    r"ti[ềe]n\s*đ[ưt][aơ]",
    r"ti[ềe]n\s*kh[áa]ch\s*tr[ảa]",
    r"kh[áa]ch\s*tr[ảa]",
    r"ti[ềe]n\s*m[ặa]t",
    r"chuy[ểe]n\s*kho[ảa]n",
    r"qu[ẹe]t\s*th[ẻe]",
    r"đ[ãa]\s*thanh\s*to[áa]n",
]

# Từ khóa tiền thối / tiền thừa (Change)
CHANGE_KEYWORDS = [
    r"ti[ềe]n\s*th[ừu]a",
    r"ti[ềe]n\s*th[ốo]i",
    r"th[ốo]i\s*l[ạa]i",
    r"ti[ềe]n\s*th[ốo]i\s*l[ạa]i",
    r"tr[ảa]\s*l[ạa]i",
    r"ti[ềe]n\s*tr[ảa]\s*l[ạa]i",
    r"tr[ảa]\s*l[ạa]i\s*kh[áa]ch",
    r"\bchange\b",
]

FINAL_PAYMENT_KEYWORDS = DUE_AMOUNT_KEYWORDS

# Từ khóa nhận diện dòng Tạm tính / Tổng tiền hàng (trước khi trừ giảm giá)
SUBTOTAL_KEYWORDS = [
    r"t[ổôoóòõọ]ng\s*ti[ềêeéèẽẹ]n\s*h[àa]ng",
    r"c[ộôo]ng\s*ti[ềêeéèẽẹ]n\s*h[àa]ng",
    r"ti[ềe]n\s*h[àa]ng",
    r"t[ạa]m\s*t[íi]nh",
    r"t[ổo]ng\s*ti[ềe]n\s*ch[ưu]a\s*gi[ảa]m",
    r"t[ổo]ng\s*ti[ềe]n\s*tr[ưu][ớo]c\s*thu[ếe]",
    r"subtotal",
]

# Từ khóa nhận diện Giảm giá, Chiết khấu, Khuyến mãi, Voucher
DISCOUNT_KEYWORDS = [
    r"gi[ảa]m\s*gi[áa]",
    r"chi[ếe]t\s*kh[ấa]u",
    r"khuy[ếe]n\s*m[ãa]i",
    r"khuy[ếe]n\s*m[ạa]i",
    r"voucher",
    r"coupon",
    r"discount",
    r"\bkm\b",
    r"gi[ảa]m\s*tr[ừu]",
    r"gi[ảa]m\s*ti[ềe]n",
    r"[ưu]u\s*[đd][ãa]i",
    r"tr[ợo]\s*gi[áa]",
    r"point\s*discount",
]

# Danh sách từ khóa tổng tiền gộp chung
TOTAL_AMOUNT_KEYWORDS = FINAL_PAYMENT_KEYWORDS + SUBTOTAL_KEYWORDS + [
    r"t[ổôoóòõọ]ng\s*(?:c[ộôo]ng|ti[ềêeéèẽẹ]n|chi\s*ph[íi]|thanh\s*to[áa]n)",
    r"t[ổôoóòõọ]ng\s*ti[ềêeéèẽẹ]n\s*(?:dv|d[ịi]ch\s*v[ụu]|ph[òo]ng)?",
    r"t[ổôoóòõọ]ng\s*ti[ềêeéèẽẹ]n\s*ph[òo]ng",
    r"t[ổôoóòõọ]ng\s*ti[ềêeéèẽẹ]n\s*dv",
    r"th[àa]nh\s*ti[ềêeéèẽẹ]n",
    r"total",
]

# Các từ khóa nhận diện dòng Header bảng
TABLE_HEADER_KEYWORDS = [
    "dịch vụ", "dich vu", "tiêu thụ", "tieu thu", "đơn giá", "don gia",
    "số lượng", "so luong", "chỉ số", "chi so", "cũ", "mới", "stt", "hàng hóa", "tên hàng",
    "thực đơn", "thuc don", "đv", "sl", "thành tiền", "thanh tien", "món ăn", "tên món",
    "diễn giải", "khoản chi", "quy cách"
]

# Từ khóa tiêu đề hóa đơn (tuyệt đối không được coi là món ăn hay tổng tiền)
RECEIPT_TITLE_KEYWORDS = [
    "phiếu tính tiền", "phieu tinh tien", "hóa đơn thanh toán", "hoa don thanh toan",
    "hóa đơn bán lẻ", "hoa don ban le", "phiếu thanh toán", "phieu thanh toan",
    "hóa đơn gtgt", "phiếu thu", "hoa don", "hóa đơn", "bảng tính tiền", "order bill"
]

# Từ khóa metadata của hóa đơn (Bàn, Giờ vào, Giờ ra, Thu ngân...) cần loại bỏ khỏi danh sách món
RECEIPT_METADATA_KEYWORDS = RECEIPT_TITLE_KEYWORDS + [
    "giờ vào", "gio vao", "giờ ra", "gio ra", "thu ngân", "thu ngan",
    "bàn", "ban", "phòng vip", "phong vip", "trong nhà", "trong nha", "mang về", "mang ve",
    "số hđ", "so hd", "sđ hd", "sd hd", "mã hđ", "ma hd", "mã bill", "số bill",
    "administrator", "cashier", "waiter", "order", "khách lẻ", "khach le"
]

# Từ khóa chân trang wifi / quảng cáo / cảm ơn
WIFI_FOOTER_KEYWORDS = [
    "wifi", "pass", "mật khẩu", "password", "taphoatoi", "taphoatai",
    "powered by", "kiotviet", "phần mềm", "lắp đặt", "cảm ơn", "cam on",
    "hẹn gặp lại", "hen gap lai", "chúc quý khách"
]

# Pattern nhận diện thời gian HH:MM hoặc HH.MM (tránh nhầm giờ vào ra thành số tiền)
TIME_PATTERN = re.compile(r"\b([01]?\d|2[0-3])[:.]([0-5]\d)\b")

# Pattern nhận diện số tiền: hỗ trợ cả phân cách dấu chấm (3.800.000), dấu phẩy (42,000), hoặc khoảng trắng (50 662 000)
AMOUNT_PATTERN = re.compile(
    r"(?:\d{1,3}(?:[.,\s]\d{3})+)\s*(?:[đ₫dD]|vn[dđ]|VN[DĐ]|dong)?|(?:\d{4,9})\s*(?:[đ₫dD]|vn[dđ]|VN[DĐ]|dong)?",
    re.IGNORECASE
)

# Pattern số bất kỳ dự phòng
FALLBACK_NUMBER_PATTERN = re.compile(r"\b\d{4,9}\b")

# Pattern nhận diện Hotline / Số điện thoại (bắt buộc có từ khóa phía trước)
HOTLINE_PATTERN = re.compile(
    r"(?:hotline|hotine|điện\s*thoại|dien\s*thoai|đt|dt|tel|phone|sđt|sdt|cskh|liên\s*hệ|lh)\s*[:\s\-]*([0-9.\s\-]{8,15})",
    re.IGNORECASE
)

# Pattern nhận diện Số hóa đơn / Mã phiếu
INVOICE_NUMBER_PATTERN = re.compile(
    r"(?:s[ốo]\s*h[đd]|so\s*hd|m[ãa]\s*h[đd]|ma\s*hd|s[ốo]\s*phi[ếe]u|so\s*phieu|m[ãa]\s*bill|s[ốo]\s*bill|invoice\s*(?:no|num)?|receipt\s*(?:no|num)?|bill\s*(?:no|num)?|s[ốo]\s*h[óo]a\s*đ[ơo]n|s[ốo]\s*ct|m[ãa]\s*ct|s[ốo]\s*:|so\s*:)\s*[:\s\-#]*([A-Z0-9\-_#/]{2,25})",
    re.IGNORECASE
)

# Pattern nhận diện Thuế VAT / GTGT
VAT_KEYWORDS = [
    r"thu[ếe]\s*gtgt",
    r"thu[ếe]\s*vat",
    r"\bvat\b",
    r"\bgtgt\b",
    r"\btax\b",
]

# Pattern nhận diện Thu ngân / Nhân viên
CASHIER_PATTERN = re.compile(
    r"(?:thu\s*ng[âa]n|cashier|nh[âa]n\s*vi[êe]n|nv\s*b[áa]n\s*h[àa]ng|nv)\s*[:\s\-]+([a-zA-ZÀ-ỹ0-9\s._-]{2,25})",
    re.IGNORECASE
)

# Pattern nhận diện Bàn / Phòng
TABLE_PATTERN = re.compile(
    r"(?:b[àa]n\s*s[ốo]|b[àa]n|ban|ph[òo]ng\s*vip|phong\s*vip|ph[òo]ng|table)\s*[:\s\-]+([A-Za-z0-9\-_]+)",
    re.IGNORECASE
)

# Pattern nhận diện Địa chỉ
ADDRESS_PREFIX_PATTERN = re.compile(
    r"(?:địa\s*chỉ|dia\s*chi|đ\/c|đc|dc|address|add)\s*[:\s\-]+(.+)$",
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
    "tạp hóa", "tap hoa", "bách hóa", "bach hoa", "cửa hàng", "cua hang",
    "bánh mì", "banh mi", "bakery", "bếp", "bep", "ẩm thực", "am thuc",
    "hải sản", "hai san", "cơm", "com", "phở", "pho", "bún", "bun",
    "lẩu", "lau", "nướng", "nuong", "buffet", "bar", "pub", "bistro",
    "siêu thị", "sieu thi", "mart", "store", "shop", "đại lý", "dai ly"
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
