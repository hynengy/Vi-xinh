"""
Unit test kiểm thử module Email OTP và endpoint xác thực OTP
"""
import os
import pytest
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent / "phase-1-web-demo"
sys.path.insert(0, str(BASE_DIR))

from backend.core.email_service import send_otp_email, is_smtp_configured
from backend.app import app, OTP_STORE, db


def test_is_smtp_configured_default(monkeypatch):
    monkeypatch.delenv("SMTP_USER", raising=False)
    monkeypatch.delenv("SMTP_EMAIL", raising=False)
    monkeypatch.delenv("GMAIL_USER", raising=False)
    monkeypatch.delenv("SMTP_PASSWORD", raising=False)
    monkeypatch.delenv("GMAIL_APP_PASSWORD", raising=False)
    assert is_smtp_configured() is False


def test_is_smtp_configured_true(monkeypatch):
    monkeypatch.setenv("SMTP_USER", "vixinh@gmail.com")
    monkeypatch.setenv("SMTP_PASSWORD", "secret123456")
    assert is_smtp_configured() is True


def test_send_otp_email_mock_fallback(monkeypatch):
    monkeypatch.delenv("SMTP_USER", raising=False)
    monkeypatch.delenv("SMTP_PASSWORD", raising=False)
    result = send_otp_email("test@example.com", "123456", "Thử Nghiệm", "reset")
    assert result["sent"] is False
    assert result["provider"] == "mock"
    assert result["reason"] == "no_credentials"


def test_auth_send_otp_api_not_found(client=None):
    with app.test_client() as c:
        res = c.post("/api/auth/otp/send", json={"contact": "nonexistent_email_12345@gmail.com", "purpose": "reset"})
        assert res.status_code == 404
        data = res.get_json()
        assert "không tìm thấy" in data["error"].lower()


def test_auth_send_otp_api_success():
    # Tạo user test
    test_email = "tester_otp@vixinh.vn"
    user = db.get_user_by_contact(test_email)
    if not user:
        user = db.register_user("Tester OTP", email=test_email, phone="0988776655", password="password123")

    with app.test_client() as c:
        res = c.post("/api/auth/otp/send", json={"contact": test_email, "purpose": "reset"})
        assert res.status_code == 200
        data = res.get_json()
        assert data["success"] is True
        assert "otp" in data or data.get("real_email_sent") is True
