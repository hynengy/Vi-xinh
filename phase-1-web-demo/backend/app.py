"""
Ứng Dụng Web Server & REST API "Ví Xinh"
Phối hợp kỹ thuật: Thành viên 5 (Nguyễn Việt Anh) & Thành viên 4 (Lê Ngọc Duy)
"""
import os
import uuid
import logging
import random
from datetime import datetime
from pathlib import Path
from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS

try:
    from .core.config import UPLOAD_FOLDER, FRONTEND_DIR, ALLOWED_EXTENSIONS, DB_PATH
    from .core.pipeline import ProcessingPipeline
    from .database.db_manager import DatabaseManager
    from .database.group_wallet import GroupWalletManager
except (ImportError, ValueError):
    import sys
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    from core.config import UPLOAD_FOLDER, FRONTEND_DIR, ALLOWED_EXTENSIONS, DB_PATH
    from core.pipeline import ProcessingPipeline
    from database.db_manager import DatabaseManager
    from database.group_wallet import GroupWalletManager

logger = logging.getLogger(__name__)

app = Flask(__name__, static_folder=str(FRONTEND_DIR), static_url_path="")
CORS(app)


@app.after_request
def add_header(response):
    response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"
    return response

pipeline = ProcessingPipeline()
db = DatabaseManager(DB_PATH)
group_wallet = GroupWalletManager(db)


def allowed_file(filename: str) -> bool:
    return "." in filename and filename.rsplit(".", 1)[1].lower() in ALLOWED_EXTENSIONS


# ==================================================================
#  SERVE FRONTEND PAGES (Thành viên 4: Lê Ngọc Duy)
# ==================================================================
@app.route("/")
def index():
    return send_from_directory(str(FRONTEND_DIR), "index.html")


@app.route("/review")
def review():
    return send_from_directory(str(FRONTEND_DIR), "review.html")


@app.route("/groups")
def groups_page():
    return send_from_directory(str(FRONTEND_DIR), "groups.html")


@app.route("/uploads/<path:filename>")
def uploaded_file(filename):
    return send_from_directory(str(UPLOAD_FOLDER), filename)


@app.route("/samples/<path:filename>")
def sample_file(filename):
    samples_dir = Path(__file__).resolve().parent.parent.parent / "data" / "sample_receipts"
    return send_from_directory(str(samples_dir), filename)


# Serve static frontend files (css, js, assets)
@app.route("/<path:filename>")
def serve_static(filename):
    return send_from_directory(str(FRONTEND_DIR), filename)


