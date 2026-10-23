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


def test_pipeline_restaurant_vip_receipt():
    """Test bóc tách hóa đơn nhà hàng hải sản bàn VIP 2 trị giá 50.662.000 đ."""
    from backend.core.pipeline import ProcessingPipeline
    sample_img = Path(__file__).resolve().parent.parent / "data" / "sample_receipts" / "receipt_restaurant_50m.jpg"
    if sample_img.exists():
        pipeline = ProcessingPipeline()
        result = pipeline.process_receipt_image(sample_img)
        assert result["status"] == "ready_for_review"
        assert result["amount"] == 50662000.0
        assert "Nhà Hàng Hải Sản" in result["merchant_name"]
        assert result["transaction_date"] == "2026-06-18"


def test_pipeline_kiotviet_stained_receipt():
    """Test bóc tách hóa đơn in nhiệt KiotViet bị ố vàng trị giá 42.000 đ."""
    from backend.core.pipeline import ProcessingPipeline
    sample_img = Path(__file__).resolve().parent.parent / "data" / "sample_receipts" / "receipt_kiotviet_42k.jpg"
    if sample_img.exists():
        pipeline = ProcessingPipeline()
        result = pipeline.process_receipt_image(sample_img)
        assert result["status"] == "ready_for_review"
        assert result["amount"] == 42000.0
        assert "KiotViet" in result["merchant_name"]
        assert result["transaction_date"] == "2026-10-22"


def test_extract_hotline_and_address():
    """Test bóc tách Hotline, Địa chỉ và không bị nhầm Hotline thành số tiền."""
    raw_text = """
    NHÀ HÀNG HƯƠNG BIỂN
    ĐC: 123 Đường Bờ Biển, Phường Mỹ Khê, Đà Nẵng
    Hotline: 0912.345.678 - Tel: 0236.3888.999
    MST: 0401234567
    Ngày: 20/10/2026
    1. Cơm chiên hải sản   120.000
    2. Canh ngao chua       80.000
    TỔNG TIỀN: 200.000 đ
    Cảm ơn quý khách!
    """
    res = ReceiptParser.parse_all(raw_text)
    assert "HƯƠNG BIỂN" in res["merchant_name"].upper()
    assert res["hotline"] is not None and "0912" in res["hotline"]
    assert res["address"] is not None and "123 Đường Bờ Biển" in res["address"]
    # Số tiền phải là 200.000 chứ KHÔNG ĐƯỢC là hotline 912.345.678!
    assert res["amount"] == 200000.0
    assert len(res["items"]) >= 2
    item_names = [it["name"] for it in res["items"]]
    assert any("Cơm chiên" in n for n in item_names)
    assert any("Canh ngao" in n for n in item_names)


def test_extract_dishes_and_prices_vietnamese_cafe():
    """Test bóc tách đồ ăn đồ uống tiếng Việt phổ biến."""
    raw_text = """
    TIỆM TRÀ SỮA & ĂN VẶT CHILL
    SĐT: 0988.777.666
    Ngày: 22/10/2026
    1. Trà sữa trân châu đường đen    35.000
    2. Cà phê sữa đá phin             25.000
    3. Khoai tây lắc phô mai          30.000
    Tổng thanh toán: 90.000 đ
    """
    res = ReceiptParser.parse_all(raw_text)
    assert "TIỆM TRÀ SỮA" in res["merchant_name"].upper()
    assert res["amount"] == 90000.0
    assert len(res["items"]) == 3
    assert res["items"][0]["amount"] == 35000.0
    assert res["items"][1]["amount"] == 25000.0
    assert res["items"][2]["amount"] == 30000.0
    # Icon nhận diện chuẩn
    assert res["items"][0]["icon"] in ["🧋", "🍵", "☕"]
    assert res["items"][1]["icon"] == "☕"
    assert res["items"][2]["icon"] in ["🍟", "🍢"]


def test_extract_discount_and_subtotal():
    """Test bóc tách giảm giá, chiết khấu, voucher và số tiền thanh toán thực tế."""
    raw_text = """
    PIZZA 4P'S HÀ NỘI
    ĐC: 43 Tràng Tiền, Hoàn Kiếm, Hà Nội
    Hotline: 028 3622 0500
    Ngày: 23/10/2026 19:45
    1. Pizza 4 Cheese          280.000
    2. Mì Ý cua sốt kem        220.000
    Tổng tiền hàng:            500.000 đ
    Giảm giá voucher:           50.000 đ
    Khách phải trả:            450.000 đ
    Tiền mặt:                  500.000 đ
    Tiền thừa:                  50.000 đ
    """
    res = ReceiptParser.parse_all(raw_text)
    assert res["amount"] == 450000.0  # Phải là tiền khách phải trả thực tế sau giảm giá
    assert res["subtotal"] == 500000.0
    assert res["discount"] == 50000.0
    assert res["hotline"] is not None and "028" in res["hotline"]
    assert len(res["items"]) >= 2


