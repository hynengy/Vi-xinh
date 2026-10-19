"""
Unit Test Cho Nghiệp Vụ Chia Tiền Ví Nhóm (Split Bill)
Phụ trách: Thành viên 2 (Lê Thị Dịu) & Toàn nhóm kiểm thử
"""
import pytest
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent / "phase-1-web-demo"
sys.path.insert(0, str(BASE_DIR))

from backend.database.group_wallet import GroupWalletManager


def test_split_equally_five_members():
    total_bill = 250000.0
    member_ids = [1, 2, 3, 4, 5]
    result = GroupWalletManager.split_equally(total_bill, member_ids)

    assert result["member_count"] == 5
    assert result["per_person"] == 50000
    assert len(result["splits"]) == 5
    for split in result["splits"]:
        assert split["split_amount"] == 50000


def test_split_equally_with_remainder():
    """Test chia đều khi có phần dư."""
    total_bill = 100000.0
    member_ids = [1, 2, 3]
    result = GroupWalletManager.split_equally(total_bill, member_ids)

    assert result["member_count"] == 3
    total_splits = sum(s["split_amount"] for s in result["splits"])
    assert total_splits == total_bill


def test_split_equally_empty_members():
    result = GroupWalletManager.split_equally(100000, [])
    assert result["per_person"] == 0
    assert result["splits"] == []


def test_split_by_percentage():
    total_bill = 1000000.0
    percentages = {1: 50, 2: 30, 3: 20}
    result = GroupWalletManager.split_by_percentage(total_bill, percentages)

    assert len(result["splits"]) == 3
    amounts = {s["user_id"]: s["split_amount"] for s in result["splits"]}
    assert amounts[1] == 500000
    assert amounts[2] == 300000
    assert amounts[3] == 200000


def test_calculate_debts_settlement():
    # Thành viên 1 trả 300k cho cả nhóm 3 người (1, 2, 3)
    # Tức mỗi người chịu 100k -> 2 nợ 1: 100k, 3 nợ 1: 100k
    tx_data = [
        {
            "user_id": 1,
            "amount": 300000.0,
            "splits": [
                {"user_id": 1, "split_amount": 100000.0},
                {"user_id": 2, "split_amount": 100000.0},
                {"user_id": 3, "split_amount": 100000.0},
            ]
        }
    ]
    debts = GroupWalletManager.calculate_debts(tx_data)
    assert len(debts) == 2
    # Người nhận là 1
    assert all(d["to_user_id"] == 1 for d in debts)
    total_owed = sum(d["amount"] for d in debts)
    assert total_owed == 200000


def test_calculate_debts_multiple_payers():
    """Test khi nhiều người trả tiền lần lượt."""
    tx_data = [
        {
            "user_id": 1,
            "amount": 300000.0,
            "splits": [
                {"user_id": 1, "split_amount": 100000.0},
                {"user_id": 2, "split_amount": 100000.0},
                {"user_id": 3, "split_amount": 100000.0},
            ]
        },
        {
            "user_id": 2,
            "amount": 150000.0,
            "splits": [
                {"user_id": 1, "split_amount": 50000.0},
                {"user_id": 2, "split_amount": 50000.0},
                {"user_id": 3, "split_amount": 50000.0},
            ]
        }
    ]
    debts = GroupWalletManager.calculate_debts(tx_data)
    # User 3 nợ cả user 1 và user 2
    assert len(debts) >= 1
    total_from_3 = sum(d["amount"] for d in debts if d["from_user_id"] == 3)
    assert total_from_3 == 150000  # Nợ 100k user1 + 50k user2
