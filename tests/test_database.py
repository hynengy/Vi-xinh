"""
Unit Test Cho Module Quản Lý CSDL (DatabaseManager)
Phụ trách: Thành viên 2 (Lê Thị Dịu) & Thành viên 5 (Nguyễn Việt Anh)
"""
import pytest
import sys
import tempfile
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent / "phase-1-web-demo"
sys.path.insert(0, str(BASE_DIR))

from backend.database.db_manager import DatabaseManager


@pytest.fixture
def db():
    """Tạo CSDL tạm cho mỗi test."""
    with tempfile.NamedTemporaryFile(suffix=".sqlite3", delete=False) as f:
        db_path = Path(f.name)
    manager = DatabaseManager(db_path, seed_demo=True)
    yield manager
    db_path.unlink(missing_ok=True)


# --- Users ---
def test_seed_users(db):
    users = db.get_users()
    assert len(users) == 5
    assert users[0]["full_name"] == "Thành viên 1"


def test_get_user(db):
    user = db.get_user(1)
    assert user is not None
    assert user["username"] == "user1"


def test_update_user(db):
    db.update_user(1, {"phone": "0999 000 111", "email": "new@email.vn"})
    user = db.get_user(1)
    assert user["phone"] == "0999 000 111"
    assert user["email"] == "new@email.vn"


def test_get_user_by_contact(db):
    # Tìm bằng email
    user_email = db.get_user_by_contact("user1@vixinh.vn")
    assert user_email is not None
    assert user_email["full_name"] == "Thành viên 1"

    # Tìm bằng số điện thoại (kể cả có hoặc không có dấu cách)
    user_phone = db.get_user_by_contact("0912345678")
    assert user_phone is not None
    assert user_phone["id"] == 1


def test_register_and_authenticate_real_user(db):
    # Đăng ký bằng email và SĐT thực
    new_user = db.register_user(
        full_name="Trần Minh Trang",
        email="trang.tran@gmail.com",
        phone="0988776655",
        password="MySecretPassword123"
    )
    assert new_user["id"] > 5
    assert new_user["email"] == "trang.tran@gmail.com"
    assert new_user["phone"] == "0988776655"

    # Xác thực bằng email thực
    auth1 = db.authenticate_user("trang.tran@gmail.com", "MySecretPassword123")
    assert auth1 is not None
    assert auth1["full_name"] == "Trần Minh Trang"

    # Xác thực bằng SĐT thực
    auth2 = db.authenticate_user("0988776655", "MySecretPassword123")
    assert auth2 is not None
    assert auth2["id"] == new_user["id"]

    # Sai mật khẩu
    auth_fail = db.authenticate_user("trang.tran@gmail.com", "WrongPassword")
    assert auth_fail is None


# --- Transactions ---
def test_add_and_get_transaction(db):
    tx_id = db.add_transaction({
        "user_id": 1,
        "merchant_name": "Test Store",
        "amount": 50000,
        "type": "expense",
        "transaction_date": "2026-10-17",
    })
    assert tx_id > 0

    transactions = db.get_recent_transactions(user_id=1)
    names = [t["merchant_name"] for t in transactions]
    assert "Test Store" in names


def test_delete_transaction(db):
    tx_id = db.add_transaction({
        "user_id": 1,
        "merchant_name": "To Delete",
        "amount": 10000,
        "type": "expense",
        "transaction_date": "2026-10-17",
    })
    assert db.delete_transaction(tx_id) is True
    assert db.delete_transaction(999999) is False


# --- Stats ---
def test_summary_stats(db):
    stats = db.get_summary_stats(user_id=1)
    assert "total_expense" in stats
    assert "total_income" in stats
    assert "balance" in stats
    assert "category_breakdown" in stats
    assert stats["transaction_count"] >= 0


# --- Groups ---
def test_seed_group(db):
    groups = db.get_groups()
    assert len(groups) >= 1
    assert "Quỹ" in groups[0]["name"] or "302" in groups[0]["name"]


def test_create_group(db):
    gid = db.create_group({
        "name": "Test Group",
        "description": "For testing",
        "created_by": 1,
        "member_ids": [2, 3]
    })
    assert gid > 0
    detail = db.get_group_detail(gid)
    assert detail is not None
    assert len(detail["members"]) == 3  # creator + 2 members


def test_group_fund(db):
    groups = db.get_groups()
    gid = groups[0]["id"]
    initial_balance = groups[0]["balance"]
    db.update_group_fund(gid, 1, 500000)
    detail = db.get_group_detail(gid)
    assert detail["balance"] == initial_balance + 500000


# --- Expense Splits ---
def test_expense_splits(db):
    tx_id = db.add_transaction({
        "user_id": 1, "group_id": 1,
        "merchant_name": "Room Rent",
        "amount": 4500000,
        "type": "expense",
        "transaction_date": "2026-10-15",
    })
    splits = [
        {"user_id": 1, "split_amount": 1125000},
        {"user_id": 2, "split_amount": 1125000},
        {"user_id": 3, "split_amount": 1125000},
        {"user_id": 4, "split_amount": 1125000},
    ]
    db.create_expense_splits(tx_id, splits)

    result = db.get_expense_splits(tx_id)
    assert len(result) == 4

    # Settle one split
    split_id = result[0]["id"]
    db.settle_split(split_id)
    updated = db.get_expense_splits(tx_id)
    settled = [s for s in updated if s["is_settled"]]
    assert len(settled) == 1


# --- Budgets ---
def test_budgets(db):
    budgets = db.get_budgets(user_id=1)
    assert len(budgets) >= 1  # Seed data has budgets

    bid = db.upsert_budget(1, "food", 5000000)
    assert bid > 0

    # Update existing
    bid2 = db.upsert_budget(1, "food", 6000000)
    assert bid2 == bid  # Same budget updated


def test_delete_budget(db):
    bid = db.upsert_budget(1, "test_cat", 100000)
    assert db.delete_budget(bid) is True


# --- Savings ---
def test_savings(db):
    savings = db.get_savings(user_id=1)
    assert len(savings) >= 1  # Seed data

    sid = db.create_saving({
        "user_id": 1,
        "name": "Test Goal",
        "target_amount": 1000000,
    })
    assert sid > 0

    db.update_saving(sid, {"saved_amount": 500000})
    updated = db.get_savings(user_id=1)
    test_goal = [s for s in updated if s["name"] == "Test Goal"][0]
    assert test_goal["saved_amount"] == 500000

    assert db.delete_saving(sid) is True


# --- Recurring ---
def test_recurring(db):
    recurring = db.get_recurring(user_id=1)
    assert len(recurring) >= 1  # Seed data

    rid = db.create_recurring({
        "user_id": 1,
        "name": "Test Recurring",
        "amount": 99000,
        "frequency": "monthly",
    })
    assert rid > 0

    db.toggle_recurring(rid)
    updated = db.get_recurring(user_id=1)
    test_rec = [r for r in updated if r["name"] == "Test Recurring"][0]
    assert test_rec["is_active"] == 0  # Toggled off

    assert db.delete_recurring(rid) is True


# --- Categories ---
def test_categories(db):
    cats = db.get_categories()
    assert len(cats) >= 9
    keys = [c["key"] for c in cats]
    assert "food" in keys
    assert "salary" in keys
