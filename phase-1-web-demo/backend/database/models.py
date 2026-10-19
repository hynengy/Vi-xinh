"""
Cấu Trúc Dữ Liệu & Models CSDL
Phụ trách: Thành viên 2 - Lê Thị Dịu
"""
from dataclasses import dataclass, field
from typing import Optional, List


@dataclass
class User:
    id: Optional[int] = None
    username: str = ""
    full_name: str = ""
    email: Optional[str] = None
    phone: Optional[str] = None
    avatar_url: Optional[str] = None
    password_hash: Optional[str] = "123456"


@dataclass
class Category:
    id: Optional[int] = None
    key: str = ""
    name: str = ""
    icon: Optional[str] = None
    type: str = "expense"


@dataclass
class Group:
    id: Optional[int] = None
    name: str = ""
    description: Optional[str] = None
    created_by: int = 1
    balance: float = 0.0


@dataclass
class GroupMember:
    id: Optional[int] = None
    group_id: int = 0
    user_id: int = 0
    role: str = "member"
    paid_fund: float = 0.0


@dataclass
class Transaction:
    id: Optional[int] = None
    user_id: int = 0
    merchant_name: str = ""
    amount: float = 0.0
    type: str = "expense"
    transaction_date: str = ""
    transaction_time: str = "00:00"
    group_id: Optional[int] = None
    category: str = "other"
    receipt_image_path: Optional[str] = None
    raw_ocr_text: Optional[str] = None
    notes: Optional[str] = None


@dataclass
class ExpenseSplit:
    id: Optional[int] = None
    transaction_id: int = 0
    user_id: int = 0
    split_amount: float = 0.0
    is_settled: bool = False
    settled_at: Optional[str] = None


@dataclass
class Budget:
    id: Optional[int] = None
    user_id: int = 0
    category: str = ""
    limit_amount: float = 0.0
    month: Optional[str] = None


@dataclass
class Saving:
    id: Optional[int] = None
    user_id: int = 0
    name: str = ""
    icon: str = "gift"
    target_amount: float = 0.0
    saved_amount: float = 0.0


@dataclass
class RecurringTransaction:
    id: Optional[int] = None
    user_id: int = 0
    name: str = ""
    amount: float = 0.0
    frequency: str = "monthly"
    category: str = "bills"
    is_active: bool = True