def test_two_line_pos_receipt_kiotviet():
    """Test bóc tách hóa đơn in nhiệt dạng 2 dòng (dòng 1 tên món, dòng 2 đơn giá & thành tiền)."""
    raw_text = """
    TẠP HÓA HOÀNG GIA
    Hotline: 0987.654.321
    Giờ vào: 20:04   Giờ ra: 20:15
    Bánh Chocopie Hộp 12 cái
    1   60.000   60.000
    Sữa Tươi Tiệt Trùng Vinamilk 1L
    2   36.000   72.000
    Cộng tiền hàng: 132.000
    Chiết khấu thành viên 10%: 13.200
    Tổng thanh toán: 118.800 đ
    """
    res = ReceiptParser.parse_all(raw_text)
    assert res["amount"] == 118800.0
    assert res["subtotal"] == 132000.0
    assert res["discount"] == 13200.0
    assert len(res["items"]) == 2
    item_names = [it["name"] for it in res["items"]]
    assert any("Chocopie" in n for n in item_names)
    assert any("Vinamilk" in n for n in item_names)
    # Tuyệt đối không được coi giờ ra/vào thành món ăn
    assert not any("20:04" in n or "20:15" in n for n in item_names)
    assert not any("Giờ vào" in n or "Giờ ra" in n for n in item_names)


def test_ignore_time_and_hotline_as_prices():
    """Test đảm bảo giờ phút (21:20, 14:35) và số điện thoại không bị nhầm thành giá tiền."""
    assert ReceiptParser.parse_amount_str("21:20") is None
    assert ReceiptParser.parse_amount_str("20:04") is None
    assert ReceiptParser.parse_amount_str("0912345678") is None
    assert ReceiptParser.parse_amount_str("024.3822.9999") is None


def test_google_mlkit_engine_and_parse_text():
    """Test mô hình Google ML Kit Engine và API bóc tách trực tiếp chuỗi text."""
    from backend.ocr.google_mlkit_engine import GoogleMLKitEngine
    from backend.core.pipeline import ProcessingPipeline

    ml_engine = GoogleMLKitEngine()
    info = ml_engine.get_engine_info()
    assert "Google ML Kit" in info["name"]
    assert info["web_client_available"] is True

    pipeline = ProcessingPipeline()
    sample_mlkit_text = """
    PHÚC LONG COFFEE & TEA
    Hotline: 1800 6779
    Ngày: 22/10/2026
    1. Trà Sữa Phúc Long     50.000
    2. Trà Đào Cam Sả        55.000
    Cộng tiền: 105.000
    Khuyến mãi: 10.000
    TỔNG THANH TOÁN: 95.000 VNĐ
    """
    result = pipeline.parse_extracted_text(sample_mlkit_text, image_url="/uploads/mlkit_sample.jpg")
    assert result["status"] == "ready_for_review"
    assert "PHÚC LONG" in result["merchant_name"].upper()
    assert result["amount"] == 95000.0
    assert result["subtotal"] == 105000.0
    assert result["discount"] == 10000.0
    assert len(result["items"]) == 2


def test_extract_time_and_invoice_no():
    """Test bóc tách giờ giao dịch và số hóa đơn / số bill."""
    raw_text = """
    HIGHLANDS COFFEE
    Số HĐ: HD729652
    Ngày: 22/10/2026 14:35:10
    Thu ngân: Thu Thảo
    Bàn số: T02
    1. Freeze Trà Xanh    55.000
    Tổng cộng: 55.000 đ
    """
    res = ReceiptParser.parse_all(raw_text)
    assert res["invoice_no"] == "HD729652"
    assert res["transaction_time"] is not None
    assert "14:35" in res["transaction_time"]
    assert res["cashier"] == "Thu Thảo"
    assert res["table_no"] == "T02"


def test_extract_granular_items_quantity_unit_price():
    """Test bóc tách chi tiết: tên sản phẩm, số lượng, đơn giá, thành tiền."""
    raw_text = """
    TẠP HÓA AN NHIÊN
    ĐC: 45 Nguyễn Huệ, Quận 1, TP.HCM
    Hotline: 0903.111.222
    Số bill: 00458
    Giờ vào: 09:15
    1. Trà sữa trân châu 2 x 35.000    70.000
    2. Cà phê đen đá                    20.000
    VAT 10%: 9.000
    Tổng thanh toán: 99.000 đ
    Hình thức: Chuyển khoản
    """
    res = ReceiptParser.parse_all(raw_text)
    assert res["invoice_no"] == "00458"
    assert res["transaction_time"] == "09:15"
    assert res["hotline"] is not None and "0903" in res["hotline"]
    assert res["address"] is not None and "Nguyễn Huệ" in res["address"]
    assert res["vat"] == 9000.0
    assert res["payment_method"] == "Chuyển khoản"
    assert res["amount"] == 99000.0

    items = res["items"]
    assert len(items) == 2
    # Item 1: Trà sữa
    assert "Trà sữa" in items[0]["name"]
    assert items[0]["quantity"] == 2.0
    assert items[0]["unit_price"] == 35000.0
    assert items[0]["amount"] == 70000.0
    assert "SL: 2" in items[0]["consumption"]

    # Item 2: Cà phê
    assert "Cà phê" in items[1]["name"]
    assert items[1]["quantity"] == 1.0
    assert items[1]["unit_price"] == 20000.0
    assert items[1]["amount"] == 20000.0


