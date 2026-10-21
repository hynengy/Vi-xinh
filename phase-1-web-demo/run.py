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
    use_ssl = "--ssl" in sys.argv or "--https" in sys.argv
    scheme = "https" if use_ssl else "http"
    ssl_context = "adhoc" if use_ssl else None

    use_prod = "--prod" in sys.argv or "--waitress" in sys.argv

    if use_prod:
        try:
            from waitress import serve
            print(f"🚀 Khởi chạy Production WSGI Server (Waitress) tại: http://{HOST}:{PORT}")
            print("✨ Server đang chạy ở chế độ Production đa luồng, ổn định tuyệt đối.")
            serve(app, host=HOST, port=PORT)
            sys.exit(0)
        except ImportError:
            print("⚠️ Chưa tìm thấy gói 'waitress', tự động chuyển về máy chủ phát triển mặc định...")

    print(f"✨ Khởi chạy Web Demo 'Ví Xinh' tại: {scheme}://{HOST}:{PORT}")
    if use_ssl:
        print("🔒 Chế độ HTTPS bảo mật đã bật: Cho phép Safari (iOS/iPhone) và Chrome bật Camera và Face ID thật 100%!")
        print("💡 Lưu ý với Safari trên iPhone: Chọn 'Nâng cao' (Show Details) -> 'Tiếp tục truy cập' (visit this website) khi mở lần đầu.")
    else:
        print("👉 Hãy mở trình duyệt và trải nghiệm quy trình OCR hóa đơn!")
        print("💡 Gợi ý cho Safari iPhone: Chạy 'python run.py --ssl' để mở camera và Face ID trực tiếp trên Safari.")
        print("💡 Gợi ý chạy chế độ Production: Chạy 'python run.py --prod' để dùng máy chủ WSGI Waitress.")
    app.run(host=HOST, port=PORT, debug=DEBUG, ssl_context=ssl_context)
