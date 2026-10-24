"""
Module OCR - Ví Xinh
Phụ trách: Thành viên 1 - Nguyễn Thúy Hiền
OCR duy nhất: Google Cloud Vision (bản cloud của Google ML Kit Text Recognition).
"""
from .image_preprocessing import ImagePreprocessor
from .google_mlkit_engine import GoogleMLKitEngine

__all__ = ["ImagePreprocessor", "GoogleMLKitEngine"]
