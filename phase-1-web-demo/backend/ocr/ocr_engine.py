"""
Module OCR Engine
Phụ trách: Thành viên 1 - Nguyễn Thúy Hiền
Nhiệm vụ: Gọi mô hình OCR trích xuất văn bản thô (raw text) từ ảnh hóa đơn đã qua tiền xử lý
"""
import os
import logging
from typing import Dict, Any
import numpy as np

# Thử import pytesseract, nếu chưa có môi trường tesseract binary thì cung cấp chế độ dự phòng
try:
    import pytesseract
    from PIL import Image
    HAS_PYTESSERACT = True
except ImportError:
    HAS_PYTESSERACT = False

from .image_preprocessing import ImagePreprocessor

logger = logging.getLogger(__name__)


class OCREngine:
    """Bộ chuyển đổi ảnh hóa đơn sang văn bản thô (Optical Character Recognition)."""

    def __init__(self, tesseract_cmd: str = None, lang: str = "vie+eng"):
        self.lang = lang
        if tesseract_cmd and HAS_PYTESSERACT:
            pytesseract.pytesseract.tesseract_cmd = tesseract_cmd
        elif HAS_PYTESSERACT and os.name == 'nt':
            # Kiểm tra các đường dẫn mặc định trên Windows nếu có
            default_win_path = r"C:\Program Files\Tesseract-OCR\tesseract.exe"
            if os.path.exists(default_win_path):
                pytesseract.pytesseract.tesseract_cmd = default_win_path

    def extract_text_from_file(self, image_path: str) -> Dict[str, Any]:
        """
        Nhận diện văn bản từ file ảnh:
        1. Tiền xử lý ảnh (Deskew, Thresh)
        2. Chạy OCR
        3. Trả về raw text và metadata
        """
        try:
            # 1. Tiền xử lý
            processed_img = ImagePreprocessor.preprocess_pipeline(image_path)

            # 2. Gọi OCR
            if HAS_PYTESSERACT:
                try:
                    raw_text = pytesseract.image_to_string(processed_img, lang=self.lang)
                except Exception as tesseract_err:
                    logger.warning(f"Lỗi gọi Tesseract binary: {tesseract_err}. Thử fallback chế độ tiếng Anh/mặc định.")
                    raw_text = pytesseract.image_to_string(processed_img)
            else:
                raw_text = "[CHƯA CÀI TESSERACT] Vui lòng cài đặt thư viện pytesseract hoặc Tesseract OCR engine trên máy."

            return {
                "success": True,
                "raw_text": raw_text.strip(),
                "image_path": str(image_path)
            }
        except Exception as e:
            logger.error(f"Lỗi xử lý OCR: {e}")
            return {
                "success": False,
                "raw_text": "",
                "error": str(e),
                "image_path": str(image_path)
            }
