"""
Module Tiền Xử Lý Ảnh Hóa Đơn
Phụ trách: Thành viên 1 - Nguyễn Thúy Hiền
Nhiệm vụ: Cân chỉnh góc nghiêng (deskew), khử nhiễu, tăng tương phản để tối ưu cho OCR
"""
import cv2
import numpy as np
from pathlib import Path


class ImagePreprocessor:
    """Tiền xử lý ảnh hóa đơn trước khi đưa qua OCR engine."""

    @staticmethod
    def read_image(image_path: str) -> np.ndarray:
        """Đọc ảnh hỗ trợ cả đường dẫn có dấu tiếng Việt."""
        img_array = np.fromfile(str(image_path), np.uint8)
        img = cv2.imdecode(img_array, cv2.IMREAD_COLOR)
        if img is None:
            raise ValueError(f"Không thể mở file ảnh tại: {image_path}")
        return img

    @staticmethod
    def to_grayscale(image: np.ndarray) -> np.ndarray:
        """Chuyển ảnh sang thang xám."""
        if len(image.shape) == 2:
            return image
        return cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

    @staticmethod
    def remove_noise(image: np.ndarray) -> np.ndarray:
        """Khử nhiễu nhẹ bằng Gaussian Blur giữ lại cạnh chữ."""
        return cv2.GaussianBlur(image, (3, 3), 0)

    @staticmethod
    def adaptive_threshold(image: np.ndarray) -> np.ndarray:
        """Áp dụng nhị phân hóa cục bộ (Otsu binarization) làm rõ nét chữ in nhiệt."""
        gray = ImagePreprocessor.to_grayscale(image)
        blurred = ImagePreprocessor.remove_noise(gray)
        _, thresh = cv2.threshold(blurred, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
        return thresh

    @staticmethod
    def deskew(image: np.ndarray) -> np.ndarray:
        """Cân chỉnh góc nghiêng của hóa đơn nếu chụp bị lệch."""
        gray = ImagePreprocessor.to_grayscale(image)
        # Đảo màu để nền đen chữ trắng tìm contour
        inv = cv2.bitwise_not(gray)
        coords = np.column_stack(np.where(inv > 0))
        if len(coords) == 0:
            return image

        angle = cv2.minAreaRect(coords)[-1]
        if angle < -45:
            angle = -(90 + angle)
        else:
            angle = -angle

        # Nếu góc nghiêng nhỏ hơn 0.5 độ thì không cần xoay
        if abs(angle) < 0.5 or abs(angle) > 45:
            return image

        (h, w) = image.shape[:2]
        center = (w // 2, h // 2)
        rotation_matrix = cv2.getRotationMatrix2D(center, angle, 1.0)
        rotated = cv2.warpAffine(
            image, rotation_matrix, (w, h), flags=cv2.INTER_CUBIC, borderMode=cv2.BORDER_REPLICATE
        )
        return rotated

    @classmethod
    def preprocess_pipeline(cls, image_path: str, save_debug: bool = False) -> np.ndarray:
        """Pipeline tiền xử lý hoàn chỉnh chuẩn bị cho OCR."""
        img = cls.read_image(image_path)
        deskewed = cls.deskew(img)
        processed = cls.adaptive_threshold(deskewed)

        if save_debug:
            debug_path = Path(image_path).with_name(f"preprocessed_{Path(image_path).name}")
            cv2.imwrite(str(debug_path), processed)

        return processed
