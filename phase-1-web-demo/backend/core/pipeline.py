"""
Module Tích Hợp Pipeline Toàn Diện (Multimodal LLM -> Validation -> Review -> Database)
Phụ trách: Thành viên 5 - Nguyễn Việt Anh
Nhiệm vụ: Kết nối các thành phần kỹ thuật, điều phối luồng dữ liệu trích xuất LLM mượt mà
"""
import logging
from typing import Dict, Any
from pathlib import Path

try:
    from ..llm.gemini_extractor import ReceiptLLMExtractor, GoogleMLKitEngine
    from ..extractor.regex_parser import ReceiptParser
    from ..database.db_manager import DatabaseManager
    from .config import DB_PATH
except (ImportError, ValueError):
    from llm.gemini_extractor import ReceiptLLMExtractor, GoogleMLKitEngine
    from extractor.regex_parser import ReceiptParser
    from database.db_manager import DatabaseManager
    from core.config import DB_PATH

logger = logging.getLogger(__name__)


class ProcessingPipeline:
    """Điều phối toàn bộ quy trình từ ảnh hóa đơn tới dữ liệu cấu trúc bằng Multimodal LLM."""

    def __init__(self):
        self.llm_engine = ReceiptLLMExtractor()
        self.mlkit_engine = self.llm_engine  # Alias tương thích ngược
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
        response["success"] = ml_res.get("success", True)
        if not ml_res.get("success"):
            response["error"] = ml_res.get("error", "Lỗi nhận dạng ảnh")
            response["error_code"] = ml_res.get("error_code", "ocr_error")
        response["engine"] = ml_res.get("engine", "google_vision_cloud")
        response["engine_note"] = ml_res.get("engine_note", "") or ml_res.get("error", "")
        response["model_name"] = ml_res.get("model_name", "Gemini 1.5 Flash")
        response["token_usage"] = ml_res.get("token_usage", {})
        response["cost_estimate"] = ml_res.get("cost_estimate", {})
        response["latency_ms"] = ml_res.get("latency_ms", ml_res.get("execution_time_ms", 0))
        response["has_vie_lang"] = ml_res.get("has_vie_lang", True)
        response["is_cloud"] = ml_res.get("is_cloud", True)
        response["confidence"] = ml_res.get("confidence", 0.0)
        response["confidence_score"] = ml_res.get("confidence_score", response["confidence"])
        response["boxes_count"] = ml_res.get("boxes_count", 0)
        response["total_lines"] = ml_res.get("total_lines", len([ln for ln in raw_text.splitlines() if ln.strip()]))
        response["execution_time_ms"] = ml_res.get("execution_time_ms", 0)
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
            "phone": parsed_data.get("phone"),
            "address": parsed_data.get("address"),
            "invoice_no": parsed_data.get("invoice_no"),
            "transaction_date": parsed_data["transaction_date"],
            "transaction_time": parsed_data.get("transaction_time"),
            "amount": parsed_data["amount"],
            "subtotal": parsed_data.get("subtotal"),
            "discount": parsed_data.get("discount"),
            "vat": parsed_data.get("vat", 0.0),
            "payment_method": parsed_data.get("payment_method"),
            "cashier": parsed_data.get("cashier"),
            "table_no": parsed_data.get("table_no"),
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
