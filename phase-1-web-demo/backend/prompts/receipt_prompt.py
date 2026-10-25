"""
=============================================================================
ĐỒ ÁN THỰC TẬP CHUYÊN MÔN - ỨNG DỤNG "VÍ XINH"
HƯỚNG 3: ỨNG DỤNG MÔ HÌNH NGÔN NGỮ LỚN (LLM API)
MODULE: PROMPT ENGINEERING & STRUCTURED OUTPUT JSON SCHEMA
PHỤ TRÁCH: NHÓM DỰ ÁN (PROMPT & STRUCTURED OUTPUT)
=============================================================================
Mô tả:
- Chứa System Prompt, Few-Shot Rules và JSON Schema chuẩn phục vụ trích xuất
  thông tin hóa đơn có cấu trúc bằng Multimodal LLM (Gemini API).
- Chứa Prompt phân tích, tóm tắt chi tiêu và đề xuất hành động tiết kiệm thông minh.
=============================================================================
"""

# =============================================================================
# 1. SYSTEM PROMPT: TRÍCH XUẤT HÓA ĐƠN CÓ CẤU TRÚC (STRUCTURED EXTRACTION)
# =============================================================================
RECEIPT_EXTRACTION_SYSTEM_PROMPT = """Bạn là một Chuyên gia Trích xuất Dữ liệu Hóa đơn Tài chính Việt Nam (Financial Invoice Extraction Specialist).
Nhiệm vụ của bạn là phân tích ảnh hóa đơn/chứng từ tiếng Việt và trích xuất thông tin có cấu trúc chuẩn xác 100%.

YÊU CẦU QUAN TRỌNG VỀ ĐỊNH DẠNG:
1. Bạn hãy đọc toàn bộ hóa đơn từ trên xuống dưới theo thứ tự dòng.
2. Với các mặt hàng trong bảng chi tiết, ghi rõ trên cùng một dòng có ký tự phân cách '|':
   Tên mặt hàng | Đơn vị tính (nếu có) | Số lượng | Đơn giá | Thành tiền
   Ví dụ:
   | Ốc Hương | Kg | 3,0 | 720 000 | 2 160 000
   | Mỳ Tôm trẻ em | gói | 3 | 1 000 | 3 000
3. BẢO TOÀN SỐ HỌC: Bắt buộc 'Số lượng * Đơn giá = Thành tiền'. Không lấy nhầm thông số đóng gói (như 50/b, 30b/t, 50g) làm giá tiền.
4. Ghi rõ các dòng tổng kết: Tiền thanh toán thực tế, Tạm tính, Chiết khấu/Giảm giá, Thuế VAT.
5. ĐỐI VỚI HÓA ĐƠN TIỀN TRỌ / CHUNG CƯ:
   - Nếu hóa đơn có tách riêng 'TỔNG TIỀN DỊCH VỤ' (điện, nước, wifi, máy giặt, vệ sinh, thang máy...) và 'TỔNG TIỀN PHÒNG', thì 'total_amount' PHẢI là TỔNG CỦA CẢ HAI (total_amount = Tổng tiền DV + Tổng tiền phòng).
   - Trích xuất đầy đủ tất cả các dịch vụ (điện, nước, wifi, máy giặt, vệ sinh, thang máy, để xe...) và tiền phòng vào danh sách 'items', không được bỏ sót bất kỳ mục nào (kể cả dịch vụ 0đ như để xe miễn phí).
6. TUYỆT ĐỐI KHÔNG dùng ký tự gạch đầu dòng (* hoặc -), tiêu đề (#), và KHÔNG thêm lời chào hay giải thích nào khác ngoài văn bản hóa đơn.
"""

