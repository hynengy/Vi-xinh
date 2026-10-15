"""
=============================================================================
ĐỒ ÁN THỰC TẬP CHUYÊN MÔN - ỨNG DỤNG "VÍ XINH"
MODULE: MÔ HÌNH NHẬN DẠNG QUANG HỌC KÝ TỰ (OCR ENGINE)
PHỤ TRÁCH: THÀNH VIÊN 1 - NGUYỄN THÚY HIỀN
=============================================================================
Mô tả nhiệm vụ:
- Tích hợp công cụ Tesseract OCR vào luồng xử lý Web Demo (Giai đoạn 1).
- Trích xuất văn bản thô (Raw text), tọa độ từng dòng (Bounding Box) và Điểm tin cậy (Confidence).
- Đo đạc thời gian xử lý (Processing time) phục vụ báo cáo hiệu năng.
=============================================================================
"""

import os
import time
import logging
from typing import Dict, Any, List, Optional
import numpy as np

try:
    import pytesseract
    from pytesseract import Output
    HAS_PYTESSERACT = True
except ImportError:
    HAS_PYTESSERACT = False

from .image_preprocessing import ImagePreprocessor

logger = logging.getLogger(__name__)


class OCREngine:
    """Wrapper quản lý và thực thi mô hình nhận dạng văn bản (OCR)."""

    def __init__(self, tesseract_cmd: Optional[str] = None, lang: str = "vie+eng"):
        self.lang = lang
        self.is_configured = False
        self._configure_tesseract(tesseract_cmd)

    def _configure_tesseract(self, custom_cmd: Optional[str] = None) -> None:
        """Tự động tìm kiếm đường dẫn Tesseract trên Windows hoặc Linux/macOS."""
        if not HAS_PYTESSERACT:
            logger.warning("Thư viện pytesseract chưa được cài đặt!")
            return

        if custom_cmd and os.path.exists(custom_cmd):
            pytesseract.pytesseract.tesseract_cmd = custom_cmd
            self.is_configured = True
            return

        # Các đường dẫn phổ biến trên Windows
        candidate_paths = [
            r"C:\Program Files\Tesseract-OCR\tesseract.exe",
            r"C:\Program Files (x86)\Tesseract-OCR\tesseract.exe",
            os.path.expanduser(r"~\AppData\Local\Programs\Tesseract-OCR\tesseract.exe")
        ]

        for path in candidate_paths:
            if os.path.exists(path):
                pytesseract.pytesseract.tesseract_cmd = path
                self.is_configured = True
                logger.info(f"Đã phát hiện Tesseract tại: {path}")
                return

        # Kiểm tra nếu đã có sẵn trong PATH hệ thống
        try:
            pytesseract.get_tesseract_version()
            self.is_configured = True
        except Exception:
            self.is_configured = False
            logger.warning(
                "Chưa phát hiện file tesseract.exe trên máy. "
                "Ứng dụng sẽ hoạt động ở chế độ chẩn đoán / mô phỏng an toàn."
            )

    def get_status(self) -> Dict[str, Any]:
        """Kiểm tra tình trạng cấu hình Tesseract."""
        if not HAS_PYTESSERACT:
            return {"ready": False, "reason": "pytesseract not installed"}
        try:
            ver = str(pytesseract.get_tesseract_version())
            langs = pytesseract.get_languages()
            return {
                "ready": True,
                "version": ver,
                "languages": langs,
                "tesseract_cmd": pytesseract.pytesseract.tesseract_cmd
            }
        except Exception as e:
            return {
                "ready": False,
                "reason": str(e),
                "suggestion": "Vui lòng cài đặt Tesseract OCR Windows từ https://github.com/UB-Mannheim/tesseract/wiki"
            }

    def extract_text_from_file(
        self, image_path: str, save_stages_dir: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Nhận diện văn bản từ ảnh hóa đơn:
        1. Chạy luồng tiền xử lý (Deskew, Shadow Removal, CLAHE, Binarization)
        2. Đo thời gian tiền xử lý
        3. Thực thi OCR và trích xuất raw text + bounding boxes + confidence
        4. Đo thời gian OCR
        """
        start_total = time.time()
        start_pre = time.time()

        try:
            # 1. Tiền xử lý ảnh
            stages = ImagePreprocessor.full_pipeline(image_path, save_stages_dir=save_stages_dir)
            gray_img = stages["gray"]
            binary_img = stages["final_binary"]
            pre_time_ms = round((time.time() - start_pre) * 1000, 2)

            start_ocr = time.time()
            raw_text = ""
            confidences = []
            boxes = []

            # 2. Gọi OCR Engine (Dùng PSM 3 tự động nhận dạng bố cục bảng biểu / hóa đơn)
            if self.is_configured:
                # PSM 3: Fully automatic page segmentation (chuẩn cho hóa đơn, bảng biểu)
                custom_config = r"--oem 3 --psm 3"

                try:
                    # Tesseract hoạt động tốt nhất trên ảnh Grayscale vì nó tự có thuật toán Otsu nội bộ
                    raw_text = pytesseract.image_to_string(gray_img, lang=self.lang, config=custom_config).strip()
                    target_img = gray_img
                except Exception as lang_err:
                    logger.warning(f"Thử lại với tiếng Anh/mặc định do: {lang_err}")
                    raw_text = pytesseract.image_to_string(gray_img).strip()
                    target_img = gray_img

                # Nếu ảnh xám đọc được quá ít chữ (dưới 15 ký tự), thử ảnh nhị phân
                if len(raw_text) < 15:
                    try:
                        text_bin = pytesseract.image_to_string(binary_img, lang=self.lang, config=custom_config).strip()
                        if len(text_bin) > len(raw_text):
                            raw_text = text_bin
                            target_img = binary_img
                    except Exception:
                        pass

                # Lấy chi tiết bounding boxes
                try:
                    data = pytesseract.image_to_data(
                        target_img,
                        lang=self.lang,
                        config=custom_config,
                        output_type=Output.DICT
                    )
                    n_boxes = len(data["text"])
                    for i in range(n_boxes):
                        t = data["text"][i].strip()
                        c = int(data["conf"][i])
                        if t and c > 0:
                            confidences.append(c)
                            boxes.append({
                                "text": t,
                                "x": data["left"][i],
                                "y": data["top"][i],
                                "w": data["width"][i],
                                "h": data["height"][i],
                                "confidence": c
                            })
                except Exception:
                    pass
            else:
                raw_text = (
                    "[TESSERACT CHƯA ĐƯỢC CÀI ĐẶT TRÊN MÁY]\n"
                    "Thành viên 1 (Thúy Hiền): Hãy tải bộ cài Tesseract OCR Windows để hoàn tất tích hợp:\n"
                    "https://github.com/UB-Mannheim/tesseract/wiki\n"
                    "(Đã hoàn thiện đầy đủ mã nguồn OpenCV tiền xử lý ảnh)."
                )

            ocr_time_ms = round((time.time() - start_ocr) * 1000, 2)
            total_time_ms = round((time.time() - start_total) * 1000, 2)
            avg_confidence = round(sum(confidences) / len(confidences), 2) if confidences else 0.0

            return {
                "success": True,
                "raw_text": raw_text,
                "rotation_angle": stages["rotation_angle"],
                "confidence_score": avg_confidence,
                "boxes_count": len(boxes),
                "boxes": boxes[:30], # Lấy 30 khung từ đầu tiên
                "metrics": {
                    "preprocessing_time_ms": pre_time_ms,
                    "ocr_time_ms": ocr_time_ms,
                    "total_time_ms": total_time_ms,
                },
                "image_path": str(image_path),
            }

        except Exception as e:
            logger.error(f"Lỗi trong quá trình xử lý: {e}", exc_info=True)
            return {
                "success": False,
                "raw_text": "",
                "error": str(e),
                "metrics": {"total_time_ms": round((time.time() - start_total) * 1000, 2)},
                "image_path": str(image_path),
            }
