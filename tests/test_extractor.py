"""
Unit Test Cho Bộ Bóc Tách Regex (Extractor)
Phụ trách: Thành viên 3 (Lê Tiến Quân) & Toàn nhóm kiểm thử
"""
import pytest
import sys
from pathlib import Path

# Thêm đường dẫn backend vào sys.path
BASE_DIR = Path(__file__).resolve().parent.parent / "phase-1-web-demo"
sys.path.insert(0, str(BASE_DIR))

from backend.extractor.regex_parser import ReceiptParser


def test_extract_merchant_known_chain():
    raw_text = """
    CIRCLE K VIET NAM
    CUA HANG SO 123
    NGAY: 12/10/2026
    TONG TIEN: 75.000 VND
    """
    lines = ReceiptParser.clean_text(raw_text)
    merchant = ReceiptParser.extract_merchant(lines)
    assert merchant == "CIRCLE K"


def test_extract_date_dd_mm_yyyy():
    raw_text = "Hoa don ban le\nNgay: 25/12/2026 14:30\nTong cong: 150.000 d"
    date_str = ReceiptParser.extract_date(raw_text)
    assert date_str == "2026-12-25"


def test_extract_date_vn_words():
    raw_text = "Hà Nội, Ngày 05 tháng 11 năm 2026\nCửa hàng tiện lợi"
    date_str = ReceiptParser.extract_date(raw_text)
    assert date_str == "2026-11-05"


def test_extract_total_amount_with_keyword():
    raw_text = """
    HIGHLANDS COFFEE
    1. Freeze Tra Xanh   55.000
    2. Ca Phe Sua Da     45.000
    Tong Cong: 100.000 VND
    Tien mat: 100.000
    """
    lines = ReceiptParser.clean_text(raw_text)
    total = ReceiptParser.extract_total_amount(lines)
    assert total == 100000.0


def test_extract_total_amount_with_dots_and_commas():
    assert ReceiptParser.parse_amount_str("150.000 đ") == 150000.0
    assert ReceiptParser.parse_amount_str("245,000 VND") == 245000.0
    assert ReceiptParser.parse_amount_str("50000") == 50000.0


def test_parse_all_full_flow():
    sample_ocr = """
    WINMART+
    Dia chi: 123 Nguyen Trai, Ha Noi
    Ngay: 14/10/2026
    Banh mi: 20.000
    Sua chua: 15.000
    THANH TIEN: 35.000 VND
    Xin cam on quy khach!
    """
    result = ReceiptParser.parse_all(sample_ocr)
    assert result["merchant_name"] == "WINMART+"
    assert result["transaction_date"] == "2026-10-14"
    assert result["amount"] == 35000.0
