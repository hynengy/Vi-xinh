"""
Module Xử Lý Logic Ví Nhóm & Thuật Toán Chia Tiền (Split Bill)
Phụ trách: Thành viên 2 - Lê Thị Dịu
Nhiệm vụ: Tính toán chia đều chi phí nhóm, theo dõi ai nợ ai và kết toán công nợ
"""
from typing import List, Dict, Any, Optional


class GroupWalletManager:
    """Xử lý nghiệp vụ chia tiền trong ví nhóm."""

    def __init__(self, db_manager=None):
        self.db = db_manager

    @staticmethod
    def split_equally(total_amount: float, member_ids: List[int]) -> Dict[str, Any]:
        """
        Chia đều số tiền cho danh sách thành viên:
        - total_amount: Tổng số tiền thanh toán của hóa đơn
        - member_ids: Danh sách ID người tham gia chia
        Returns: { per_person: float, splits: [{user_id, amount}], total: float }
        """
        if not member_ids:
            return {"per_person": 0, "splits": [], "total": 0}

        count = len(member_ids)
        # Làm tròn đến hàng đơn vị
        per_person = round(total_amount / count)

        # Xử lý phần dư: người đầu tiên trả thêm phần dư
        remainder = total_amount - (per_person * count)
        splits = []
        for i, m_id in enumerate(member_ids):
            amount = per_person + (remainder if i == 0 else 0)
            splits.append({"user_id": m_id, "split_amount": amount})

        return {
            "total": total_amount,
            "member_count": count,
            "per_person": per_person,
            "splits": splits
        }

    @staticmethod
    def split_by_percentage(total_amount: float, percentages: Dict[int, float]) -> Dict[str, Any]:
        """
        Chia theo phần trăm tùy chỉnh:
        - percentages: {user_id: percentage} (tổng = 100)
        """
        splits = []
        for user_id, pct in percentages.items():
            amount = round(total_amount * pct / 100)
            splits.append({"user_id": user_id, "split_amount": amount})

        return {
            "total": total_amount,
            "member_count": len(percentages),
            "splits": splits
        }

    @staticmethod
    def split_by_amounts(custom_amounts: Dict[int, float]) -> Dict[str, Any]:
        """
        Chia theo số tiền tùy chỉnh cho từng người.
        """
        splits = []
        total = 0
        for user_id, amount in custom_amounts.items():
            splits.append({"user_id": user_id, "split_amount": amount})
            total += amount

        return {
            "total": total,
            "member_count": len(custom_amounts),
            "splits": splits
        }

    @staticmethod
    def calculate_debts(transactions_with_splits: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """
        Tính toán công nợ tịnh tiến (Net Debt) giữa các thành viên:
        Ai đã trả trước, ai còn nợ ai bao nhiêu tiền.
        """
        balances: Dict[int, float] = {}

        for tx in transactions_with_splits:
            payer_id = tx["user_id"]
            total = tx["amount"]
            splits = tx.get("splits", [])

            # Người trả tiền được cộng số dư
            balances[payer_id] = balances.get(payer_id, 0.0) + total

            # Những người được chia bị trừ số dư tương ứng
            for s in splits:
                u_id = s["user_id"]
                amt = s["split_amount"]
                balances[u_id] = balances.get(u_id, 0.0) - amt

        # Tách người nợ (balances < 0) và người được nhận (balances > 0)
        debtors = [[u_id, -bal] for u_id, bal in balances.items() if bal < -0.01]
        creditors = [[u_id, bal] for u_id, bal in balances.items() if bal > 0.01]

        # Sắp xếp để tối ưu số lượng giao dịch thanh toán
        debtors.sort(key=lambda x: x[1], reverse=True)
        creditors.sort(key=lambda x: x[1], reverse=True)

        settlements = []
        d_idx, c_idx = 0, 0

        # Khớp nợ tối ưu (Greedy Settlement)
        while d_idx < len(debtors) and c_idx < len(creditors):
            debtor_id, debt_amt = debtors[d_idx]
            creditor_id, credit_amt = creditors[c_idx]

            settled_amount = min(debt_amt, credit_amt)
            settlements.append({
                "from_user_id": debtor_id,
                "to_user_id": creditor_id,
                "amount": round(settled_amount)
            })

            debtors[d_idx][1] -= settled_amount
            creditors[c_idx][1] -= settled_amount

            if debtors[d_idx][1] <= 0.01:
                d_idx += 1
            if creditors[c_idx][1] <= 0.01:
                c_idx += 1

        return settlements

    def create_group_transaction(self, payer_id: int, group_id: int,
                                  merchant_name: str, amount: float,
                                  date_str: str, split_mode: str = "equal",
                                  member_ids: Optional[List[int]] = None,
                                  **extra) -> Dict[str, Any]:
        """
        Tạo giao dịch nhóm hoàn chỉnh: lưu transaction + tự động chia tiền.
        split_mode: 'equal' | 'custom'
        """
        if not self.db:
            return {"error": "Database not configured"}

        # 1. Lưu giao dịch
        tx_data = {
            "user_id": payer_id,
            "group_id": group_id,
            "merchant_name": merchant_name,
            "amount": amount,
            "type": "expense",
            "transaction_date": date_str,
            "category": extra.get("category", "bills"),
            "notes": extra.get("notes", ""),
            "receipt_image_path": extra.get("receipt_image_path"),
            "raw_ocr_text": extra.get("raw_ocr_text"),
        }
        tx_id = self.db.add_transaction(tx_data)

        # 2. Tính chia tiền
        if not member_ids:
            members = self.db.get_group_members(group_id)
            member_ids = [m["id"] for m in members]

        if split_mode == "equal":
            split_result = self.split_equally(amount, member_ids)
        else:
            split_result = self.split_equally(amount, member_ids)

        # 3. Lưu splits
        self.db.create_expense_splits(tx_id, split_result["splits"])

        return {
            "success": True,
            "transaction_id": tx_id,
            "split_result": split_result
        }
