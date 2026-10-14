"""
Bộ Phân Tích & Bóc Tách Thông Tin Hóa Đơn Bằng Regex
Phụ trách: Thành viên 3 - Lê Tiến Quân
Nhiệm vụ: Trích xuất chính xác Tên cửa hàng, Ngày tháng, Tổng tiền từ raw text của OCR
"""
import re
from datetime import datetime
from typing import Dict, Any, Optional
from .rules import (
    TOTAL_AMOUNT_KEYWORDS,
    AMOUNT_PATTERN,
    DATE_PATTERNS,
    KNOWN_MERCHANTS,
    MERCHANT_IGNORE_KEYWORDS,
)


class ReceiptParser:
    """Trích xuất trường dữ liệu từ chuỗi văn bản thô OCR."""

    @staticmethod
    def clean_text(raw_text: str) -> list[str]:
        """Chuẩn hóa và tách văn bản thành các dòng sạch."""
        lines = [line.strip() for line in raw_text.splitlines() if line.strip()]
        return lines

    @staticmethod
    def extract_merchant(lines: list[str]) -> str:
        """
        Trích xuất tên cửa hàng / người bán:
        - Ưu tiên 1: Đối sánh với các chuỗi thương hiệu phổ biến
        - Ưu tiên 2: Lấy dòng đầu tiên không chứa từ khóa chung chung như 'Hóa đơn', 'Phiếu thu'
        """
        # 1. Tìm trong toàn bộ text xem có thương hiệu lớn không
        full_text_upper = "\n".join(lines).upper()
        for merchant in KNOWN_MERCHANTS:
            if merchant in full_text_upper:
                return merchant

        # 2. Duyệt 5 dòng đầu tiên
        for line in lines[:5]:
            line_lower = line.lower()
            if any(ignore in line_lower for ignore in MERCHANT_IGNORE_KEYWORDS):
                continue
            # Bỏ qua dòng chỉ toàn số hoặc ký tự đặc biệt
            clean_line = re.sub(r"[^a-zA-Z0-9À-ỹ\s]", "", line).strip()
            if len(clean_line) >= 3 and not clean_line.isdigit():
                return line.strip()

        return "Cửa hàng không xác định"

    @staticmethod
    def extract_date(raw_text: str) -> str:
        """
        Trích xuất ngày giao dịch và chuyển về định dạng chuẩn YYYY-MM-DD.
        Nếu không tìm thấy, lấy ngày hiện tại.
        """
        # Thử mẫu "ngày dd tháng mm năm yyyy"
        vn_match = re.search(r"ng[àa]y\s*(\d{1,2})\s*th[áa]ng\s*(\d{1,2})\s*n[ăa]m\s*(\d{4})", raw_text, re.IGNORECASE)
        if vn_match:
            d, m, y = vn_match.groups()
            return f"{int(y):04d}-{int(m):02d}-{int(d):02d}"

        # Thử regex DD/MM/YYYY
        date_match = re.search(r"\b(\d{1,2})[/-](\d{1,2})[/-](\d{4})\b", raw_text)
        if date_match:
            d, m, y = date_match.groups()
            # Xử lý trường hợp tháng/ngày
            d_int, m_int, y_int = int(d), int(m), int(y)
            if 1 <= d_int <= 31 and 1 <= m_int <= 12:
                return f"{y_int:04d}-{m_int:02d}-{d_int:02d}"

        # Thử regex YYYY/MM/DD
        iso_match = re.search(r"\b(\d{4})[/-](\d{1,2})[/-](\d{1,2})\b", raw_text)
        if iso_match:
            y, m, d = iso_match.groups()
            return f"{int(y):04d}-{int(m):02d}-{int(d):02d}"

        # Mặc định ngày hôm nay
        return datetime.now().strftime("%Y-%m-%d")

    @staticmethod
    def parse_amount_str(amount_str: str) -> Optional[float]:
        """Làm sạch và chuyển chuỗi tiền thành số float thực."""
        # Bỏ chữ đ, vnđ, ký tự khoảng trắng
        cleaned = re.sub(r"[^\d.,]", "", amount_str).strip()
        if not cleaned:
            return None

        # Nếu có dấu chấm hoặc dấu phẩy phân tách hàng nghìn (ví dụ: 120.000 hoặc 120,000)
        # Trong tiếng Việt thường dùng dấu chấm ngăn cách hàng nghìn
        if "." in cleaned and "," in cleaned:
            # 1.250,50 -> 1250.50
            cleaned = cleaned.replace(".", "").replace(",", ".")
        elif "." in cleaned:
            parts = cleaned.split(".")
            # Nếu phần sau dấu chấm dài 3 số -> phân cách hàng nghìn
            if all(len(p) == 3 for p in parts[1:]):
                cleaned = "".join(parts)
        elif "," in cleaned:
            parts = cleaned.split(",")
            if all(len(p) == 3 for p in parts[1:]):
                cleaned = "".join(parts)

        try:
            val = float(cleaned)
            # Lọc bỏ giá trị vô lý (quá nhỏ hoặc quá lớn)
            if 100 <= val <= 500_000_000:
                return val
        except ValueError:
            pass
        return None

    @classmethod
    def extract_total_amount(cls, lines: list[str]) -> float:
        """
        Trích xuất tổng tiền hóa đơn:
        - Quét từ khóa 'Tổng cộng', 'Thành tiền', 'Total'
        - Nếu tìm thấy dòng có từ khóa, bóc tách số tiền trong dòng hoặc dòng kế tiếp
        - Nếu không có từ khóa, lấy số tiền lớn nhất hợp lý xuất hiện ở cuối hóa đơn
        """
        candidate_amounts = []

        # 1. Quét theo từ khóa tổng tiền
        for i, line in enumerate(lines):
            line_lower = line.lower()
            for kw in TOTAL_AMOUNT_KEYWORDS:
                if re.search(kw, line_lower):
                    # Tìm số tiền trên chính dòng này
                    numbers = AMOUNT_PATTERN.findall(line)
                    for n in numbers:
                        val = cls.parse_amount_str(n)
                        if val:
                            return val

                    # Nếu không có, tìm ở 1-2 dòng kế tiếp
                    for next_idx in range(i + 1, min(i + 3, len(lines))):
                        numbers_next = AMOUNT_PATTERN.findall(lines[next_idx])
                        for n in numbers_next:
                            val = cls.parse_amount_str(n)
                            if val:
                                return val

        # 2. Quét toàn bộ các số tiền xuất hiện và lấy số hợp lệ cuối cùng/lớn nhất
        for line in lines:
            matches = AMOUNT_PATTERN.findall(line)
            for m in matches:
                val = cls.parse_amount_str(m)
                if val:
                    candidate_amounts.append(val)

        if candidate_amounts:
            # Thông thường tổng tiền là con số lớn nhất trong các dòng
            return max(candidate_amounts)

        return 0.0

    @classmethod
    def parse_all(cls, raw_text: str) -> Dict[str, Any]:
        """Hàm chính thực hiện toàn bộ luồng bóc tách."""
        lines = cls.clean_text(raw_text)

        merchant = cls.extract_merchant(lines) if lines else "Cửa hàng không xác định"
        date_str = cls.extract_date(raw_text)
        amount = cls.extract_total_amount(lines) if lines else 0.0

        return {
            "merchant_name": merchant,
            "transaction_date": date_str,
            "amount": amount,
            "raw_lines_count": len(lines),
            "status": "success"
        }
