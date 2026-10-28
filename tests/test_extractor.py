"""
Unit Test Cho Bộ Bóc Tách Regex (Extractor)
Phụ trách: Thành viên 4 (Lê Ngọc Duy) & Toàn nhóm kiểm thử
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
    sample_text = """
    WINMART+
    Dia chi: 123 Nguyen Trai, Ha Noi
    Ngay: 14/10/2026
    Banh mi: 20.000
    Sua chua: 15.000
    THANH TIEN: 35.000 VND
    Xin cam on quy khach!
    """
    result = ReceiptParser.parse_all(sample_text)
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


def test_extract_compound_room_rent_bill():
    """Test bóc tách hóa đơn tiền trọ có 2 phần tổng tiền: Tổng tiền DV + Tổng tiền phòng."""
    sample_bill = """
    THÔNG BÁO TIỀN TRỌ
    Tháng 10/2026
    Kính gửi phòng: 801
    Bảng tính tiền điện nước của tháng trước và tiền phòng, dịch vụ của tháng tới

    Dịch vụ | Cũ | Mới | Tiêu thụ | Thành Tiền
    Số điện | 17247 | 17738 | 491 | 1.865.800 đ
    Số nước | 1107 | 1135 | 28 | 650.000 đ
    Số người
    Wifi | 100.000 đ | TIỀN DỊCH VỤ CHUYỂN VÀO STK HỒNG NHUNG
    Máy giặt | 350.000 đ
    Vệ sinh, điện chung | 5 | 150.000 đ
    Để xe | 0 đ
    Thang máy | 250.000 đ
    TỔNG TIỀN DV | 3.365.800 đ
    TỔNG TIỀN PHÒNG | 3.800.000 đ | TIỀN PHÒNG CHUYỂN STK HKD SIMPLE STAY
    """
    res = ReceiptParser.parse_all(sample_bill)
    assert res["amount"] == 7165800.0  # 3.365.800 (DV) + 3.800.000 (Phòng)
    assert res["subtotal"] == 7165800.0
    assert len(res["items"]) >= 7
    item_names = [it["name"] for it in res["items"]]
    assert "Tiền phòng" in item_names
    assert "Wifi" in item_names
    assert "Thang máy" in item_names
    assert any("Để xe" in n or "xe" in n.lower() for n in item_names)
    assert any(b["label"] == "Tổng tiền dịch vụ" and b["amount"] == 3365800.0 for b in res["breakdown"])
    assert any(b["label"] == "Tổng tiền phòng" and b["amount"] == 3800000.0 for b in res["breakdown"])



def test_pipeline_real_receipt_extraction():
    """Test kết nối toàn diện Pipeline: Image Preprocessing -> Multimodal LLM Extraction -> Structure Parser."""
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
        assert result["transaction_date"] in ("2026-10-22", "2023-10-22")


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
    Tạm tính: 300.000 đ
    Giảm giá: 30.000 đ
    Tổng cộng: 270.000 đ
    """
    res = ReceiptParser.parse_all(raw_text)
    assert res["amount"] == 270000.0
    assert res.get("discount") == 30000.0
    assert res.get("subtotal") == 300000.0


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


def test_llm_gemini_extractor():
    """Kiểm tra Module backend.llm và class ReceiptLLMExtractor (Hướng 3)."""
    from backend.llm.gemini_extractor import ReceiptLLMExtractor, GoogleMLKitEngine
    from backend.core.pipeline import ProcessingPipeline

    extractor = ReceiptLLMExtractor()
    assert extractor is not None
    info = extractor.get_engine_info()
    assert info["web_client_available"] is True

    pipe = ProcessingPipeline()
    assert pipe.llm_engine is not None
    assert pipe.mlkit_engine is not None


def test_received_cash_not_included_in_total_or_items():
    """Kiểm tra hóa đơn có 'Tiền đã nhận' không bị cộng vào tổng tiền và không bị coi là món ăn."""
    raw_text = """
    PHÚC LONG COFFEE & TEA
    1. Trà đào cam sả    55.000
    2. Bánh croissant     30.000
    ---------------------------------
    Tổng cộng: 85.000 đ
    Tiền đã nhận: 100.000 đ
    Tiền trả lại: 15.000 đ
    """
    res = ReceiptParser.parse_all(raw_text)
    assert res["amount"] == 85000.0
    item_names = [it["name"].lower() for it in res["items"]]
    assert not any("tiền đã nhận" in n or "đã nhận" in n for n in item_names)
    assert not any("tiền trả lại" in n or "trả lại" in n for n in item_names)
    assert len(res["items"]) == 2


def test_kiotviet_42k_sample_receipt():
    """Kiểm tra hóa đơn mẫu KiotViet 42k không bị tính số HĐ, ngày giờ, header bảng vào món ăn."""
    sample_path = Path(__file__).resolve().parent.parent / "data" / "sample_receipts" / "receipt_kiotviet_42k.ocr.txt"
    raw_text = sample_path.read_text(encoding="utf-8")
    res = ReceiptParser.parse_all(raw_text)

    assert res["amount"] == 42000.0
    assert res["invoice_no"] == "HD729652"
    assert res["transaction_date"] == "2026-10-22"
    assert res["transaction_time"] == "14:02"

    item_names = [it["name"].lower() for it in res["items"]]
    for bad_kw in ["hđ", "hd729652", "ngày", "22/10/2026", "14:02", "khách hàng", "khách lẻ", "tên hàng", "kiotviet", "cảm ơn"]:
        assert not any(bad_kw in n for n in item_names), f"Found metadata '{bad_kw}' in items: {item_names}"

    total_items_amount = sum(it["amount"] for it in res["items"])
    assert total_items_amount == 40000.0


def test_cafe_receipt_ignores_wifi_pass_phone_date_time():
    """Kiểm tra hóa đơn quán cafe có wifi, mật khẩu, hotline, ngày giờ không bị parse thành món ăn hay tổng tiền."""
    raw_text = """
    THE COFFEE HOUSE
    Wifi: TheCoffeeHouse
    Pass: 12345678
    Hotline: 0912.888.999
    Ngày: 24/10/2026 15:30
    Bàn số: 05
    Thu ngân: Linh
    1. Trà đào cam sả 55.000
    2. Cà phê sữa đá 45.000
    Tổng thanh toán: 100.000
    Tiền đã nhận: 200.000
    Tiền thối lại: 100.000
    Cảm ơn và hẹn gặp lại!
    """
    res = ReceiptParser.parse_all(raw_text)
    assert res["amount"] == 100000.0
    assert res["hotline"] == "0912.888.999"
    assert res["transaction_date"] == "2026-10-24"
    assert res["transaction_time"] == "15:30"

    item_names = [it["name"].lower() for it in res["items"]]
    for bad in ["wifi", "pass", "12345678", "0912", "hotline", "ngày", "24/10/2026", "15:30", "bàn", "thu ngân", "tiền đã nhận", "tiền thối", "cảm ơn"]:
        assert not any(bad in n for n in item_names), f"Found '{bad}' in item names: {item_names}"

    assert len(res["items"]) == 2
    assert res["items"][0]["amount"] == 55000.0
    assert res["items"][1]["amount"] == 45000.0





