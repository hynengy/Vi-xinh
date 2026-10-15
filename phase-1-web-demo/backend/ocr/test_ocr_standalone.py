"""
=============================================================================
ĐỒ ÁN THỰC TẬP CHUYÊN MÔN - ỨNG DỤNG "VÍ XINH"
SCRIPT TEST ĐỘC LẬP CHO THÀNH VIÊN 1 - NGUYỄN THÚY HIỀN
=============================================================================
Cách sử dụng:
1. Chạy với ảnh mẫu tự động tạo:
   python -m backend.ocr.test_ocr_standalone

2. Hoặc chạy với ảnh hóa đơn của bạn:
   python -m backend.ocr.test_ocr_standalone "duong_dan_anh.jpg"
=============================================================================
"""

import sys
import os
from pathlib import Path

# Đảm bảo in tiếng Việt có dấu mượt mà trên console Windows
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")
import numpy as np
from PIL import Image, ImageDraw, ImageFont

# Thêm phase-1-web-demo vào sys.path
CURRENT_DIR = Path(__file__).resolve().parent
ROOT_DIR = CURRENT_DIR.parent.parent
sys.path.insert(0, str(ROOT_DIR))

from backend.ocr.image_preprocessing import ImagePreprocessor
from backend.ocr.ocr_engine import OCREngine


def create_synthetic_receipt(output_path: Path) -> Path:
    """Tạo một ảnh hóa đơn mẫu thực tế để kiểm thử ngay lập tức."""
    img = Image.new("RGB", (550, 750), color=(245, 243, 238))
    draw = ImageDraw.Draw(img)

    # Viết chữ mô phỏng hóa đơn
    lines = [
        ("=== HIGHLANDS COFFEE ===", 24, True),
        ("Dia chi: 298 Cau Giay, Ha Noi", 16, False),
        ("So HD: HD-20261015-099", 14, False),
        ("Ngay: 15/10/2026   Gio: 08:45", 16, False),
        ("Thu ngan: Tran Van B", 14, False),
        ("--------------------------------------------", 16, False),
        ("1. Freeze Tra Xanh (L)       65.000", 17, False),
        ("2. Phin Sua Da (M)            39.000", 17, False),
        ("3. Banh Mi Que Ga            19.000", 17, False),
        ("--------------------------------------------", 16, False),
        ("CONG TIEN HANG:             123.000 d", 18, False),
        ("VAT (8%):                     9.840 d", 16, False),
        ("TONG CONG:                  132.840 VND", 22, True),
        ("TIEN MAT:                   150.000 VND", 18, False),
        ("TIEN THUA:                   17.160 VND", 16, False),
        ("--------------------------------------------", 16, False),
        ("CAM ON QUY KHACH - HEN GAP LAI!", 16, True),
    ]

    y_pos = 40
    for text, font_size, is_bold in lines:
        try:
            font = ImageFont.truetype("arial.ttf", font_size)
        except IOError:
            font = ImageFont.load_default()
        color = (20, 20, 20) if is_bold else (60, 60, 60)
        draw.text((45, y_pos), text, fill=color, font=font)
        y_pos += font_size + 14

    output_path.parent.mkdir(parents=True, exist_ok=True)
    # Xoay nhẹ 3 độ để kiểm thử khả năng xoay thẳng (Deskew) của Thúy Hiền
    rotated = img.rotate(3.5, expand=True, fillcolor=(230, 230, 230))
    rotated.save(str(output_path))
    return output_path


def main():
    print("=" * 70)
    print("  ỨNG DỤNG 'VÍ XINH' - BÀI TEST OCR CỦA NGUYỄN THÚY HIỀN")
    print("=" * 70)

    # 1. Kiểm tra trạng thái Tesseract Engine
    engine = OCREngine()
    status = engine.get_status()
    print("\n🔍 1. KIỂM TRA MÔI TRƯỜNG OCR:")
    if status["ready"]:
        print(f"  ✅ Tesseract Engine: ĐÃ SẴN SÀNG (Phiên bản {status['version']})")
        print(f"  🌐 Ngôn ngữ hỗ trợ: {', '.join(status['languages'])}")
    else:
        print(f"  ⚠️  Tesseract Engine: Chưa kích hoạt ({status.get('reason')})")
        print(f"  💡 Hướng dẫn: {status.get('suggestion')}")

    # 2. Chuẩn bị ảnh đầu vào
    if len(sys.argv) > 1 and os.path.exists(sys.argv[1]):
        image_path = Path(sys.argv[1])
        print(f"\n📂 2. ĐANG KIỂM THỬ VỚI ẢNH NGƯỜI DÙNG: {image_path.name}")
    else:
        sample_path = ROOT_DIR.parent / "data" / "sample_receipts" / "sample_test_receipt.jpg"
        image_path = create_synthetic_receipt(sample_path)
        print(f"\n📂 2. ĐÃ TẠO ẢNH HÓA ĐƠN MẪU TỰ ĐỘNG TẠI: {image_path}")

    # 3. Chạy luồng tiền xử lý & OCR
    debug_dir = ROOT_DIR.parent / "data" / "sample_receipts" / "debug"
    print("\n⚙️  3. ĐANG THỰC THI TIỀN XỬ LÝ ẢNH & OCR...")
    result = engine.extract_text_from_file(str(image_path), save_stages_dir=str(debug_dir))

    # 4. In bảng báo cáo kết quả hiệu năng
    print("\n" + "=" * 70)
    print("📊 KẾT QUẢ ĐO ĐẠC HIỆU NĂNG (ĐƯA VÀO BÁO CÁO CỦA THÚY HIỀN):")
    print("=" * 70)
    metrics = result.get("metrics", {})
    print(f"  ⏱️  Thời gian tiền xử lý ảnh (OpenCV): {metrics.get('preprocessing_time_ms', 0)} ms")
    print(f"  ⏱️  Thời gian nhận diện OCR:          {metrics.get('ocr_time_ms', 0)} ms")
    print(f"  ⏱️  Tổng thời gian xử lý:             {metrics.get('total_time_ms', 0)} ms")
    print(f"  📐 Góc nghiêng phát hiện & xoay:      {result.get('rotation_angle', 0)} độ")
    print(f"  🎯 Điểm tin cậy (Confidence Score):   {result.get('confidence_score', 0)} %")
    print(f"  📦 Số lượng từ / khung nhận diện:     {result.get('boxes_count', 0)} từ")

    print("\n" + "-" * 70)
    print("📜 VĂN BẢN THÔ (RAW TEXT) TRÍCH XUẤT ĐƯỢC:")
    print("-" * 70)
    print(result.get("raw_text") or "(Chưa có text)")
    print("-" * 70)

    print(f"\n💾 Đã lưu các ảnh từng bước tiền xử lý vào: {debug_dir}")
    print("=" * 70)
    print("🎉 HOÀN TẤT THỬ NGHIỆM CHO THÀNH VIÊN 1 - NGUYỄN THÚY HIỀN!")
    print("=" * 70)


if __name__ == "__main__":
    main()