# =============================================================================
# 2. JSON SCHEMA: KIỂM SOÁT ĐỊNH DẠNG ĐẦU RA (STRUCTURED OUTPUT SCHEMA)
# =============================================================================
RECEIPT_JSON_SCHEMA = {
    "type": "OBJECT",
    "properties": {
        "merchant_name": {
            "type": "STRING",
            "description": "Tên cửa hàng, siêu thị, nhà hàng hoặc đơn vị phát hành hóa đơn"
        },
        "transaction_date": {
            "type": "STRING",
            "description": "Ngày giao dịch theo định dạng YYYY-MM-DD"
        },
        "transaction_time": {
            "type": "STRING",
            "description": "Giờ giao dịch theo định dạng HH:MM"
        },
        "invoice_no": {
            "type": "STRING",
            "description": "Số hóa đơn, số bill hoặc mã phiếu nếu có"
        },
        "total_amount": {
            "type": "NUMBER",
            "description": "Tổng số tiền thực tế khách hàng phải thanh toán (VNĐ)"
        },
        "subtotal": {
            "type": "NUMBER",
            "description": "Tổng tiền hàng tạm tính trước khi giảm giá hoặc cộng thuế (VNĐ)"
        },
        "discount": {
            "type": "NUMBER",
            "description": "Số tiền được giảm giá, chiết khấu hoặc khuyến mãi (VNĐ)"
        },
        "vat": {
            "type": "NUMBER",
            "description": "Tiền thuế GTGT / VAT nếu có (VNĐ)"
        },
        "payment_method": {
            "type": "STRING",
            "description": "Hình thức thanh toán: Tiền mặt, Chuyển khoản, Thẻ, MoMo, Quét mã QR"
        },
        "category": {
            "type": "STRING",
            "enum": ["food", "shopping", "bills", "transport", "entertainment", "other"],
            "description": "Danh mục chi tiêu phù hợp"
        },
        "items": {
            "type": "ARRAY",
            "description": "Danh sách các mặt hàng, dịch vụ trên hóa đơn",
            "items": {
                "type": "OBJECT",
                "properties": {
                    "name": {"type": "STRING", "description": "Tên sản phẩm hoặc dịch vụ"},
                    "quantity": {"type": "NUMBER", "description": "Số lượng mua"},
                    "unit_price": {"type": "NUMBER", "description": "Đơn giá 1 đơn vị sản phẩm (VNĐ)"},
                    "amount": {"type": "NUMBER", "description": "Thành tiền của sản phẩm = Số lượng * Đơn giá (VNĐ)"},
                    "unit": {"type": "STRING", "description": "Đơn vị tính (kg, cái, đĩa, lon, bát...)"}
                },
                "required": ["name", "quantity", "unit_price", "amount"]
            }
        }
    },
    "required": ["merchant_name", "total_amount", "transaction_date", "items"]
}

# =============================================================================
# 3. PROMPT: TÓM TẮT BÁO CÁO CHI TIÊU & ĐỀ XUẤT HÀNH ĐỘNG (FINANCIAL ADVISOR)
# =============================================================================
SPENDING_ANALYSIS_SYSTEM_PROMPT = """Bạn là Cố vấn Tài chính Thông minh của ứng dụng Ví Xinh.
Dưới đây là dữ liệu thống kê chi tiêu trong tháng của người dùng.
Hãy phân tích báo cáo và đưa ra phản hồi súc tích theo định dạng sau:
1. 📌 TÓM TẮT 3 ĐIỂM CHÍNH: Nhận xét cơ cấu chi tiêu, danh mục tốn nhiều tiền nhất và xu hướng chi tiêu.
2. ⚠️ CẢNH BÁO: Chỉ ra các khoản chi lãng phí hoặc đang vượt định mức an toàn.
3. 💡 3 ĐỀ XUẤT HÀNH ĐỘNG CỤ THỂ: Đưa ra 3 lời khuyên hành động thực tế, khả thi ngay để người dùng tiết kiệm từ 10% - 25% ngân sách vào tháng sau.

Văn phong: Thân thiện, khích lệ, chuyên nghiệp và ngắn gọn.
"""
