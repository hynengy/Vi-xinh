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
    total, breakdown = ReceiptParser.extract_totals_breakdown(lines)
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


def test_extract_merchant_room_rent():
    """Test nhận diện hóa đơn tiền trọ."""
    raw_text = """
    THÔNG BÁO TIỀN TRỌ
    Phòng: 801
    Tháng 10/2026
    Tiền phòng: 3.800.000
    Điện: 150.000
    Nước: 80.000
    Tổng tiền: 4.030.000 đ
    """
    lines = ReceiptParser.clean_text(raw_text)
    merchant = ReceiptParser.extract_merchant(lines)
    assert "Tiền trọ" in merchant
    assert "801" in merchant


def test_extract_date_month_format():
    """Test nhận diện format Tháng MM/YYYY."""
    raw_text = "Thông báo tiền trọ\nTháng 10/2026\nPhòng 302"
    date_str = ReceiptParser.extract_date(raw_text)
    assert date_str == "2026-10-01"


def test_extract_line_items_room_services():
    """Test bóc tách dịch vụ phòng trọ."""
    raw_text = """
    THÔNG BÁO TIỀN TRỌ - Phòng 302
    Tiền phòng: 3.800.000
    Điện | 100 | 150 | 50 | 250.000
    Nước | 20 | 28 | 8 | 120.000
    Wifi: 100.000
    Tổng tiền: 4.270.000 đ
    """
    lines = ReceiptParser.clean_text(raw_text)
    items = ReceiptParser.extract_line_items(lines)
    # Phải có ít nhất tiền phòng, điện, nước, wifi
    item_names = [it["name"] for it in items]
    assert "Tiền phòng" in item_names
    assert any("điện" in n.lower() or "Số điện" in n for n in item_names)


def test_pipeline_real_receipt_ocr():
    """Test kết nối toàn diện Pipeline: OpenCV Preprocessing -> Tesseract OCR -> Regex Extractor."""
    from backend.core.pipeline import ProcessingPipeline
    sample_img = Path(__file__).resolve().parent.parent / "data" / "sample_receipts" / "sample_test_receipt.jpg"
    if sample_img.exists():
        pipeline = ProcessingPipeline()
        result = pipeline.process_receipt_image(sample_img)
        assert result["status"] == "ready_for_review"
        assert result["merchant_name"] == "HIGHLANDS COFFEE"
        assert result["amount"] == 132840.0
        assert "HIGHLANDS" in result["raw_text"]

