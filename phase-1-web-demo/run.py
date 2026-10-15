"""
File Khởi Chạy Web Demo "Ví Xinh"
Phụ trách điều phối: Thành viên 5 - Nguyễn Việt Anh
Sử dụng:
    python run.py
"""
import sys
from pathlib import Path

# Đảm bảo in UTF-8 không lỗi trên console Windows
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

# Thêm thư mục hiện tại vào sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent))

from backend.app import app
from backend.core.config import HOST, PORT, DEBUG

if __name__ == "__main__":
    print(f"✨ Khởi chạy Web Demo 'Ví Xinh' tại: http://{HOST}:{PORT}")
    print("👉 Hãy mở trình duyệt và trải nghiệm quy trình OCR hóa đơn!")
    app.run(host=HOST, port=PORT, debug=DEBUG)
