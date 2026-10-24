"""
Quản Lý Cơ Sở Dữ Liệu SQLite
Phụ trách: Thành viên 2 - Lê Thị Dịu
Nhiệm vụ: Tạo bảng, quản lý kết nối, lưu trữ giao dịch cá nhân và ví nhóm
"""
import sqlite3
from datetime import datetime, date
from typing import List, Dict, Any, Optional
from pathlib import Path


class DatabaseManager:
    """Quản lý kết nối và các câu truy vấn tới SQLite."""

    def __init__(self, db_path: Path, seed_demo: bool = False):
        self.db_path = str(db_path)
        try:
            Path(self.db_path).parent.mkdir(parents=True, exist_ok=True)
        except Exception:
            pass
        self.seed_demo = seed_demo
        self.init_database()

    def get_connection(self) -> sqlite3.Connection:
        """Tạo kết nối với CSDL với cấu hình row_factory dạng Dict."""
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        conn.execute("PRAGMA foreign_keys = ON")
        return conn

    def init_database(self) -> None:
        """Khởi tạo toàn bộ cấu trúc bảng và dữ liệu mẫu nếu chưa có."""
        with self.get_connection() as conn:
            cursor = conn.cursor()

            # 1. Bảng users
            cursor.execute("""
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT UNIQUE NOT NULL,
                full_name TEXT NOT NULL,
                email TEXT,
                phone TEXT,
                avatar_url TEXT,
                password_hash TEXT DEFAULT '123456',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
            """)
            try:
                cursor.execute("ALTER TABLE users ADD COLUMN password_hash TEXT DEFAULT '123456'")
            except sqlite3.OperationalError:
                pass

            # 2. Bảng categories
            cursor.execute("""
            CREATE TABLE IF NOT EXISTS categories (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                key TEXT UNIQUE NOT NULL,
                name TEXT NOT NULL,
                icon TEXT,
                type TEXT DEFAULT 'expense'
            )
            """)

            # 3. Bảng groups (Ví nhóm)
            cursor.execute("""
            CREATE TABLE IF NOT EXISTS groups (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                description TEXT,
                created_by INTEGER,
                balance REAL DEFAULT 0,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (created_by) REFERENCES users (id)
            )
            """)

            # 4. Bảng group_members
            cursor.execute("""
            CREATE TABLE IF NOT EXISTS group_members (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                group_id INTEGER NOT NULL,
                user_id INTEGER NOT NULL,
                role TEXT DEFAULT 'member',
                paid_fund REAL DEFAULT 0,
                FOREIGN KEY (group_id) REFERENCES groups (id),
                FOREIGN KEY (user_id) REFERENCES users (id),
                UNIQUE(group_id, user_id)
            )
            """)

            # 5. Bảng transactions
            cursor.execute("""
            CREATE TABLE IF NOT EXISTS transactions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                group_id INTEGER,
                category TEXT DEFAULT 'other',
                merchant_name TEXT NOT NULL,
                amount REAL NOT NULL,
                type TEXT DEFAULT 'expense',
                transaction_date TEXT NOT NULL,
                transaction_time TEXT DEFAULT '00:00',
                receipt_image_path TEXT,
                raw_ocr_text TEXT,
                notes TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users (id),
                FOREIGN KEY (group_id) REFERENCES groups (id)
            )
            """)

            # 6. Bảng expense_splits (Chia tiền nhóm)
            cursor.execute("""
            CREATE TABLE IF NOT EXISTS expense_splits (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                transaction_id INTEGER NOT NULL,
                user_id INTEGER NOT NULL,
                split_amount REAL NOT NULL,
                is_settled INTEGER DEFAULT 0,
                settled_at TIMESTAMP,
                FOREIGN KEY (transaction_id) REFERENCES transactions (id),
                FOREIGN KEY (user_id) REFERENCES users (id)
            )
            """)

            # 7. Bảng budgets (Ngân sách)
            cursor.execute("""
            CREATE TABLE IF NOT EXISTS budgets (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                category TEXT NOT NULL,
                limit_amount REAL NOT NULL,
                month TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users (id)
            )
            """)

            # 8. Bảng savings (Mục tiêu tiết kiệm)
            cursor.execute("""
            CREATE TABLE IF NOT EXISTS savings (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                name TEXT NOT NULL,
                icon TEXT DEFAULT 'gift',
                target_amount REAL NOT NULL,
                saved_amount REAL DEFAULT 0,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users (id)
            )
            """)

            # 9. Bảng recurring_transactions (Giao dịch định kỳ)
            cursor.execute("""
            CREATE TABLE IF NOT EXISTS recurring_transactions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                name TEXT NOT NULL,
                amount REAL NOT NULL,
                frequency TEXT DEFAULT 'monthly',
                category TEXT DEFAULT 'bills',
                is_active INTEGER DEFAULT 1,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users (id)
            )
            """)

            # Khởi tạo danh mục mặc định
            cursor.execute("SELECT COUNT(*) FROM categories")
            if cursor.fetchone()[0] == 0:
                self._seed_categories(cursor)

            # Chỉ nạp tài khoản mẫu khi bật seed_demo (phục vụ unit test)
            if self.seed_demo:
                cursor.execute("SELECT COUNT(*) FROM users")
                if cursor.fetchone()[0] == 0:
                    self._seed_data(cursor)

            conn.commit()

    def _seed_categories(self, cursor: sqlite3.Cursor) -> None:
        """Khởi tạo danh mục chi tiêu chuẩn của hệ thống."""
        seed_cats = [
            ("food", "Ăn uống", "ri-restaurant-line", "expense"),
            ("transport", "Di chuyển", "ri-taxi-line", "expense"),
            ("shopping", "Mua sắm", "ri-shopping-bag-3-line", "expense"),
            ("entertainment", "Giải trí", "ri-gamepad-line", "expense"),
            ("health", "Sức khỏe", "ri-heart-pulse-line", "expense"),
            ("education", "Học tập", "ri-book-open-line", "expense"),
            ("bills", "Hoá đơn", "ri-bill-line", "expense"),
            ("salary", "Lương", "ri-money-dollar-circle-line", "income"),
            ("other", "Khác", "ri-archive-line", "expense"),
        ]
        cursor.executemany(
            "INSERT OR IGNORE INTO categories (key, name, icon, type) VALUES (?, ?, ?, ?)",
            seed_cats
        )

    def _seed_data(self, cursor: sqlite3.Cursor) -> None:
        """Tạo dữ liệu mẫu cho nhóm 5 thành viên (dùng cho test suite)."""
        # Users
        seed_users = [
            ("user1", "Thành viên 1", "user1@vixinh.vn", "0912 345 678", "123456"),
            ("thidiu", "Lê Thị Dịu", "diu@vixinh.vn", "0987 654 321", "123456"),
            ("tienquan", "Lê Tiến Quân", "quan@vixinh.vn", "0934 567 890", "123456"),
            ("ngocduy", "Lê Ngọc Duy", "duy@vixinh.vn", "0903 112 233", "123456"),
            ("vietanh", "Nguyễn Việt Anh", "vietanh@vixinh.vn", "0978 123 456", "123456"),
        ]
        cursor.executemany(
            "INSERT INTO users (username, full_name, email, phone, password_hash) VALUES (?, ?, ?, ?, ?)",
            seed_users
        )


        # Tạo nhóm mẫu
        cursor.execute(
            "INSERT INTO groups (name, description, created_by, balance) VALUES (?, ?, ?, ?)",
            ("Quỹ Chi Tiêu Chung", "Quỹ sinh hoạt chi tiêu chung các thành viên", 1, 2400000)
        )
        group_id = cursor.lastrowid
        for u_id in range(1, 6):
            cursor.execute(
                "INSERT INTO group_members (group_id, user_id, role, paid_fund) VALUES (?, ?, ?, ?)",
                (group_id, u_id, "admin" if u_id == 1 else "member", 1500000 if u_id <= 4 else 0)
            )

        # Giao dịch: Để trống 100% khi khởi tạo để người dùng tự nhập hoặc quét hóa đơn thật
        seed_transactions = []
        if seed_transactions:
            cursor.executemany(
                """INSERT INTO transactions
                   (user_id, group_id, category, merchant_name, amount, type, transaction_date, transaction_time)
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
                seed_transactions
            )

        # Budgets mẫu
        seed_budgets = [
            (1, "food", 3000000),
            (1, "transport", 800000),
            (1, "shopping", 1500000),
            (1, "entertainment", 500000),
            (1, "bills", 1000000),
            (1, "education", 500000),
        ]
        cursor.executemany(
            "INSERT INTO budgets (user_id, category, limit_amount) VALUES (?, ?, ?)",
            seed_budgets
        )

        # Savings mẫu
        seed_savings = [
            (1, "Mua Laptop mới", "laptop", 15000000, 8500000),
            (1, "Du lịch Đà Lạt", "travel", 5000000, 2200000),
            (1, "Quỹ khẩn cấp", "gift", 10000000, 4300000),
        ]
        cursor.executemany(
            "INSERT INTO savings (user_id, name, icon, target_amount, saved_amount) VALUES (?, ?, ?, ?, ?)",
            seed_savings
        )

        # Recurring mẫu
        seed_recurring = [
            (1, "Tiền nhà", 3500000, "monthly", "bills", 1),
            (1, "Tiền điện", 400000, "monthly", "bills", 1),
            (1, "Internet", 200000, "monthly", "bills", 1),
            (1, "Spotify", 59000, "monthly", "entertainment", 1),
            (1, "Cà phê sáng", 35000, "daily", "food", 0),
        ]
        cursor.executemany(
            """INSERT INTO recurring_transactions
               (user_id, name, amount, frequency, category, is_active) VALUES (?, ?, ?, ?, ?, ?)""",
            seed_recurring
        )

    # ================================================================
    #  USER CRUD
    # ================================================================
    def get_users(self) -> List[Dict[str, Any]]:
        """Lấy danh sách thành viên."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT id, username, full_name, email, phone, avatar_url FROM users ORDER BY id ASC")
            return [dict(row) for row in cursor.fetchall()]

    def get_user(self, user_id: int) -> Optional[Dict[str, Any]]:
        """Lấy thông tin 1 người dùng."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,))
            row = cursor.fetchone()
            return dict(row) if row else None

    def update_user(self, user_id: int, data: Dict[str, Any]) -> bool:
        """Cập nhật thông tin người dùng (email, phone, full_name, avatar_url)."""
        fields = []
        values = []
        for key in ("full_name", "email", "phone", "avatar_url"):
            if key in data:
                fields.append(f"{key} = ?")
                values.append(data[key])
        if not fields:
            return False
        values.append(user_id)
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(f"UPDATE users SET {', '.join(fields)} WHERE id = ?", values)
            conn.commit()
            return cursor.rowcount > 0

    def get_user_by_contact(self, contact: str) -> Optional[Dict[str, Any]]:
        """Tìm người dùng qua Email hoặc Số điện thoại thực tế."""
        if not contact:
            return None
        clean_contact = contact.strip()
        clean_phone = clean_contact.replace(" ", "").replace("-", "").replace(".", "").replace("+84", "0")
        if clean_phone.startswith("84") and len(clean_phone) >= 11:
            clean_phone = "0" + clean_phone[2:]
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                SELECT * FROM users 
                WHERE LOWER(TRIM(COALESCE(email, ''))) = LOWER(?) 
                   OR phone = ? 
                   OR REPLACE(REPLACE(REPLACE(REPLACE(COALESCE(phone, ''), ' ', ''), '-', ''), '.', ''), '+84', '0') = ?
                   OR LOWER(username) = LOWER(?)
            """, (clean_contact, clean_contact, clean_phone, clean_contact))
            row = cursor.fetchone()
            return dict(row) if row else None

    def register_user(self, full_name: str, email: Optional[str] = None, phone: Optional[str] = None, password: str = "123456") -> Dict[str, Any]:
        """Đăng ký tài khoản người dùng mới bằng Email hoặc SĐT thực."""
        # Chuẩn hóa
        clean_email = email.strip().lower() if email else None
        clean_phone = phone.strip() if phone else None
        if clean_phone:
            clean_phone = clean_phone.replace(" ", "").replace("-", "").replace(".", "").replace("+84", "0")
            if clean_phone.startswith("84") and len(clean_phone) >= 11:
                clean_phone = "0" + clean_phone[2:]
        clean_name = full_name.strip() if full_name else "Người dùng Ví Xinh"

        # Sinh username tự động
        if clean_email:
            base_user = clean_email.split("@")[0].lower()
        elif clean_phone:
            base_user = "user_" + clean_phone.replace(" ", "").replace("-", "")[-4:]
        else:
            base_user = "user_" + str(int(datetime.now().timestamp()))

        import re
        base_user = re.sub(r"[^a-zA-Z0-9_]", "", base_user) or "user"
        username = base_user
        counter = 1

        with self.get_connection() as conn:
            cursor = conn.cursor()
            while True:
                cursor.execute("SELECT COUNT(*) FROM users WHERE username = ?", (username,))
                if cursor.fetchone()[0] == 0:
                    break
                username = f"{base_user}_{counter}"
                counter += 1

            cursor.execute("""
                INSERT INTO users (username, full_name, email, phone, password_hash, avatar_url)
                VALUES (?, ?, ?, ?, ?, ?)
            """, (username, clean_name, clean_email, clean_phone, password, "assets/logo.jpg"))
            user_id = cursor.lastrowid
            conn.commit()

            cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,))
            return dict(cursor.fetchone())

    def authenticate_user(self, identifier: str, password: str) -> Optional[Dict[str, Any]]:
        """Xác thực đăng nhập bằng email hoặc số điện thoại thực."""
        user = self.get_user_by_contact(identifier)
        if not user:
            return None
        stored_pw = user.get("password_hash")
        # Khớp mật khẩu chính xác
        if stored_pw and stored_pw == password:
            return user
        return None

    # ================================================================
    #  TRANSACTION CRUD
    # ================================================================
    def add_transaction(self, tx_data: Dict[str, Any]) -> int:
        """Lưu giao dịch mới vào CSDL."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
            INSERT INTO transactions (
                user_id, group_id, category, merchant_name, amount, type,
                transaction_date, transaction_time, receipt_image_path, raw_ocr_text, notes
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                tx_data.get("user_id", 1),
                tx_data.get("group_id"),
                tx_data.get("category", "other"),
                tx_data.get("merchant_name", "Không xác định"),
                tx_data.get("amount", 0.0),
                tx_data.get("type", "expense"),
                tx_data.get("transaction_date", date.today().isoformat()),
                tx_data.get("transaction_time", "00:00"),
                tx_data.get("receipt_image_path"),
                tx_data.get("raw_ocr_text"),
                tx_data.get("notes")
            ))
            conn.commit()
            return cursor.lastrowid

    def get_recent_transactions(self, user_id: int = 1, limit: int = 30) -> List[Dict[str, Any]]:
        """Lấy danh sách các giao dịch gần nhất."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
            SELECT t.*, u.full_name as paid_by_name, g.name as group_name
            FROM transactions t
            LEFT JOIN users u ON t.user_id = u.id
            LEFT JOIN groups g ON t.group_id = g.id
            WHERE t.user_id = ?
            ORDER BY t.transaction_date DESC, t.transaction_time DESC, t.id DESC
            LIMIT ?
            """, (user_id, limit))
            return [dict(row) for row in cursor.fetchall()]

    def delete_transaction(self, tx_id: int) -> bool:
        """Xóa giao dịch."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("DELETE FROM expense_splits WHERE transaction_id = ?", (tx_id,))
            cursor.execute("DELETE FROM transactions WHERE id = ?", (tx_id,))
            conn.commit()
            return cursor.rowcount > 0

    def get_transactions_by_date_range(self, user_id: int, start_date: str, end_date: str) -> List[Dict[str, Any]]:
        """Lấy giao dịch trong khoảng ngày."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
            SELECT * FROM transactions
            WHERE user_id = ? AND transaction_date BETWEEN ? AND ?
            ORDER BY transaction_date DESC, transaction_time DESC
            """, (user_id, start_date, end_date))
            return [dict(row) for row in cursor.fetchall()]

    # ================================================================
    #  STATISTICS
    # ================================================================
    def get_summary_stats(self, user_id: int = 1) -> Dict[str, Any]:
        """Tính toán tổng chi tiêu cá nhân, nhóm và số giao dịch."""
        with self.get_connection() as conn:
            cursor = conn.cursor()

            # Tổng chi
            cursor.execute(
                "SELECT COALESCE(SUM(amount), 0) FROM transactions WHERE user_id = ? AND type = 'expense'",
                (user_id,)
            )
            total_expense = cursor.fetchone()[0]

            # Tổng thu
            cursor.execute(
                "SELECT COALESCE(SUM(amount), 0) FROM transactions WHERE user_id = ? AND type = 'income'",
                (user_id,)
            )
            total_income = cursor.fetchone()[0]

            # Số giao dịch
            cursor.execute("SELECT COUNT(*) FROM transactions WHERE user_id = ?", (user_id,))
            tx_count = cursor.fetchone()[0]

            # Phân bổ theo danh mục
            cursor.execute("""
            SELECT category, SUM(amount) as cat_amount, COUNT(*) as cat_count
            FROM transactions WHERE user_id = ? AND type = 'expense'
            GROUP BY category ORDER BY cat_amount DESC
            """, (user_id,))
            category_breakdown = [dict(row) for row in cursor.fetchall()]

            # Chi tiêu theo tháng hiện tại
            current_month = date.today().strftime("%Y-%m")
            cursor.execute("""
            SELECT COALESCE(SUM(amount), 0) FROM transactions
            WHERE user_id = ? AND type = 'expense' AND transaction_date LIKE ?
            """, (user_id, f"{current_month}%"))
            monthly_expense = cursor.fetchone()[0]

            cursor.execute("""
            SELECT COALESCE(SUM(amount), 0) FROM transactions
            WHERE user_id = ? AND type = 'income' AND transaction_date LIKE ?
            """, (user_id, f"{current_month}%"))
            monthly_income = cursor.fetchone()[0]

            return {
                "total_expense": total_expense,
                "total_income": total_income,
                "balance": total_income - total_expense,
                "transaction_count": tx_count,
                "category_breakdown": category_breakdown,
                "monthly_expense": monthly_expense,
                "monthly_income": monthly_income,
            }

    def get_monthly_chart_data(self, user_id: int = 1, months: int = 6) -> List[Dict[str, Any]]:
        """Lấy dữ liệu biểu đồ chi tiêu theo tháng."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
            SELECT
                strftime('%Y-%m', transaction_date) as month,
                SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) as expense,
                SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) as income
            FROM transactions WHERE user_id = ?
            GROUP BY month ORDER BY month DESC LIMIT ?
            """, (user_id, months))
            return [dict(row) for row in cursor.fetchall()]

    # ================================================================
    #  GROUP & MEMBER CRUD
    # ================================================================
    def get_groups(self, user_id: int = None) -> List[Dict[str, Any]]:
        """Lấy danh sách ví nhóm (tùy chọn lọc theo user_id)."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            if user_id:
                cursor.execute("""
                SELECT g.*, u.full_name as creator_name,
                       (SELECT COUNT(*) FROM group_members WHERE group_id = g.id) as member_count
                FROM groups g
                LEFT JOIN users u ON g.created_by = u.id
                JOIN group_members gm ON gm.group_id = g.id AND gm.user_id = ?
                ORDER BY g.id DESC
                """, (user_id,))
            else:
                cursor.execute("""
                SELECT g.*, u.full_name as creator_name,
                       (SELECT COUNT(*) FROM group_members WHERE group_id = g.id) as member_count
                FROM groups g
                LEFT JOIN users u ON g.created_by = u.id
                ORDER BY g.id DESC
                """)
            return [dict(row) for row in cursor.fetchall()]

    def create_group(self, data: Dict[str, Any]) -> int:
        """Tạo ví nhóm mới."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(
                "INSERT INTO groups (name, description, created_by) VALUES (?, ?, ?)",
                (data.get("name"), data.get("description", ""), data.get("created_by", 1))
            )
            group_id = cursor.lastrowid
            # Thêm người tạo làm admin
            cursor.execute(
                "INSERT INTO group_members (group_id, user_id, role) VALUES (?, ?, 'admin')",
                (group_id, data.get("created_by", 1))
            )
            # Thêm các thành viên khác
            for member_id in data.get("member_ids", []):
                if member_id != data.get("created_by", 1):
                    cursor.execute(
                        "INSERT OR IGNORE INTO group_members (group_id, user_id, role) VALUES (?, ?, 'member')",
                        (group_id, member_id)
                    )
            conn.commit()
            return group_id

    def get_group_detail(self, group_id: int) -> Optional[Dict[str, Any]]:
        """Lấy chi tiết ví nhóm bao gồm thành viên và giao dịch."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM groups WHERE id = ?", (group_id,))
            group_row = cursor.fetchone()
            if not group_row:
                return None

            group = dict(group_row)

            # Members
            cursor.execute("""
            SELECT u.id, u.full_name, u.username, u.phone, u.avatar_url, gm.role, gm.paid_fund
            FROM group_members gm
            JOIN users u ON gm.user_id = u.id
            WHERE gm.group_id = ?
            """, (group_id,))
            group["members"] = [dict(row) for row in cursor.fetchall()]

            # Group transactions
            cursor.execute("""
            SELECT t.*, u.full_name as paid_by_name
            FROM transactions t
            JOIN users u ON t.user_id = u.id
            WHERE t.group_id = ?
            ORDER BY t.transaction_date DESC LIMIT 20
            """, (group_id,))
            group["transactions"] = [dict(row) for row in cursor.fetchall()]

            return group

    def get_group_members(self, group_id: int) -> List[Dict[str, Any]]:
        """Lấy thành viên của một nhóm."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
            SELECT u.id, u.full_name, u.username, u.phone, gm.role, gm.paid_fund
            FROM group_members gm
            JOIN users u ON gm.user_id = u.id
            WHERE gm.group_id = ?
            """, (group_id,))
            return [dict(row) for row in cursor.fetchall()]

    def add_group_member(self, group_id: int, user_id: int, role: str = "member") -> bool:
        """Thêm thành viên vào nhóm."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            try:
                cursor.execute(
                    "INSERT INTO group_members (group_id, user_id, role) VALUES (?, ?, ?)",
                    (group_id, user_id, role)
                )
                conn.commit()
                return True
            except sqlite3.IntegrityError:
                return False

    def update_group_fund(self, group_id: int, user_id: int, amount: float) -> bool:
        """Cập nhật quỹ nhóm khi thành viên góp tiền."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(
                "UPDATE group_members SET paid_fund = paid_fund + ? WHERE group_id = ? AND user_id = ?",
                (amount, group_id, user_id)
            )
            cursor.execute(
                "UPDATE groups SET balance = balance + ? WHERE id = ?",
                (amount, group_id)
            )
            conn.commit()
            return cursor.rowcount > 0

    # ================================================================
    #  EXPENSE SPLITS
    # ================================================================
    def create_expense_splits(self, transaction_id: int, splits: List[Dict[str, Any]]) -> bool:
        """Tạo bản ghi chia tiền cho giao dịch nhóm."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            for split in splits:
                cursor.execute(
                    "INSERT INTO expense_splits (transaction_id, user_id, split_amount) VALUES (?, ?, ?)",
                    (transaction_id, split["user_id"], split["split_amount"])
                )
            conn.commit()
            return True

    def get_expense_splits(self, transaction_id: int) -> List[Dict[str, Any]]:
        """Lấy chi tiết chia tiền của 1 giao dịch."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
            SELECT es.*, u.full_name
            FROM expense_splits es
            JOIN users u ON es.user_id = u.id
            WHERE es.transaction_id = ?
            """, (transaction_id,))
            return [dict(row) for row in cursor.fetchall()]

    def settle_split(self, split_id: int) -> bool:
        """Đánh dấu 1 khoản chia đã được thanh toán."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(
                "UPDATE expense_splits SET is_settled = 1, settled_at = ? WHERE id = ?",
                (datetime.now().isoformat(), split_id)
            )
            conn.commit()
            return cursor.rowcount > 0

    def get_unsettled_debts(self, user_id: int) -> List[Dict[str, Any]]:
        """Lấy các khoản nợ chưa thanh toán của 1 người dùng."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
            SELECT es.*, t.merchant_name, t.amount as total_amount, t.transaction_date,
                   u_payer.full_name as payer_name
            FROM expense_splits es
            JOIN transactions t ON es.transaction_id = t.id
            JOIN users u_payer ON t.user_id = u_payer.id
            WHERE es.user_id = ? AND es.is_settled = 0
            ORDER BY t.transaction_date DESC
            """, (user_id,))
            return [dict(row) for row in cursor.fetchall()]

    # ================================================================
    #  BUDGET CRUD
    # ================================================================
    def get_budgets(self, user_id: int = 1) -> List[Dict[str, Any]]:
        """Lấy danh sách ngân sách kèm chi tiêu thực tế."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            current_month = date.today().strftime("%Y-%m")
            cursor.execute("""
            SELECT b.*,
                   COALESCE((
                       SELECT SUM(t.amount) FROM transactions t
                       WHERE t.user_id = b.user_id AND t.category = b.category
                       AND t.type = 'expense' AND t.transaction_date LIKE ?
                   ), 0) as spent
            FROM budgets b WHERE b.user_id = ?
            ORDER BY b.id ASC
            """, (f"{current_month}%", user_id))
            return [dict(row) for row in cursor.fetchall()]

    def upsert_budget(self, user_id: int, category: str, limit_amount: float) -> int:
        """Tạo hoặc cập nhật ngân sách theo danh mục."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(
                "SELECT id FROM budgets WHERE user_id = ? AND category = ?",
                (user_id, category)
            )
            existing = cursor.fetchone()
            if existing:
                cursor.execute(
                    "UPDATE budgets SET limit_amount = ? WHERE id = ?",
                    (limit_amount, existing[0])
                )
                conn.commit()
                return existing[0]
            else:
                cursor.execute(
                    "INSERT INTO budgets (user_id, category, limit_amount) VALUES (?, ?, ?)",
                    (user_id, category, limit_amount)
                )
                conn.commit()
                return cursor.lastrowid

    def delete_budget(self, budget_id: int) -> bool:
        """Xóa ngân sách."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("DELETE FROM budgets WHERE id = ?", (budget_id,))
            conn.commit()
            return cursor.rowcount > 0

    # ================================================================
    #  SAVINGS CRUD
    # ================================================================
    def get_savings(self, user_id: int = 1) -> List[Dict[str, Any]]:
        """Lấy danh sách mục tiêu tiết kiệm."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM savings WHERE user_id = ? ORDER BY id ASC", (user_id,))
            return [dict(row) for row in cursor.fetchall()]

    def create_saving(self, data: Dict[str, Any]) -> int:
        """Tạo mục tiêu tiết kiệm mới."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(
                "INSERT INTO savings (user_id, name, icon, target_amount, saved_amount) VALUES (?, ?, ?, ?, ?)",
                (data.get("user_id", 1), data["name"], data.get("icon", "gift"),
                 data["target_amount"], data.get("saved_amount", 0))
            )
            conn.commit()
            return cursor.lastrowid

    def update_saving(self, saving_id: int, data: Dict[str, Any]) -> bool:
        """Cập nhật mục tiêu tiết kiệm (thêm tiền)."""
        fields = []
        values = []
        for key in ("name", "icon", "target_amount", "saved_amount"):
            if key in data:
                fields.append(f"{key} = ?")
                values.append(data[key])
        if not fields:
            return False
        values.append(saving_id)
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(f"UPDATE savings SET {', '.join(fields)} WHERE id = ?", values)
            conn.commit()
            return cursor.rowcount > 0

    def delete_saving(self, saving_id: int) -> bool:
        """Xóa mục tiêu tiết kiệm."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("DELETE FROM savings WHERE id = ?", (saving_id,))
            conn.commit()
            return cursor.rowcount > 0

    # ================================================================
    #  RECURRING TRANSACTIONS
    # ================================================================
    def get_recurring(self, user_id: int = 1) -> List[Dict[str, Any]]:
        """Lấy danh sách giao dịch định kỳ."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(
                "SELECT * FROM recurring_transactions WHERE user_id = ? ORDER BY id ASC",
                (user_id,)
            )
            return [dict(row) for row in cursor.fetchall()]

    def create_recurring(self, data: Dict[str, Any]) -> int:
        """Tạo giao dịch định kỳ mới."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(
                """INSERT INTO recurring_transactions
                   (user_id, name, amount, frequency, category, is_active)
                   VALUES (?, ?, ?, ?, ?, ?)""",
                (data.get("user_id", 1), data["name"], data["amount"],
                 data.get("frequency", "monthly"), data.get("category", "bills"),
                 data.get("is_active", 1))
            )
            conn.commit()
            return cursor.lastrowid

    def toggle_recurring(self, recurring_id: int) -> bool:
        """Bật/tắt giao dịch định kỳ."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(
                "UPDATE recurring_transactions SET is_active = CASE WHEN is_active = 1 THEN 0 ELSE 1 END WHERE id = ?",
                (recurring_id,)
            )
            conn.commit()
            return cursor.rowcount > 0

    def delete_recurring(self, recurring_id: int) -> bool:
        """Xóa giao dịch định kỳ."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("DELETE FROM recurring_transactions WHERE id = ?", (recurring_id,))
            conn.commit()
            return cursor.rowcount > 0

    # ================================================================
    #  CATEGORIES
    # ================================================================
    def get_categories(self) -> List[Dict[str, Any]]:
        """Lấy danh sách danh mục chi tiêu."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM categories ORDER BY id ASC")
            return [dict(row) for row in cursor.fetchall()]
