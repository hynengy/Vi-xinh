"""
Cấu hình hệ thống Ví Xinh (Phase 1: Web Demo)
Phụ trách: Thành viên 5 - Nguyễn Việt Anh
"""
import os
from pathlib import Path

# Base Directory
BASE_DIR = Path(__file__).resolve().parent.parent.parent
BACKEND_DIR = BASE_DIR / "backend"
FRONTEND_DIR = BASE_DIR / "frontend"
DATA_DIR = BASE_DIR.parent / "data"


def _load_env_file() -> None:
    """Nạp biến môi trường từ file .env (phase-1-web-demo/.env hoặc thư mục gốc repo).
    Không ghi đè biến đã được đặt sẵn trong hệ thống."""
    for env_path in (BASE_DIR / ".env", BASE_DIR.parent / ".env"):
        if not env_path.exists():
            continue
        for raw in env_path.read_text(encoding="utf-8").splitlines():
            line = raw.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, val = line.split("=", 1)
            key = key.strip()
            val = val.strip().strip('"').strip("'")
            if key and key not in os.environ:
                os.environ[key] = val


_load_env_file()

# Google Cloud Vision (OCR duy nhất của hệ thống)
GOOGLE_VISION_API_KEY = os.environ.get("GOOGLE_VISION_API_KEY") or os.environ.get("GOOGLE_API_KEY") or ""

# Upload & Data storage directories
UPLOAD_FOLDER = DATA_DIR / "uploads"
UPLOAD_FOLDER.mkdir(parents=True, exist_ok=True)

DB_PATH = DATA_DIR / "vixinh.sqlite3"

# Allowed upload extensions
ALLOWED_EXTENSIONS = {"png", "jpg", "jpeg", "webp", "bmp"}

# Server Settings
HOST = "0.0.0.0"
PORT = 5000
DEBUG = True
