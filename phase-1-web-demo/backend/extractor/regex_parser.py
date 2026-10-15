"""
Bộ Phân Tích & Bóc Tách Thông Tin Hóa Đơn & Tiền Trọ Bằng Regex
Phụ trách: Thành viên 3 - Lê Tiến Quân
Nhiệm vụ: Trích xuất chính xác Tên cơ sở/Khoản chi, Ngày tháng, Tổng tiền (kể cả hóa đơn nhiều khoản tổng)
"""
import re
from datetime import datetime
from typing import Dict, Any, Optional, List, Tuple
from .rules import (
    TOTAL_AMOUNT_KEYWORDS,
    TABLE_HEADER_KEYWORDS,
    AMOUNT_PATTERN,
    FALLBACK_NUMBER_PATTERN,
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
        Trích xuất tên cửa hàng / nội dung khoản chi:
        - Nhận diện hóa đơn tiền trọ: "THÔNG BÁO TIỀN TRỌ - Phòng 801"
        - Nhận diện chuỗi cửa hàng lớn (Highlands, WinMart, Circle K,...)
        - Nhận diện dòng tiêu đề đầu tiên hợp lệ
        """
        full_text_upper = "\n".join(lines).upper()

        # Kiểm tra nếu là hóa đơn tiền trọ
        room_match = re.search(r"ph[òo]ng\s*[:\s]*(\d+)", full_text_upper, re.IGNORECASE)
        room_no = f" - Phòng {room_match.group(1)}" if room_match else ""

        if "TIEN TRO" in full_text_upper or "TIỀN TRỌ" in full_text_upper or "THONG BAO TIEN TRO" in full_text_upper:
            host_match = re.search(r"(?:HKD|STK)?\s*([A-Z\s]{3,20}\b(?:STAY|HOTEL|HOMESTAY|APARTMENT)?)", full_text_upper)
            extra = " - Simple Stay" if "SIMPLE STAY" in full_text_upper else ""
            return f"Tiền trọ{room_no}{extra}"

        # So khớp với các chuỗi thương hiệu lớn
        for merchant in KNOWN_MERCHANTS:
            if merchant in full_text_upper:
                return merchant

        # Duyệt các dòng đầu tiên để lấy tên
        for line in lines[:5]:
            line_lower = line.lower()
            if any(ignore in line_lower for ignore in MERCHANT_IGNORE_KEYWORDS):
                continue
            clean_line = re.sub(r"[^a-zA-Z0-9À-ỹ\s]", "", line).strip()
            if len(clean_line) >= 3 and not clean_line.isdigit():
                return line.strip()

        return "Khoản chi không xác định"

    @staticmethod
    def extract_date(raw_text: str) -> str:
        """Trích xuất ngày giao dịch / tháng thu tiền."""
        # 1. Thử "Tháng MM/YYYY" (ví dụ: Tháng 10/2026)
        month_match = re.search(r"th[áa]ng\s*(\d{1,2})[/-](\d{4})", raw_text, re.IGNORECASE)
        if month_match:
            m, y = month_match.groups()
            return f"{int(y):04d}-{int(m):02d}-01"

        # 2. Thử ngày tháng năm bằng chữ tiếng Việt
        vn_match = re.search(r"ng[àa]y\s*(\d{1,2})\s*th[áa]ng\s*(\d{1,2})\s*n[ăa]m\s*(\d{4})", raw_text, re.IGNORECASE)
        if vn_match:
            d, m, y = vn_match.groups()
            return f"{int(y):04d}-{int(m):02d}-{int(d):02d}"

        # 3. Thử DD/MM/YYYY
        date_match = re.search(r"\b(\d{1,2})[/-](\d{1,2})[/-](\d{4})\b", raw_text)
        if date_match:
            d, m, y = date_match.groups()
            d_int, m_int, y_int = int(d), int(m), int(y)
            if 1 <= d_int <= 31 and 1 <= m_int <= 12:
                return f"{y_int:04d}-{m_int:02d}-{d_int:02d}"

        return datetime.now().strftime("%Y-%m-%d")

    @staticmethod
    def parse_amount_str(amount_str: str) -> Optional[float]:
        """Chuyển chuỗi tiền thành float."""
        cleaned = re.sub(r"[^\d.,]", "", amount_str).strip()
        if not cleaned:
            return None

        # Xử lý dấu phân cách
        if "." in cleaned and "," in cleaned:
            cleaned = cleaned.replace(".", "").replace(",", ".")
        elif "." in cleaned:
            parts = cleaned.split(".")
            # Hàng nghìn kiểu VN (ví dụ: 3.800.000 hoặc 150.000)
            if all(len(p) == 3 for p in parts[1:]):
                cleaned = "".join(parts)
        elif "," in cleaned:
            parts = cleaned.split(",")
            if all(len(p) == 3 for p in parts[1:]):
                cleaned = "".join(parts)

        try:
            val = float(cleaned)
            # Giới hạn số tiền hợp lý: 5.000 đ đến 1 tỷ đ
            if 5_000 <= val <= 1_000_000_000:
                return val
        except ValueError:
            pass
        return None

    @classmethod
    def is_table_header(cls, line: str) -> bool:
        """Kiểm tra xem dòng có phải header bảng không (ví dụ: 'Dịch vụ | Cũ | Mới | Thành Tiền')."""
        line_lower = line.lower()
        matches = [kw for kw in TABLE_HEADER_KEYWORDS if kw in line_lower]
        # Nếu có từ 2 từ khóa bảng trở lên thì chắc chắn là header
        return len(matches) >= 2

    @classmethod
    def extract_totals_breakdown(cls, lines: list[str]) -> Tuple[float, List[Dict[str, Any]]]:
        """
        Bóc tách các dòng Tổng tiền (hỗ trợ cả hóa đơn có nhiều khoản tổng như Tiền trọ):
        - Quét từ dưới lên trên (Bottom-Up)
        - Tránh nhầm lẫn với header bảng
        - Nếu có nhiều dòng 'TỔNG TIỀN...' (ví dụ: Tổng tiền DV, Tổng tiền phòng) -> Tự động cộng dồn
        """
        sub_totals = []

        # Quét các dòng theo thứ tự từ dưới lên trên
        for i in range(len(lines) - 1, -1, -1):
            line = lines[i]
            if cls.is_table_header(line):
                continue

            line_lower = line.lower()

            for kw in TOTAL_AMOUNT_KEYWORDS:
                if re.search(kw, line_lower):
                    # Tìm các số tiền xuất hiện trên chính dòng này
                    numbers = AMOUNT_PATTERN.findall(line)
                    # Nếu pattern có dấu chấm không bắt được, thử pattern số thông thường
                    if not numbers:
                        numbers = FALLBACK_NUMBER_PATTERN.findall(line)

                    for n in numbers:
                        val = cls.parse_amount_str(n)
                        # Loại trừ các con số nhỏ như chỉ số phòng (801, 5, 28)
                        if val and val >= 50_000:
                            # Đặt tên khoản
                            label = line.split(":")[0].strip() if ":" in line else line.strip()
                            label = re.sub(r"[\d.,đ₫|]", "", label).strip()
                            if not label:
                                label = "Tổng tiền"

                            # Tránh trùng lặp số tiền đã bắt ở chính dòng đó
                            if not any(st["amount"] == val for st in sub_totals):
                                sub_totals.append({"label": label, "amount": val})
                    break

        if sub_totals:
            # Nếu có cả Tiền DV và Tiền Phòng -> Tổng = Tiền DV + Tiền Phòng
            # Hoặc nếu chỉ có 1 dòng tổng -> Lấy số đó
            total_sum = sum(item["amount"] for item in sub_totals)
            return total_sum, sub_totals

        # Dự phòng: Nếu không bắt được bằng từ khóa, lấy con số tiền lớn nhất ở nửa dưới hóa đơn
        all_amounts = []
        for line in lines[len(lines)//2:]:
            if cls.is_table_header(line):
                continue
            for match in AMOUNT_PATTERN.findall(line):
                val = cls.parse_amount_str(match)
                if val and val >= 50_000:
                    all_amounts.append(val)

        if all_amounts:
            return max(all_amounts), []

        return 0.0, []

    @classmethod
    def extract_line_items(cls, lines: list[str]) -> List[Dict[str, Any]]:
        """
        Bóc tách chi tiết từng dịch vụ / món hàng (Line Items):
        - Hỗ trợ bảng dịch vụ phòng trọ (Điện, Nước, Wifi, Máy giặt, Thang máy, Tiền phòng,...)
        - Hỗ trợ các món hàng hóa đơn thông thường (Trà sữa, Cà phê, Bánh mì, Hàng siêu thị,...)
        """
        items = []
        ignored_phrases = [
            "thông báo", "kính gửi", "bảng tính", "tháng", "dịch vụ cũ",
            "tiêu thụ", "số người", "stt", "hóa đơn", "địa chỉ", "thu ngân",
            "cảm ơn", "hẹn gặp lại", "tong tien dv", "tổng tiền dv",
            "chuyển vào stk", "chuyển stk", "hkd simple", "thành tiền"
        ]

        amt_pattern = re.compile(
            r"(\d{1,3}(?:[.,]\d{3})+|\d{5,9}|\b0\b)\s*(?:[đ₫dD]|vn[dđ])?",
            re.IGNORECASE
        )

        for line in lines:
            line_lower = line.lower().strip()

            # Nhận diện dòng Tiền Phòng
            if ("tiền phòng" in line_lower or "tien phong" in line_lower) and not any(it["name"] == "Tiền phòng" for it in items):
                matches = list(amt_pattern.finditer(line))
                if matches:
                    val = cls.parse_amount_str(matches[-1].group(1))
                    if val and val >= 100_000:
                        items.append({
                            "name": "Tiền phòng",
                            "amount": val,
                            "consumption": "1 phòng / tháng",
                            "icon": "🏠"
                        })
                continue

            # Bỏ qua các dòng tiêu đề hoặc metadata
            if any(p in line_lower for p in ignored_phrases):
                continue

            matches = list(amt_pattern.finditer(line))
            if matches:
                # Cột Thành Tiền ở bảng dịch vụ luôn là con số ở cuối dòng
                last_m = matches[-1]
                amt_val = cls.parse_amount_str(last_m.group(1))
                if amt_val is None:
                    if last_m.group(1) == "0":
                        amt_val = 0.0
                    else:
                        continue

                # Lấy tên dịch vụ (phần đứng trước số tiền)
                raw_name = line[:last_m.start()].strip()
                clean_name = re.sub(r"[|:;]", " ", raw_name).strip()
                clean_name = re.sub(r"\b\d{3,6}\b", "", clean_name).strip()
                clean_name = re.sub(r"^\d+[\.\-\)]\s*", "", clean_name).strip()

                name_lower = clean_name.lower()
                icon = "📦"
                display_name = clean_name

                # Nhận diện thông minh các dịch vụ tiền trọ & sinh hoạt
                if "điện" in name_lower or "dien" in name_lower:
                    display_name, icon = "Số điện", "⚡"
                elif "nước" in name_lower or "nuoc" in name_lower:
                    display_name, icon = "Số nước", "💧"
                elif "wi" in name_lower or "mạng" in name_lower or "internet" in name_lower:
                    display_name, icon = "Wifi", "📶"
                elif any(k in name_lower for k in ["giặt", "gặt", "giat"]):
                    display_name, icon = "Máy giặt", "🧺"
                elif any(k in name_lower for k in ["vệ sinh", "tiện chang", "ve sinh"]):
                    display_name, icon = "Vệ sinh, điện chung", "🧹"
                elif "xe" in name_lower:
                    display_name, icon = "Để xe", "🚗"
                elif "thang máy" in name_lower or "thang may" in name_lower:
                    display_name, icon = "Thang máy", "🛗"
                elif any(c in name_lower for c in ["cà phê", "cafe", "coffee", "trà", "tea"]):
                    icon = "☕"
                elif any(c in name_lower for c in ["bánh", "food", "mì", "cơm"]):
                    icon = "🍔"

                # Trích xuất chỉ số tiêu thụ nếu có
                consumption = ""
                numbers_in_line = re.findall(r"\b\d+\b", line)
                if len(numbers_in_line) >= 3 and ("điện" in name_lower or "nước" in name_lower):
                    consumption = f"Tiêu thụ: {numbers_in_line[-2]} số"

                # Tránh trùng lặp dịch vụ
                if not any(it["name"] == display_name for it in items):
                    items.append({
                        "name": display_name,
                        "amount": amt_val,
                        "consumption": consumption,
                        "icon": icon
                    })

        return items

    @classmethod
    def parse_all(cls, raw_text: str) -> Dict[str, Any]:
        """Hàm chính thực thi toàn bộ logic bóc tách."""
        lines = cls.clean_text(raw_text)

        merchant = cls.extract_merchant(lines) if lines else "Khoản chi không xác định"
        date_str = cls.extract_date(raw_text)
        total_amount, breakdown = cls.extract_totals_breakdown(lines)
        line_items = cls.extract_line_items(lines)

        # Nếu tổng tiền bằng 0 nhưng có danh sách dịch vụ chi tiết, tự tính tổng từ các món
        if total_amount == 0 and line_items:
            total_amount = sum(it["amount"] for it in line_items)

        notes_parts = []
        if breakdown:
            for item in breakdown:
                notes_parts.append(f"{item['label']}: {item['amount']:,.0f} đ")
        elif line_items:
            for item in line_items[:4]:
                notes_parts.append(f"{item['name']}: {item['amount']:,.0f} đ")

        notes = "Chi tiết: " + " + ".join(notes_parts) if notes_parts else ""

        return {
            "merchant_name": merchant,
            "transaction_date": date_str,
            "amount": total_amount,
            "breakdown": breakdown,
            "items": line_items,
            "notes": notes,
            "raw_lines_count": len(lines),
            "status": "success"
        }
