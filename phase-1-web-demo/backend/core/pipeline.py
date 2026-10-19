"""
Module Tích Hợp Pipeline Toàn Diện (OCR -> Regex -> Review -> Database)
Phụ trách: Thành viên 5 - Nguyễn Việt Anh
Nhiệm vụ: Kết nối các thành phần kỹ thuật, điều phối luồng dữ liệu mượt mà
"""
import logging
from typing import Dict, Any
from pathlib import Path

try:
    from ..ocr.ocr_engine import OCREngine
    from ..extractor.regex_parser import ReceiptParser
    from ..database.db_manager import DatabaseManager
    from .config import DB_PATH
except (ImportError, ValueError):
    from ocr.ocr_engine import OCREngine
    from extractor.regex_parser import ReceiptParser
    from database.db_manager import DatabaseManager
    from core.config import DB_PATH

logger = logging.getLogger(__name__)


class ProcessingPipeline:
    """Điều phối toàn bộ quy trình từ ảnh hóa đơn tới dữ liệu cấu trúc."""

    def __init__(self):
        self.ocr_engine = OCREngine()
        self.parser = ReceiptParser()
        self.db_manager = DatabaseManager(DB_PATH)

    def process_receipt_image(self, image_path: Path) -> Dict[str, Any]:
        """
        Thực thi các bước 2 & 3 trong Pipeline:
        1. Gọi OCREngine trích xuất raw text
        2. Gọi ReceiptParser bóc tách các trường Tên quán, Ngày, Tổng tiền
        """
        logger.info(f"Bắt đầu pipeline xử lý ảnh: {image_path}")

        # Bước 2: OCR
        ocr_result = self.ocr_engine.extract_text_from_file(str(image_path))
        raw_text = ocr_result.get("raw_text", "")

        # Bước 3: Regex Extractor
        parsed_data = self.parser.parse_all(raw_text)

        response = {
            "image_url": f"/uploads/{image_path.name}",
            "raw_text": raw_text,
            "merchant_name": parsed_data["merchant_name"],
            "transaction_date": parsed_data["transaction_date"],
            "amount": parsed_data["amount"],
            "notes": parsed_data.get("notes", ""),
            "breakdown": parsed_data.get("breakdown", []),
            "items": parsed_data.get("items", []),
            "status": "ready_for_review"
        }

        logger.info(f"Hoàn thành bóc tách: {response['merchant_name']} - {response['amount']} VNĐ")
        return response

    def save_verified_transaction(self, tx_payload: Dict[str, Any]) -> int:
        """
        Thực thi Bước 5: Lưu dữ liệu đã được người dùng kiểm tra trên màn hình xác thực vào CSDL
        """
        return self.db_manager.add_transaction(tx_payload)
