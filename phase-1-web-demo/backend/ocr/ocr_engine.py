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
import cv2

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
        if self.is_configured:
            has_vie = self.has_vietnamese_language()
            if not has_vie and "vie" in self.lang:
                logger.warning(
                    "[CẢNH BÁO TESSERACT] Không tìm thấy gói ngôn ngữ tiếng Việt 'vie' trong Tesseract. "
                    "Chữ tiếng Việt có dấu sẽ bị đọc sai. Tự động chuyển cấu hình sang 'eng'."
                )
                self.lang = "eng"

    def has_vietnamese_language(self) -> bool:
        """Kiểm tra Tesseract đã có gói ngôn ngữ 'vie' (tiếng Việt) chưa."""
        if not self.is_configured:
            return False
        try:
            langs = pytesseract.get_languages()
            return "vie" in langs
        except Exception:
            return False

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
                # Chạy Multi-Pass OCR: PSM 6 (chuẩn dòng hóa đơn/bảng biểu), PSM 4 và PSM 3
                configs_to_try = [
                    r"--oem 3 --psm 6",
                    r"--oem 3 --psm 4",
                    r"--oem 3 --psm 3",
                ]

                best_text = ""
                best_score = -1
                best_cfg = r"--oem 3 --psm 6"
                target_img = gray_img

                for cfg in configs_to_try:
                    try:
                        cur_text = pytesseract.image_to_string(gray_img, lang=self.lang, config=cfg).strip()
                    except Exception:
                        try:
                            cur_text = pytesseract.image_to_string(gray_img, config=cfg).strip()
                        except Exception:
                            cur_text = ""

                    # Chấm điểm văn bản dựa trên độ dài và từ khóa hóa đơn
                    score = len(cur_text)
                    lower_cur = cur_text.lower()
                    for kw in ["tổng", "thanh toán", "tiền", "thành tiền", "hóa đơn", "cộng", "kiotviet", "thu ngân", "ngày"]:
                        if kw in lower_cur:
                            score += 150

                    if score > best_score:
                        best_score = score
                        best_text = cur_text
                        best_cfg = cfg

                # Dự phòng: Thử ảnh nhị phân nếu cần
                if len(best_text) < 40:
                    for cfg in [r"--oem 3 --psm 6", r"--oem 3 --psm 3"]:
                        try:
                            bin_text = pytesseract.image_to_string(binary_img, lang=self.lang, config=cfg).strip()
                            if len(bin_text) > len(best_text):
                                best_text = bin_text
                                best_cfg = cfg
                                target_img = binary_img
                        except Exception:
                            pass

                # 3. Kết quả văn bản OCR đầy đủ từ ảnh nguyên bản (không ghép trùng vùng đầu để tránh nhân đôi dòng)
                raw_text = best_text

                # Chỉ khi toàn ảnh không trích xuất được chữ (dưới 15 ký tự) mới thử vùng header dự phòng
                if len(raw_text.strip()) < 15:
                    try:
                        h_img, w_img = gray_img.shape[:2]
                        top_crop = gray_img[0:int(h_img * 0.4), 0:w_img]
                        top_scaled = cv2.resize(top_crop, (0, 0), fx=2.0, fy=2.0, interpolation=cv2.INTER_CUBIC)
                        for psm_h in [r"--oem 3 --psm 6", r"--oem 3 --psm 3"]:
                            try:
                                h_cand = pytesseract.image_to_string(top_scaled, lang=self.lang, config=psm_h).strip()
                                if len(h_cand) > len(raw_text):
                                    raw_text = h_cand
                                    break
                            except Exception:
                                continue
                    except Exception as e:
                        logger.debug(f"Header fallback skipped: {e}")

                # 4. Lấy chi tiết bounding boxes và điểm tin cậy (Confidence) dùng cấu hình tối ưu best_cfg
                try:
                    try:
                        data = pytesseract.image_to_data(
                            target_img,
                            lang=self.lang,
                            config=best_cfg,
                            output_type=Output.DICT
                        )
                    except Exception:
                        data = pytesseract.image_to_data(
                            target_img,
                            config=best_cfg,
                            output_type=Output.DICT
                        )

                    n_boxes = len(data["text"])
                    for i in range(n_boxes):
                        t = data["text"][i].strip()
                        c = float(data["conf"][i])
                        if t and c > 0:
                            confidences.append(c)
                            boxes.append({
                                "text": t,
                                "x": int(data["left"][i]),
                                "y": int(data["top"][i]),
                                "w": int(data["width"][i]),
                                "h": int(data["height"][i]),
                                "confidence": round(c, 2)
                            })
                except Exception as box_err:
                    logger.warning(f"Lỗi khi trích xuất bounding boxes & confidence: {box_err}")
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
                "confidence": avg_confidence,
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
