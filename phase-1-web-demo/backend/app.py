"""
Ứng Dụng Web Server & REST API "Ví Xinh"
Phối hợp kỹ thuật: Thành viên 5 (Nguyễn Việt Anh) & Thành viên 4 (Lê Ngọc Duy)
"""
import os
import uuid
from pathlib import Path
from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS

from .core.config import UPLOAD_FOLDER, FRONTEND_DIR, ALLOWED_EXTENSIONS
from .core.pipeline import ProcessingPipeline
from .database.db_manager import DatabaseManager
from .database.group_wallet import GroupWalletManager
from .core.config import DB_PATH

app = Flask(__name__, static_folder=str(FRONTEND_DIR), static_url_path="")
CORS(app)

pipeline = ProcessingPipeline()
db = DatabaseManager(DB_PATH)


def allowed_file(filename: str) -> bool:
    return "." in filename and filename.rsplit(".", 1)[1].lower() in ALLOWED_EXTENSIONS


# --- Serve Frontend Pages (Thành viên 4: Lê Ngọc Duy) ---
@app.route("/")
def index():
    return send_from_directory(str(FRONTEND_DIR), "index.html")


@app.route("/review")
def review():
    return send_from_directory(str(FRONTEND_DIR), "review.html")


@app.route("/groups")
def groups():
    return send_from_directory(str(FRONTEND_DIR), "groups.html")


@app.route("/uploads/<path:filename>")
def uploaded_file(filename):
    return send_from_directory(str(UPLOAD_FOLDER), filename)


# --- REST API Endpoints ---
@app.route("/api/receipts/upload", methods=["POST"])
def upload_receipt():
    """
    API 1: Tải ảnh hóa đơn lên và chạy OCR + Bóc tách dữ liệu
    """
    if "receipt" not in request.files:
        return jsonify({"error": "Không tìm thấy file ảnh tải lên!"}), 400

    file = request.files["receipt"]
    if file.filename == "":
        return jsonify({"error": "Chưa chọn file!"}), 400

    if not allowed_file(file.filename):
        return jsonify({"error": "Định dạng file không được hỗ trợ!"}), 400

    # Lưu file với uuid để tránh trùng lặp
    ext = file.filename.rsplit(".", 1)[1].lower()
    saved_filename = f"{uuid.uuid4().hex}.{ext}"
    saved_path = UPLOAD_FOLDER / saved_filename
    file.save(str(saved_path))

    # Chạy quy trình OCR & Regex bóc tách
    result = pipeline.process_receipt_image(saved_path)
    result["file_name"] = saved_filename

    return jsonify(result)


@app.route("/api/transactions", methods=["GET", "POST"])
def handle_transactions():
    """
    API 2: Lưu giao dịch đã xác thực hoặc lấy danh sách giao dịch
    """
    if request.method == "POST":
        data = request.json or {}
        tx_id = pipeline.save_verified_transaction(data)
        return jsonify({"success": True, "transaction_id": tx_id}), 201

    transactions = db.get_recent_transactions(limit=30)
    return jsonify(transactions)


@app.route("/api/stats", methods=["GET"])
def get_stats():
    """API 3: Lấy số liệu thống kê Dashboard."""
    stats = db.get_summary_stats()
    return jsonify(stats)


@app.route("/api/groups", methods=["GET"])
def list_groups():
    """API 4: Lấy danh sách ví nhóm."""
    groups_list = db.get_groups()
    return jsonify(groups_list)


@app.route("/api/users", methods=["GET"])
def list_users():
    """API 5: Lấy danh sách thành viên nhóm."""
    users_list = db.get_users()
    return jsonify(users_list)


@app.route("/api/groups/<int:group_id>/split-equal", methods=["POST"])
def split_equal(group_id):
    """API 6: Tính toán chia đều tiền trong ví nhóm."""
    data = request.json or {}
    total_amount = float(data.get("amount", 0))
    member_ids = data.get("member_ids", [])
    result = GroupWalletManager.split_equally(total_amount, member_ids)
    return jsonify(result)
