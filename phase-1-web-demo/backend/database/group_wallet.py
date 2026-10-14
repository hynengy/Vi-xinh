"""
Module Xử Lý Logic Ví Nhóm & Thuật Toán Chia Tiền (Split Bill)
Phụ trách: Thành viên 2 - Lê Thị Dịu
Nhiệm vụ: Tính toán chia đều chi phí nhóm, theo dõi ai nợ ai và kết toán công nợ
"""
from typing import List, Dict, Any


class GroupWalletManager:
    """Xử lý nghiệp vụ chia tiền trong ví nhóm."""

    @staticmethod
    def split_equally(total_amount: float, member_ids: List[int]) -> Dict[int, float]:
        """
        Chia đều số tiền cho danh sách thành viên:
        - total_amount: Tổng số tiền thanh toán của hóa đơn
        - member_ids: Danh sách ID người tham gia chia
        """
        if not member_ids:
            return {}
        count = len(member_ids)
        # Làm tròn đến hàng nghìn đồng
        split_per_person = round(total_amount / count, 2)
        return {m_id: split_per_person for m_id in member_ids}

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

        settlements = []
        d_idx, c_idx = 0, 0

        # Khớp nợ tối ưu
        while d_idx < len(debtors) and c_idx < len(creditors):
            debtor_id, debt_amt = debtors[d_idx]
            creditor_id, credit_amt = creditors[c_idx]

            settled_amount = min(debt_amt, credit_amt)
            settlements.append({
                "from_user_id": debtor_id,
                "to_user_id": creditor_id,
                "amount": round(settled_amount, 2)
            })

            debtors[d_idx][1] -= settled_amount
            creditors[c_idx][1] -= settled_amount

            if debtors[d_idx][1] <= 0.01:
                d_idx += 1
            if creditors[c_idx][1] <= 0.01:
                c_idx += 1

        return settlements
