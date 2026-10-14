"""
Quản Lý Cơ Sở Dữ Liệu SQLite
Phụ trách: Thành viên 2 - Lê Thị Dịu
Nhiệm vụ: Tạo bảng, quản lý kết nối, lưu trữ giao dịch cá nhân và ví nhóm
"""
import sqlite3
from typing import List, Dict, Any, Optional
from pathlib import Path


class DatabaseManager:
    """Quản lý kết nối và các câu truy vấn tới SQLite."""

    def __init__(self, db_path: Path):
        self.db_path = str(db_path)
        self.init_database()

    def get_connection(self) -> sqlite3.Connection:
        """Tạo kết nối với CSDL với cấu hình row_factory dạng Dict."""
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
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
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
            """)

            # 2. Bảng groups (Ví nhóm)
            cursor.execute("""
            CREATE TABLE IF NOT EXISTS groups (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                description TEXT,
                created_by INTEGER,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (created_by) REFERENCES users (id)
            )
            """)

            # 3. Bảng group_members
            cursor.execute("""
            CREATE TABLE IF NOT EXISTS group_members (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                group_id INTEGER NOT NULL,
                user_id INTEGER NOT NULL,
                role TEXT DEFAULT 'member',
                FOREIGN KEY (group_id) REFERENCES groups (id),
                FOREIGN KEY (user_id) REFERENCES users (id)
            )
            """)

            # 4. Bảng transactions
            cursor.execute("""
            CREATE TABLE IF NOT EXISTS transactions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                group_id INTEGER,
                category TEXT DEFAULT 'Khác',
                merchant_name TEXT NOT NULL,
                amount REAL NOT NULL,
                transaction_date TEXT NOT NULL,
                receipt_image_path TEXT,
                raw_ocr_text TEXT,
                notes TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users (id),
                FOREIGN KEY (group_id) REFERENCES groups (id)
            )
            """)

            # 5. Bảng expense_splits (Chia tiền nhóm)
            cursor.execute("""
            CREATE TABLE IF NOT EXISTS expense_splits (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                transaction_id INTEGER NOT NULL,
                user_id INTEGER NOT NULL,
                split_amount REAL NOT NULL,
                is_settled INTEGER DEFAULT 0,
                FOREIGN KEY (transaction_id) REFERENCES transactions (id),
                FOREIGN KEY (user_id) REFERENCES users (id)
            )
            """)

            # Tạo người dùng mẫu cho nhóm 5 thành viên
            cursor.execute("SELECT COUNT(*) FROM users")
            if cursor.fetchone()[0] == 0:
                seed_users = [
                    ("thuyhien", "Nguyễn Thúy Hiền", "hien@vixinh.vn"),
                    ("thidiu", "Lê Thị Dịu", "diu@vixinh.vn"),
                    ("tienquan", "Lê Tiến Quân", "quan@vixinh.vn"),
                    ("ngocduy", "Lê Ngọc Duy", "duy@vixinh.vn"),
                    ("vietanh", "Nguyễn Việt Anh", "vietanh@vixinh.vn"),
                ]
                cursor.executemany(
                    "INSERT INTO users (username, full_name, email) VALUES (?, ?, ?)",
                    seed_users
                )

                # Tạo nhóm mẫu
                cursor.execute(
                    "INSERT INTO groups (name, description, created_by) VALUES (?, ?, ?)",
                    ("Nhóm 05 - Ví Xinh", "Ví chi tiêu chung đồ án thực tập", 1)
                )
                group_id = cursor.lastrowid
                for u_id in range(1, 6):
                    cursor.execute(
                        "INSERT INTO group_members (group_id, user_id, role) VALUES (?, ?, ?)",
                        (group_id, u_id, "admin" if u_id == 1 else "member")
                    )

            conn.commit()

    # --- Thao tác Transaction ---
    def add_transaction(self, tx_data: Dict[str, Any]) -> int:
        """Lưu giao dịch mới vào CSDL."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
            INSERT INTO transactions (
                user_id, group_id, category, merchant_name, amount,
                transaction_date, receipt_image_path, raw_ocr_text, notes
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                tx_data.get("user_id", 1),
                tx_data.get("group_id"),
                tx_data.get("category", "Ăn uống"),
                tx_data.get("merchant_name", "Không xác định"),
                tx_data.get("amount", 0.0),
                tx_data.get("transaction_date"),
                tx_data.get("receipt_image_path"),
                tx_data.get("raw_ocr_text"),
                tx_data.get("notes")
            ))
            conn.commit()
            return cursor.lastrowid

    def get_recent_transactions(self, limit: int = 20) -> List[Dict[str, Any]]:
        """Lấy danh sách các giao dịch gần nhất."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
            SELECT t.*, u.full_name as paid_by_name, g.name as group_name
            FROM transactions t
            LEFT JOIN users u ON t.user_id = u.id
            LEFT JOIN groups g ON t.group_id = g.id
            ORDER BY t.transaction_date DESC, t.id DESC
            LIMIT ?
            """, (limit,))
            return [dict(row) for row in cursor.fetchall()]

    def get_summary_stats(self) -> Dict[str, Any]:
        """Tính toán tổng chi tiêu cá nhân, nhóm và số giao dịch."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT COALESCE(SUM(amount), 0), COUNT(*) FROM transactions")
            total_spent, tx_count = cursor.fetchone()

            cursor.execute("""
            SELECT category, SUM(amount) as cat_amount
            FROM transactions
            GROUP BY category
            ORDER BY cat_amount DESC
            """)
            category_breakdown = [dict(row) for row in cursor.fetchall()]

            return {
                "total_spent": total_spent,
                "transaction_count": tx_count,
                "category_breakdown": category_breakdown
            }

    # --- Thao tác Ví nhóm & Users ---
    def get_groups(self) -> List[Dict[str, Any]]:
        """Lấy danh sách ví nhóm."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM groups ORDER BY id DESC")
            return [dict(row) for row in cursor.fetchall()]

    def get_users(self) -> List[Dict[str, Any]]:
        """Lấy danh sách thành viên."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT id, username, full_name, email FROM users ORDER BY id ASC")
            return [dict(row) for row in cursor.fetchall()]

    def get_group_members(self, group_id: int) -> List[Dict[str, Any]]:
        """Lấy thành viên của một nhóm."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
            SELECT u.id, u.full_name, u.username, gm.role
            FROM group_members gm
            JOIN users u ON gm.user_id = u.id
            WHERE gm.group_id = ?
            """, (group_id,))
            return [dict(row) for row in cursor.fetchall()]