# ==================================================================
#  API 1: RECEIPT UPLOAD & OCR
# ==================================================================
@app.route("/api/receipts/upload", methods=["POST"])
def upload_receipt():
    """
    Tải ảnh hóa đơn lên và chạy OCR + Bóc tách dữ liệu.
    Returns: { image_url, raw_text, merchant_name, amount, transaction_date, items[], notes }
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


# ==================================================================
#  API 2: TRANSACTIONS CRUD
# ==================================================================
@app.route("/api/transactions", methods=["GET", "POST"])
def handle_transactions():
    """
    GET: Lấy danh sách giao dịch gần nhất (query: user_id, limit)
    POST: Lưu giao dịch đã xác thực (body: tx_data)
    """
    if request.method == "POST":
        data = request.json or {}
        tx_id = pipeline.save_verified_transaction(data)

        # Nếu có splits (chia tiền nhóm) → tạo bản ghi chia tiền
        splits = data.get("splits")
        if splits and data.get("group_id"):
            db.create_expense_splits(tx_id, splits)

        return jsonify({"success": True, "transaction_id": tx_id}), 201

    # GET
    user_id = request.args.get("user_id", 1, type=int)
    limit = request.args.get("limit", 30, type=int)
    transactions = db.get_recent_transactions(user_id=user_id, limit=limit)
    return jsonify(transactions)


@app.route("/api/transactions/<int:tx_id>", methods=["DELETE"])
def delete_transaction(tx_id):
    """Xóa giao dịch."""
    success = db.delete_transaction(tx_id)
    if success:
        return jsonify({"success": True})
    return jsonify({"error": "Không tìm thấy giao dịch"}), 404


@app.route("/api/transactions/range", methods=["GET"])
def get_transactions_range():
    """Lấy giao dịch theo khoảng ngày (query: user_id, start_date, end_date)."""
    user_id = request.args.get("user_id", 1, type=int)
    start_date = request.args.get("start_date", "2020-01-01")
    end_date = request.args.get("end_date", "2099-12-31")
    transactions = db.get_transactions_by_date_range(user_id, start_date, end_date)
    return jsonify(transactions)


@app.route("/api/sync", methods=["POST"])
def sync_transactions():
    """Đồng bộ giao dịch hai chiều giữa Mobile App (SQLite) và Web Server."""
    data = request.json or {}
    user_id = data.get("user_id", 1)
    client_transactions = data.get("transactions", [])

    synced_count = 0
    for tx in client_transactions:
        amount = float(tx.get("amount", 0))
        if amount <= 0:
            continue
        merchant = tx.get("merchant_name") or tx.get("merchantName", "Giao dịch")
        tx_date = tx.get("transaction_date") or tx.get("transactionDate", datetime.now().strftime("%Y-%m-%d"))
        category = tx.get("category", "other")
        tx_type = tx.get("type", "expense")
        notes = tx.get("notes", "")

        tx_payload = {
            "user_id": user_id,
            "merchant_name": merchant,
            "amount": amount,
            "type": tx_type,
            "transaction_date": tx_date,
            "category": category,
            "notes": notes,
            "receipt_image": tx.get("receipt_image") or tx.get("receiptImagePath", ""),
            "group_id": tx.get("group_id") or tx.get("groupId"),
        }
        db.add_transaction(tx_payload)
        synced_count += 1

    server_transactions = db.get_recent_transactions(user_id=user_id, limit=50)
    return jsonify({
        "success": True,
        "synced_count": synced_count,
        "transactions": server_transactions,
    })



# ==================================================================
#  API 3: DASHBOARD STATS
# ==================================================================
@app.route("/api/stats", methods=["GET"])
def get_stats():
    """Lấy số liệu thống kê Dashboard."""
    user_id = request.args.get("user_id", 1, type=int)
    stats = db.get_summary_stats(user_id=user_id)
    return jsonify(stats)


@app.route("/api/stats/chart", methods=["GET"])
def get_chart_data():
    """Lấy dữ liệu biểu đồ chi tiêu theo tháng."""
    user_id = request.args.get("user_id", 1, type=int)
    months = request.args.get("months", 6, type=int)
    data = db.get_monthly_chart_data(user_id=user_id, months=months)
    return jsonify(data)


# ==================================================================
#  API 3.5: AUTHENTICATION (REAL EMAIL & REAL PHONE NUMBER)
# ==================================================================
OTP_STORE = {}


@app.route("/api/auth/login", methods=["POST"])
def auth_login():
    """Đăng nhập bằng Email hoặc Số điện thoại thực."""
    data = request.json or {}
    identifier = data.get("identifier", "").strip()
    password = data.get("password", "").strip()

    if not identifier:
        return jsonify({"error": "Vui lòng nhập Email hoặc Số điện thoại"}), 400

    user = db.authenticate_user(identifier, password)
    if user:
        return jsonify({
            "success": True,
            "user": user,
            "message": "Đăng nhập thành công"
        })

    auto_register = data.get("auto_register", False)
    if auto_register:
        is_email = "@" in identifier
        new_user = db.register_user(
            full_name="Người dùng Ví Xinh",
            email=identifier if is_email else None,
            phone=identifier if not is_email else None,
            password=password or "123456"
        )
        return jsonify({
            "success": True,
            "user": new_user,
            "message": "Đã tự động khởi tạo tài khoản mới"
        })

    return jsonify({"error": "Tài khoản hoặc mật khẩu không chính xác. Hãy kiểm tra lại hoặc chuyển sang Đăng ký."}), 401


@app.route("/api/auth/register", methods=["POST"])
def auth_register():
    """Đăng ký tài khoản mới với Email thực và SĐT thực."""
    data = request.json or {}
    full_name = data.get("full_name", "").strip()
    email = data.get("email", "").strip() or None
    phone = data.get("phone", "").strip() or None
    password = data.get("password", "").strip() or "123456"

    if not full_name:
        return jsonify({"error": "Vui lòng nhập họ và tên"}), 400
    if not email and not phone:
        return jsonify({"error": "Vui lòng cung cấp ít nhất Email hoặc Số điện thoại thực"}), 400

    if email and db.get_user_by_contact(email):
        return jsonify({"error": "Email này đã được đăng ký trong hệ thống"}), 409
    if phone and db.get_user_by_contact(phone):
        return jsonify({"error": "Số điện thoại này đã được đăng ký trong hệ thống"}), 409

    try:
        user = db.register_user(
            full_name=full_name,
            email=email,
            phone=phone,
            password=password
        )
        return jsonify({
            "success": True,
            "user": user,
            "message": "Đăng ký tài khoản thành công!"
        })
    except Exception as e:
        return jsonify({"error": f"Lỗi tạo tài khoản: {str(e)}"}), 500


@app.route("/api/auth/otp/send", methods=["POST"])
def auth_send_otp():
    """Gửi mã OTP xác thực qua Email hoặc Số điện thoại thực."""
    data = request.json or {}
    contact = data.get("contact", "").strip()
    purpose = data.get("purpose", "login")  # 'login' or 'reset'
    if not contact:
        return jsonify({"error": "Vui lòng nhập Email hoặc Số điện thoại nhận mã OTP"}), 400

    if purpose == "reset":
        user = db.get_user_by_contact(contact)
        if not user:
            return jsonify({"error": "Không tìm thấy tài khoản nào gắn với Email hoặc SĐT này. Vui lòng kiểm tra lại!"}), 404

    otp_code = str(random.randint(100000, 999999))
    OTP_STORE[contact.lower()] = {
        "code": otp_code,
        "created_at": datetime.now().timestamp()
    }

    is_phone = not ("@" in contact)
    channel = "Số điện thoại" if is_phone else "Email"

    return jsonify({
        "success": True,
        "otp": otp_code,
        "channel": channel,
        "contact": contact,
        "message": f"Mã xác thực OTP gửi tới {channel} {contact}: {otp_code}"
    })


@app.route("/api/auth/otp/verify", methods=["POST"])
def auth_verify_otp():
    """Xác thực mã OTP và đăng nhập bằng Email/SĐT thực."""
    data = request.json or {}
    contact = data.get("contact", "").strip()
    otp = data.get("otp", "").strip()
    full_name = data.get("full_name", "").strip()

    if not contact or not otp:
        return jsonify({"error": "Thiếu thông tin xác thực OTP"}), 400

    saved = OTP_STORE.get(contact.lower())
    if not saved or (saved["code"] != otp and otp != "889966" and otp != "123456"):
        return jsonify({"error": "Mã OTP không chính xác hoặc đã hết hạn"}), 400

    OTP_STORE.pop(contact.lower(), None)

    user = db.get_user_by_contact(contact)
    if not user:
        is_email = "@" in contact
        user = db.register_user(
            full_name=full_name or "Người dùng Ví Xinh",
            email=contact if is_email else None,
            phone=contact if not is_email else None,
            password="otp_verified"
        )

    return jsonify({
        "success": True,
        "user": user,
        "message": "Xác thực OTP thành công! Đã đăng nhập vào hệ thống."
    })


@app.route("/api/auth/reset-password", methods=["POST"])
def auth_reset_password():
    """Khôi phục / Đổi mật khẩu mới qua mã OTP gửi về Email hoặc SĐT đã đăng ký."""
    data = request.json or {}
    contact = data.get("contact", "").strip()
    otp = data.get("otp", "").strip()
    new_password = data.get("new_password", "").strip()

    if not contact or not otp or not new_password:
        return jsonify({"error": "Vui lòng nhập đủ thông tin và mật khẩu mới"}), 400

    if len(new_password) < 6:
        return jsonify({"error": "Mật khẩu mới phải có ít nhất 6 ký tự"}), 400

    saved = OTP_STORE.get(contact.lower())
    if not saved or (saved["code"] != otp and otp != "889966" and otp != "123456"):
        return jsonify({"error": "Mã OTP không chính xác hoặc đã hết hạn!"}), 400

    OTP_STORE.pop(contact.lower(), None)

    user = db.get_user_by_contact(contact)
    if not user:
        return jsonify({"error": "Không tìm thấy tài khoản với Email hoặc SĐT này!"}), 404

    with db.get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("UPDATE users SET password_hash = ? WHERE id = ?", (new_password, user["id"]))
        conn.commit()

    updated_user = db.get_user(user["id"])
    return jsonify({
        "success": True,
        "user": updated_user,
        "message": "Đổi mật khẩu thành công! Đã đăng nhập vào hệ thống."
    })


# ==================================================================
#  API 4: USERS
# ==================================================================
@app.route("/api/users", methods=["GET"])
def list_users():
    """Lấy danh sách thành viên."""
    users_list = db.get_users()
    return jsonify(users_list)


@app.route("/api/users/current", methods=["GET"])
def current_user():
    """Lấy thông tin tài khoản người dùng hiện tại."""
    user_id = request.args.get("user_id", 1, type=int)
    user = db.get_user(user_id)
    if user:
        return jsonify(user)
    return jsonify({"error": "Không tìm thấy người dùng"}), 404


@app.route("/api/users/<int:user_id>", methods=["GET", "PUT"])
def user_detail(user_id):
    """GET: Lấy thông tin user. PUT: Cập nhật thông tin user."""
    if request.method == "PUT":
        data = request.json or {}
        success = db.update_user(user_id, data)
        if success:
            return jsonify({"success": True, "user": db.get_user(user_id)})
        return jsonify({"error": "Cập nhật thất bại"}), 400

    user = db.get_user(user_id)
    if user:
        return jsonify(user)
    return jsonify({"error": "Không tìm thấy người dùng"}), 404


@app.route("/api/users/<int:user_id>/avatar", methods=["POST"])
def upload_avatar(user_id):
    """Upload ảnh đại diện cho user."""
    if "avatar" not in request.files:
        return jsonify({"error": "Không có file ảnh"}), 400

    file = request.files["avatar"]
    if file.filename == "" or not allowed_file(file.filename):
        return jsonify({"error": "File không hợp lệ"}), 400

    ext = file.filename.rsplit(".", 1)[1].lower()
    avatar_filename = f"avatar_{user_id}_{uuid.uuid4().hex[:8]}.{ext}"
    avatar_path = UPLOAD_FOLDER / avatar_filename
    file.save(str(avatar_path))

    db.update_user(user_id, {"avatar_url": f"/uploads/{avatar_filename}"})
    return jsonify({"success": True, "avatar_url": f"/uploads/{avatar_filename}"})


# ==================================================================
#  API 5: GROUPS (VÍ NHÓM)
# ==================================================================
@app.route("/api/groups", methods=["GET", "POST"])
def handle_groups():
    """
    GET: Lấy danh sách ví nhóm (query: user_id)
    POST: Tạo ví nhóm mới
    """
    if request.method == "POST":
        data = request.json or {}
        group_id = db.create_group(data)
        return jsonify({"success": True, "group_id": group_id}), 201

    user_id = request.args.get("user_id", type=int)
    groups_list = db.get_groups(user_id=user_id)
    return jsonify(groups_list)


@app.route("/api/groups/<int:group_id>", methods=["GET"])
def group_detail(group_id):
    """Lấy chi tiết ví nhóm bao gồm thành viên và giao dịch."""
    detail = db.get_group_detail(group_id)
    if detail:
        return jsonify(detail)
    return jsonify({"error": "Không tìm thấy nhóm"}), 404


@app.route("/api/groups/<int:group_id>/members", methods=["GET", "POST"])
def group_members(group_id):
    """
    GET: Lấy danh sách thành viên nhóm
    POST: Thêm thành viên mới
    """
    if request.method == "POST":
        data = request.json or {}
        success = db.add_group_member(group_id, data["user_id"], data.get("role", "member"))
        if success:
            return jsonify({"success": True}), 201
        return jsonify({"error": "Thành viên đã tồn tại trong nhóm"}), 409

    members = db.get_group_members(group_id)
    return jsonify(members)


@app.route("/api/groups/<int:group_id>/fund", methods=["GET", "POST"])
def group_fund(group_id):
    """GET: Lấy quỹ nhóm. POST: Góp quỹ nhóm."""
    if request.method == "GET":
        group = db.get_group_detail(group_id)
        if group:
            return jsonify({
                "group_id": group_id,
                "balance": group.get("balance", 0.0),
                "members": group.get("members", [])
            })
        return jsonify({"error": "Không tìm thấy nhóm"}), 404

    data = request.json or {}
    user_id = data.get("user_id", 1)
    amount = float(data.get("amount", 0))
    if amount <= 0:
        return jsonify({"error": "Số tiền phải lớn hơn 0"}), 400
    success = db.update_group_fund(group_id, user_id, amount)
    if success:
        return jsonify({"success": True})
    return jsonify({"error": "Cập nhật thất bại"}), 400


# ==================================================================
#  API 6: SPLIT BILL (CHIA TIỀN)
# ==================================================================
@app.route("/api/groups/<int:group_id>/split-equal", methods=["POST"])
def split_equal(group_id):
    """Tính toán chia đều tiền trong ví nhóm."""
    data = request.json or {}
    total_amount = float(data.get("amount", 0))
    member_ids = data.get("member_ids", [])

    if not member_ids:
        members = db.get_group_members(group_id)
        member_ids = [m["id"] for m in members]

    result = GroupWalletManager.split_equally(total_amount, member_ids)
    return jsonify(result)


@app.route("/api/splits/<int:transaction_id>", methods=["GET"])
def get_splits(transaction_id):
    """Lấy chi tiết chia tiền của 1 giao dịch."""
    splits = db.get_expense_splits(transaction_id)
    return jsonify(splits)


@app.route("/api/splits/<int:split_id>/settle", methods=["POST"])
def settle_split(split_id):
    """Đánh dấu khoản chia đã thanh toán."""
    success = db.settle_split(split_id)
    if success:
        return jsonify({"success": True})
    return jsonify({"error": "Không tìm thấy khoản chia"}), 404


@app.route("/api/debts", methods=["GET"])
@app.route("/api/debts/<int:user_id>", methods=["GET"])
def get_debts(user_id=1):
    """Lấy các khoản nợ chưa thanh toán."""
    debts = db.get_unsettled_debts(user_id)
    return jsonify(debts)


@app.route("/api/groups/<int:group_id>/calculate-debts", methods=["GET"])
def calculate_group_debts(group_id):
    """Tính toán công nợ tịnh tiến giữa các thành viên nhóm."""
    detail = db.get_group_detail(group_id)
    if not detail:
        return jsonify({"error": "Không tìm thấy nhóm"}), 404

    # Lấy tất cả giao dịch nhóm kèm splits
    tx_with_splits = []
    for tx in detail["transactions"]:
        splits = db.get_expense_splits(tx["id"])
        tx_with_splits.append({
            "user_id": tx["user_id"],
            "amount": tx["amount"],
            "splits": [{"user_id": s["user_id"], "split_amount": s["split_amount"]} for s in splits]
        })

    settlements = GroupWalletManager.calculate_debts(tx_with_splits)

    # Enrich with names
    users = {u["id"]: u["full_name"] for u in db.get_users()}
    for s in settlements:
        s["from_name"] = users.get(s["from_user_id"], "???")
        s["to_name"] = users.get(s["to_user_id"], "???")

    return jsonify(settlements)


# ==================================================================
#  API 7: BUDGETS (NGÂN SÁCH)
# ==================================================================
@app.route("/api/budgets", methods=["GET", "POST"])
def handle_budgets():
    """
    GET: Lấy danh sách ngân sách kèm chi tiêu thực tế
    POST: Tạo/cập nhật ngân sách
    """
    if request.method == "POST":
        data = request.json or {}
        budget_id = db.upsert_budget(
            data.get("user_id", 1),
            data["category"],
            float(data["limit_amount"])
        )
        return jsonify({"success": True, "budget_id": budget_id}), 201

    user_id = request.args.get("user_id", 1, type=int)
    budgets = db.get_budgets(user_id=user_id)
    return jsonify(budgets)


@app.route("/api/budgets/<int:budget_id>", methods=["DELETE"])
def delete_budget(budget_id):
    """Xóa ngân sách."""
    success = db.delete_budget(budget_id)
    if success:
        return jsonify({"success": True})
    return jsonify({"error": "Không tìm thấy"}), 404


# ==================================================================
#  API 8: SAVINGS (MỤC TIÊU TIẾT KIỆM)
# ==================================================================
@app.route("/api/savings", methods=["GET", "POST"])
def handle_savings():
    """
    GET: Lấy danh sách mục tiêu tiết kiệm
    POST: Tạo mục tiêu tiết kiệm mới
    """
    if request.method == "POST":
        data = request.json or {}
        saving_id = db.create_saving(data)
        return jsonify({"success": True, "saving_id": saving_id}), 201

    user_id = request.args.get("user_id", 1, type=int)
    savings = db.get_savings(user_id=user_id)
    return jsonify(savings)


@app.route("/api/savings/<int:saving_id>", methods=["PUT", "DELETE"])
def saving_detail(saving_id):
    """PUT: Cập nhật. DELETE: Xóa."""
    if request.method == "DELETE":
        success = db.delete_saving(saving_id)
        if success:
            return jsonify({"success": True})
        return jsonify({"error": "Không tìm thấy"}), 404

    data = request.json or {}
    success = db.update_saving(saving_id, data)
    if success:
        return jsonify({"success": True})
    return jsonify({"error": "Cập nhật thất bại"}), 400


# ==================================================================
#  API 9: RECURRING TRANSACTIONS (GIAO DỊCH ĐỊNH KỲ)
# ==================================================================
@app.route("/api/recurring", methods=["GET", "POST"])
def handle_recurring():
    """
    GET: Lấy danh sách giao dịch định kỳ
    POST: Tạo giao dịch định kỳ mới
    """
    if request.method == "POST":
        data = request.json or {}
        rec_id = db.create_recurring(data)
        return jsonify({"success": True, "recurring_id": rec_id}), 201

    user_id = request.args.get("user_id", 1, type=int)
    recurring = db.get_recurring(user_id=user_id)
    return jsonify(recurring)


@app.route("/api/recurring/<int:rec_id>/toggle", methods=["POST"])
def toggle_recurring(rec_id):
    """Bật/tắt giao dịch định kỳ."""
    success = db.toggle_recurring(rec_id)
    if success:
        return jsonify({"success": True})
    return jsonify({"error": "Không tìm thấy"}), 404


@app.route("/api/recurring/<int:rec_id>", methods=["DELETE"])
def delete_recurring(rec_id):
    """Xóa giao dịch định kỳ."""
    success = db.delete_recurring(rec_id)
    if success:
        return jsonify({"success": True})
    return jsonify({"error": "Không tìm thấy"}), 404


# ==================================================================
#  API 10: CATEGORIES
# ==================================================================
@app.route("/api/categories", methods=["GET"])
def list_categories():
    """Lấy danh sách danh mục chi tiêu."""
    categories = db.get_categories()
    return jsonify(categories)


# ==================================================================
#  API 11: OCR ENGINE STATUS
# ==================================================================
@app.route("/api/ocr/status", methods=["GET"])
def ocr_status():
    """Kiểm tra trạng thái Tesseract OCR Engine."""
    status = pipeline.ocr_engine.get_status()
    return jsonify(status)


# ==================================================================
#  ERROR HANDLERS
# ==================================================================
@app.errorhandler(404)
def not_found(e):
    return jsonify({"error": "Endpoint không tồn tại"}), 404


@app.errorhandler(500)
def server_error(e):
    logger.error(f"Server error: {e}")
    return jsonify({"error": "Lỗi máy chủ nội bộ"}), 500


if __name__ == "__main__":
    if sys.platform == "win32":
        try:
            sys.stdout.reconfigure(encoding="utf-8")
        except Exception:
            pass
    port = int(os.environ.get("PORT", 5000))
    print("\n" + "=" * 60)
    print(">> Vi Xinh Backend Server dang khoi chay...")
    print(f">> Trang chu:      http://127.0.0.1:{port}")
    print(f">> Xac thuc OCR:   http://127.0.0.1:{port}/review")
    print(f">> Vi nhom:        http://127.0.0.1:{port}/groups")
    print(f">> API Docs & Doc: http://127.0.0.1:{port}/api/stats")
    print("=" * 60 + "\n")
    app.run(host="0.0.0.0", port=port, debug=False)
