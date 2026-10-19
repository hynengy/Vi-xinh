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
