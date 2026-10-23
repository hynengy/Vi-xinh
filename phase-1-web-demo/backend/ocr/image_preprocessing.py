"""
=============================================================================
ĐỒ ÁN THỰC TẬP CHUYÊN MÔN - ỨNG DỤNG "VÍ XINH"
MODULE: TIỀN XỬ LÝ ẢNH HÓA ĐƠN (IMAGE PREPROCESSING)
PHỤ TRÁCH: THÀNH VIÊN 1 - NGUYỄN THÚY HIỀN
=============================================================================
Mô tả nhiệm vụ:
- Cân chỉnh góc nghiêng (Deskew) khi người dùng chụp ảnh bị xéo/lệch.
- Khử bóng đổ và cân bằng ánh sáng không đều (Shadow Removal & Illumination Correction).
- Tăng cường độ tương phản cho hóa đơn in nhiệt mờ chữ (CLAHE).
- Lọc nhiễu nhưng vẫn bảo toàn cạnh ký tự sắc nét (Bilateral Filter).
- Nhị phân hóa thích nghi (Adaptive Binarization / Otsu Thresholding).
=============================================================================
"""

import cv2
import numpy as np
from pathlib import Path
from typing import Dict, Any, Tuple, Optional


class ImagePreprocessor:
    """Bộ tiền xử lý ảnh hóa đơn toàn diện tối ưu hóa cho nhận diện OCR."""

    @staticmethod
    def read_image(image_path: str) -> np.ndarray:
        """
        Đọc file ảnh hỗ trợ đầy đủ đường dẫn có dấu tiếng Việt và nhiều định dạng (JPG, PNG, WEBP, BMP).
        Sử dụng numpy fromfile để tránh lỗi OpenCV tiêu chuẩn trên Windows khi gặp ký tự UTF-8.
        """
        path_obj = Path(image_path)
        if not path_obj.exists():
            raise FileNotFoundError(f"Không tìm thấy file ảnh tại: {image_path}")

        img_bytes = np.fromfile(str(path_obj), dtype=np.uint8)
        img = cv2.imdecode(img_bytes, cv2.IMREAD_COLOR)
        if img is None:
            raise ValueError(f"Không thể giải mã file ảnh hợp lệ: {image_path}")
        return img

    @staticmethod
    def write_image(output_path: Path, img: np.ndarray) -> bool:
        """Lưu ảnh an toàn trên Windows kể cả đường dẫn có dấu tiếng Việt."""
        ext = output_path.suffix.lower() or ".jpg"
        is_success, buffer = cv2.imencode(ext, img)
        if is_success:
            buffer.tofile(str(output_path))
            return True
        return False

    @staticmethod
    def auto_scale(image: np.ndarray) -> np.ndarray:
        """Phóng to ảnh tối ưu để đảm bảo độ cao chữ trong bảng biểu và in nhiệt đạt chuẩn OCR."""
        h, w = image.shape[:2]
        if max(h, w) < 1400:
            scale_factor = min(2.0, 1600.0 / max(h, w))
            if scale_factor > 1.1:
                return cv2.resize(image, (int(w * scale_factor), int(h * scale_factor)), interpolation=cv2.INTER_CUBIC)
        return image

    @staticmethod
    def to_grayscale(image: np.ndarray) -> np.ndarray:
        """
        Chuyển đổi sang thang xám thông minh:
        Tự động nhận diện vết ố vàng / dầu mỡ trên hóa đơn in nhiệt và khử sạch bằng kênh Red.
        """
        if len(image.shape) == 2:
            return image
        
        # Bóc tách kênh màu: BGR
        b, g, r = cv2.split(image)
        # Vết ố vàng/nước sốt/dầu mỡ (như hóa đơn quán ăn, tạp hóa) có thành phần Red cao.
        # Sử dụng trọng số kênh Red cao giúp vết ố vàng hòa vào nền giấy trắng, loại bỏ hoàn toàn nhiễu mỡ!
        cleaned_gray = cv2.addWeighted(r, 0.75, g, 0.25, 0)
        return cleaned_gray

    @staticmethod
    def deskew(image: np.ndarray) -> Tuple[np.ndarray, float]:
        """
        Tự động phát hiện góc nghiêng và xoay thẳng hóa đơn (Deskew).
        Sử dụng thuật toán MinAreaRect trên tập điểm cạnh của văn bản.
        Trả về: (ảnh đã xoay, góc đã xoay tính theo độ).
        """
        gray = ImagePreprocessor.to_grayscale(image)
        # Đảo màu để chữ màu trắng trên nền đen
        inv = cv2.bitwise_not(gray)
        # Ngưỡng nhị phân nhẹ để gom cụm chữ
        _, thresh = cv2.threshold(inv, 0, 255, cv2.THRESH_BINARY | cv2.THRESH_OTSU)

        # Lấy tọa độ các điểm ảnh khác 0
        coords = np.column_stack(np.where(thresh > 0))
        if len(coords) < 50:
            return image, 0.0

        rect = cv2.minAreaRect(coords)
        angle = rect[-1]

        # Chuẩn hóa góc quay OpenCV
        if angle < -45:
            angle = -(90 + angle)
        elif angle > 45:
            angle = angle - 90
        else:
            angle = -angle

        # Nếu độ nghiêng rất nhỏ (< 0.6 độ) hoặc quá lệch (> 45 độ do nhiễu khung) thì giữ nguyên
        if abs(angle) < 0.6 or abs(angle) > 45.0:
            return image, 0.0

        (h, w) = image.shape[:2]
        center = (w // 2, h // 2)
        rot_mat = cv2.getRotationMatrix2D(center, angle, 1.0)
        deskewed = cv2.warpAffine(
            image, rot_mat, (w, h), flags=cv2.INTER_CUBIC, borderMode=cv2.BORDER_REPLICATE
        )
        return deskewed, round(angle, 2)

    @staticmethod
    def remove_shadows(gray_image: np.ndarray) -> np.ndarray:
        """
        Khử bóng đổ và cân bằng ánh sáng không đều (Shadow & Illumination Correction).
        Sử dụng phép toán hình thái học Morphological Opening để ước lượng nền sáng,
        sau đó chuẩn hóa nền để loại bỏ bóng chụp của điện thoại/tay.
        """
        # Cấu trúc phần tử kernel lớn để tách nền
        kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (25, 25))
        # Ước lượng nền ánh sáng
        background = cv2.morphologyEx(gray_image, cv2.MORPH_DILATE, kernel)
        # Trừ nền để lấy phần chữ và loại bỏ chênh lệch sáng tối
        diff = 255 - cv2.subtract(background, gray_image)
        # Chuẩn hóa độ sáng về dải [0, 255]
        normalized = cv2.normalize(diff, None, alpha=0, beta=255, norm_type=cv2.NORM_MINMAX)
        return normalized

    @staticmethod
    def enhance_contrast(gray_image: np.ndarray) -> np.ndarray:
        """
        Tăng cường độ tương phản cục bộ bằng thuật toán CLAHE
        (Contrast Limited Adaptive Histogram Equalization).
        Cực kỳ hiệu quả cho các dòng chữ in nhiệt bị mờ, nét đứt đoạn.
        """
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        return clahe.apply(gray_image)

    @staticmethod
    def denoise(gray_image: np.ndarray) -> np.ndarray:
        """
        Khử nhiễu muối tiêu bằng Bilateral Filter.
        Ưu điểm vượt trội so với Gaussian Blur: Làm mịn bề mặt giấy nhưng GIỮ NGUYÊN cạnh chữ.
        """
        return cv2.bilateralFilter(gray_image, d=9, sigmaColor=75, sigmaSpace=75)

    @staticmethod
    def adaptive_binarization(gray_image: np.ndarray) -> np.ndarray:
        """
        Nhị phân hóa thích nghi (Adaptive Thresholding) kết hợp Otsu.
        Biến ảnh xám thành ảnh đen trắng tuyệt đối (chữ đen, nền trắng).
        """
        # Kết hợp Gaussian Adaptive Threshold
        thresh = cv2.adaptiveThreshold(
            gray_image, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 21, 10
        )
        return thresh

    @classmethod
    def full_pipeline(
        cls, image_path: str, save_stages_dir: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Toàn bộ luồng tiền xử lý ảnh hoàn chỉnh của Nguyễn Thúy Hiền:
        1. Đọc ảnh gốc
        2. Cân chỉnh góc nghiêng (Deskew)
        3. Chuyển sang thang xám
        4. Khử bóng đổ & đồng đều ánh sáng (Shadow Removal)
        5. Tăng tương phản nét chữ (CLAHE)
        6. Lọc nhiễu bảo toàn cạnh (Bilateral Denoise)
        7. Nhị phân hóa đen trắng thích nghi (Adaptive Threshold)
        """
        # 1. Đọc ảnh & Tự động nâng độ phân giải tối ưu nếu ảnh nhỏ
        raw_img = cls.read_image(image_path)
        original = cls.auto_scale(raw_img)

        # 2. Xoay thẳng
        deskewed, rotation_angle = cls.deskew(original)

        # 3. Chuyển xám
        gray = cls.to_grayscale(deskewed)

        # 4. Khử bóng
        shadow_free = cls.remove_shadows(gray)

        # 5. Tăng tương phản
        contrast_boosted = cls.enhance_contrast(shadow_free)

        # 6. Khử nhiễu
        denoised = cls.denoise(contrast_boosted)

        # 7. Nhị phân hóa đen trắng
        final_binary = cls.adaptive_binarization(denoised)

        stages = {
            "original": original,
            "deskewed": deskewed,
            "gray": gray,
            "shadow_free": shadow_free,
            "enhanced": contrast_boosted,
            "final_binary": final_binary,
            "rotation_angle": rotation_angle,
        }

        # Lưu ảnh từng công đoạn nếu có thư mục debug (để đưa vào Báo cáo & Slide)
        if save_stages_dir:
            out_dir = Path(save_stages_dir)
            out_dir.mkdir(parents=True, exist_ok=True)
            stem = Path(image_path).stem
            cls.write_image(out_dir / f"{stem}_1_deskewed.jpg", deskewed)
            cls.write_image(out_dir / f"{stem}_2_shadow_free.jpg", shadow_free)
            cls.write_image(out_dir / f"{stem}_3_final_binary.png", final_binary)

        return stages
