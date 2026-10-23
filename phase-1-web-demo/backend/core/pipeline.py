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
    from ..ocr.google_mlkit_engine import GoogleMLKitEngine
    from ..extractor.regex_parser import ReceiptParser
    from ..database.db_manager import DatabaseManager
    from .config import DB_PATH
except (ImportError, ValueError):
    from ocr.ocr_engine import OCREngine
    from ocr.google_mlkit_engine import GoogleMLKitEngine
    from extractor.regex_parser import ReceiptParser
    from database.db_manager import DatabaseManager
    from core.config import DB_PATH

logger = logging.getLogger(__name__)


class ProcessingPipeline:
    """Điều phối toàn bộ quy trình từ ảnh hóa đơn tới dữ liệu cấu trúc."""

    def __init__(self):
        self.ocr_engine = OCREngine()
        self.mlkit_engine = GoogleMLKitEngine()
        self.parser = ReceiptParser()
        self.db_manager = DatabaseManager(DB_PATH)

    def process_receipt_image(self, image_path: Path, engine: str = "google_mlkit") -> Dict[str, Any]:
        """
        Thực thi quy trình Google ML Kit OCR -> Regex Parser bóc tách dữ liệu hóa đơn.
        """
        image_path = Path(image_path)
        logger.info(f"Bắt đầu Google ML Kit pipeline xử lý ảnh: {image_path}")

        ml_res = self.mlkit_engine.process_image(str(image_path))
        raw_text = ml_res.get("raw_text", "")

        response = self.parse_extracted_text(raw_text, image_url=f"/uploads/{image_path.name}")
        response["engine"] = "google_mlkit"
        return response

    def parse_extracted_text(self, raw_text: str, image_url: str = "") -> Dict[str, Any]:
        """
        Bóc tách cấu trúc hóa đơn trực tiếp từ chuỗi văn bản thô (phù hợp với Google ML Kit on-device client).
        """
        parsed_data = self.parser.parse_all(raw_text)

        response = {
            "image_url": image_url,
            "raw_text": raw_text,
            "merchant_name": parsed_data["merchant_name"],
            "hotline": parsed_data.get("hotline"),
            "address": parsed_data.get("address"),
            "transaction_date": parsed_data["transaction_date"],
            "amount": parsed_data["amount"],
            "subtotal": parsed_data.get("subtotal"),
            "discount": parsed_data.get("discount"),
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
