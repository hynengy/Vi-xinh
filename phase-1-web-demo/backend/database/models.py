"""
Cấu Trúc Dữ Liệu & Models CSDL
Phụ trách: Thành viên 2 - Lê Thị Dịu
"""
from dataclasses import dataclass
from typing import Optional


@dataclass
class User:
    id: Optional[int]
    username: str
    full_name: str
    email: Optional[str] = None


@dataclass
class Group:
    id: Optional[int]
    name: str
    description: Optional[str] = None
    created_by: int = 1


@dataclass
class Transaction:
    id: Optional[int]
    user_id: int
    merchant_name: str
    amount: float
    transaction_date: str
    group_id: Optional[int] = None
    category: str = "Khác"
    receipt_image_path: Optional[str] = None
    raw_ocr_text: Optional[str] = None
    notes: Optional[str] = None


@dataclass
class ExpenseSplit:
    id: Optional[int]
    transaction_id: int
    user_id: int
    split_amount: float
    is_settled: bool = False
