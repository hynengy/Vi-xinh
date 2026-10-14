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
    splits = GroupWalletManager.split_equally(total_bill, member_ids)

    assert len(splits) == 5
    for m_id in member_ids:
        assert splits[m_id] == 50000.0


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
