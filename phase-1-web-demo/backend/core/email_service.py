"""
Module gửi Email OTP thực tế cho hệ thống Ví Xinh qua SMTP (Gmail / Custom SMTP).
Phụ trách: Thành viên 5 (Nguyễn Việt Anh)
"""
import os
import smtplib
import logging
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from typing import Dict, Any

logger = logging.getLogger(__name__)


def is_smtp_configured() -> bool:
    """Kiểm tra xem hệ thống đã được cấu hình tài khoản gửi email SMTP chưa."""
    user = os.environ.get("SMTP_USER") or os.environ.get("SMTP_EMAIL") or os.environ.get("GMAIL_USER")
    pwd = os.environ.get("SMTP_PASSWORD") or os.environ.get("GMAIL_APP_PASSWORD")
    return bool(user and pwd)


def send_otp_email(
    to_email: str,
    otp_code: str,
    user_name: str = "Bạn",
    purpose: str = "reset"
) -> Dict[str, Any]:
    """
    Gửi email chứa mã OTP xác thực thực tế đến địa chỉ hộp thư của người dùng.
    
    Tham số:
    - to_email: Địa chỉ email người nhận (VD: user@gmail.com)
    - otp_code: Mã số OTP (6 chữ số)
    - user_name: Họ tên người nhận
    - purpose: Mục đích ('reset' khôi phục mật khẩu hoặc 'login' đăng nhập)
    """
    smtp_host = os.environ.get("SMTP_HOST", "smtp.gmail.com")
    smtp_port = int(os.environ.get("SMTP_PORT", "587"))
    smtp_user = os.environ.get("SMTP_USER") or os.environ.get("SMTP_EMAIL") or os.environ.get("GMAIL_USER")
    smtp_pwd = os.environ.get("SMTP_PASSWORD") or os.environ.get("GMAIL_APP_PASSWORD")
    from_name = os.environ.get("SMTP_FROM_NAME", "Ví Xinh - Quản Lý Tài Chính")

    if not smtp_user or not smtp_pwd:
        logger.info(f"[EmailService] Chưa cấu hình SMTP. Mã OTP giả lập cho {to_email}: {otp_code}")
        return {
            "sent": False,
            "provider": "mock",
            "message": "Chưa cấu hình tài khoản SMTP gửi mail. Đang chạy chế độ demo nội bộ.",
            "reason": "no_credentials"
        }

    title_text = "Khôi phục mật khẩu" if purpose == "reset" else "Xác thực đăng nhập"

    html_content = f"""
    <!DOCTYPE html>
    <html lang="vi">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
            body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #F8FAFC; margin: 0; padding: 24px; color: #1E293B; }}
            .container {{ max-width: 520px; margin: 0 auto; background: #FFFFFF; border-radius: 16px; border: 1px solid #E2E8F0; overflow: hidden; box-shadow: 0 4px 16px rgba(0,0,0,0.05); }}
            .header {{ background: linear-gradient(135deg, #5286E8 0%, #3B82F6 100%); padding: 32px 24px; text-align: center; color: #FFFFFF; }}
            .header h1 {{ margin: 0; font-size: 24px; font-weight: 800; letter-spacing: -0.5px; }}
            .header p {{ margin: 6px 0 0 0; opacity: 0.9; font-size: 14px; }}
            .body-wrap {{ padding: 32px 28px; line-height: 1.6; font-size: 15px; }}
            .greeting {{ font-size: 16px; font-weight: 600; margin-bottom: 12px; color: #0F172A; }}
            .otp-box {{ background: #EFF6FF; border: 2px dashed #3B82F6; border-radius: 14px; text-align: center; padding: 20px; margin: 24px 0; }}
            .otp-code {{ font-size: 34px; font-weight: 800; letter-spacing: 8px; color: #1D4ED8; font-family: monospace; }}
            .otp-hint {{ font-size: 13px; color: #64748B; margin-top: 8px; }}
            .warning {{ background: #FEF2F2; border-left: 4px solid #EF4444; padding: 12px 16px; border-radius: 0 8px 8px 0; font-size: 13px; color: #991B1B; margin: 20px 0; }}
            .footer {{ background: #F8FAFC; padding: 20px 24px; text-align: center; font-size: 12px; color: #94A3B8; border-top: 1px solid #F1F5F9; }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>Ví Xinh</h1>
                <p>Quản Lý Tài Chính Thông Minh & Chi Tiêu Nhóm</p>
            </div>
            <div class="body-wrap">
                <div class="greeting">Xin chào {user_name},</div>
                <p>Chúng tôi nhận được yêu cầu <strong>{title_text}</strong> cho tài khoản Ví Xinh gắn với email này.</p>
                <p>Dưới đây là mã xác thực OTP của bạn:</p>
                
                <div class="otp-box">
                    <div class="otp-code">{otp_code}</div>
                    <div class="otp-hint">Mã xác thực có hiệu lực trong vòng <strong>5 phút</strong></div>
                </div>

                <div class="warning">
                    <strong>Bảo mật:</strong> Tuyệt đối không chia sẻ mã này cho bất kỳ ai, kể cả nhân viên hỗ trợ của Ví Xinh.
                </div>

                <p style="font-size: 13px; color: #64748B;">Nếu bạn không thực hiện yêu cầu này, vui lòng bỏ qua email hoặc đổi mật khẩu để bảo vệ tài khoản.</p>
            </div>
            <div class="footer">
                &copy; Ví Xinh. Thư này được gửi tự động từ hệ thống xác thực.
            </div>
        </div>
    </body>
    </html>
    """

    plain_content = (
        f"Xin chào {user_name},\n\n"
        f"Mã OTP xác thực {title_text} cho tài khoản Ví Xinh của bạn là: {otp_code}\n"
        f"Mã có hiệu lực trong vòng 5 phút. Vui lòng không chia sẻ mã này cho bất kỳ ai.\n\n"
        f"Trân trọng,\nĐội ngũ Ví Xinh"
    )

    try:
        msg = MIMEMultipart("alternative")
        msg["Subject"] = f"[{otp_code}] Mã xác thực Ví Xinh - {title_text}"
        msg["From"] = f"{from_name} <{smtp_user}>"
        msg["To"] = to_email

        msg.attach(MIMEText(plain_content, "plain", "utf-8"))
        msg.attach(MIMEText(html_content, "html", "utf-8"))

        # Gửi qua SMTP với timeout 10 giây
        if smtp_port == 465:
            with smtplib.SMTP_SSL(smtp_host, smtp_port, timeout=10) as server:
                server.login(smtp_user, smtp_pwd)
                server.send_message(msg)
        else:
            with smtplib.SMTP(smtp_host, smtp_port, timeout=10) as server:
                server.starttls()
                server.login(smtp_user, smtp_pwd)
                server.send_message(msg)

        logger.info(f"[EmailService] Đã gửi thành công email OTP tới {to_email}")
        return {
            "sent": True,
            "provider": "smtp",
            "message": f"Mã OTP đã được gửi đến hộp thư {to_email}."
        }
    except Exception as e:
        logger.error(f"[EmailService] Lỗi gửi email qua SMTP: {str(e)}")
        return {
            "sent": False,
            "provider": "smtp",
            "message": f"Không thể gửi email: {str(e)}",
            "error": str(e)
        }
