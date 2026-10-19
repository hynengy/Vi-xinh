import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/transaction_model.dart';
import '../../providers/wallet_provider.dart';

class ReviewReceiptScreen extends StatefulWidget {
  final TransactionModel transaction;

  const ReviewReceiptScreen({Key? key, required this.transaction}) : super(key: key);

  @override
  State<ReviewReceiptScreen> createState() => _ReviewReceiptScreenState();
}

class _ReviewReceiptScreenState extends State<ReviewReceiptScreen> {
  late TextEditingController _merchantCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _dateCtrl;
  late TextEditingController _notesCtrl;
  String _selectedCategory = 'bills';
  String _splitMode = 'personal'; // 'personal', 'quick_split', 'group'
  int _splitCount = 3;

  @override
  void initState() {
    super.initState();
    _merchantCtrl = TextEditingController(text: widget.transaction.merchantName);
    _amountCtrl = TextEditingController(text: widget.transaction.amount.toStringAsFixed(0));
    _dateCtrl = TextEditingController(text: widget.transaction.transactionDate);
    _notesCtrl = TextEditingController(text: widget.transaction.notes ?? '');
    _selectedCategory = widget.transaction.category;
    _splitMode = 'personal';
  }

  @override
  void dispose() {
    _merchantCtrl.dispose();
    _amountCtrl.dispose();
    _dateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double _getRawTotalAmount() {
    return double.tryParse(_amountCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? widget.transaction.amount;
  }

  void _saveTransaction() {
    final totalAmount = _getRawTotalAmount();
    double savedAmount = totalAmount;
    int? targetGroupId;
    String finalNotes = _notesCtrl.text.trim();

    if (_splitMode == 'quick_split') {
      savedAmount = totalAmount / _splitCount;
      final splitNote = 'Chia $_splitCount người (Hóa đơn gốc: ${CurrencyFormatter.format(totalAmount)})';
      finalNotes = finalNotes.isNotEmpty ? '$finalNotes · $splitNote' : splitNote;
      targetGroupId = null;
    } else if (_splitMode == 'group') {
      savedAmount = totalAmount;
      targetGroupId = 1;
      final groupNote = 'Chi cho Ví Nhóm';
      finalNotes = finalNotes.isNotEmpty ? '$finalNotes · $groupNote' : groupNote;
    }

    final updatedTx = TransactionModel(
      userId: 1,
      merchantName: _merchantCtrl.text.trim().isEmpty ? 'Hóa đơn' : _merchantCtrl.text.trim(),
      amount: savedAmount,
      type: 'expense',
      transactionDate: _dateCtrl.text.trim(),
      category: _selectedCategory,
      groupId: targetGroupId,
      notes: finalNotes,
      receiptImagePath: widget.transaction.receiptImagePath,
      rawOcrText: widget.transaction.rawOcrText,
      lineItems: widget.transaction.lineItems,
    );

    context.read<WalletProvider>().addTransaction(updatedTx);

    final successMsg = _splitMode == 'quick_split'
        ? 'Đã lưu phần của bạn: ${CurrencyFormatter.format(savedAmount)} ✨'
        : 'Đã lưu giao dịch thành công! ✨';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(successMsg),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = _getRawTotalAmount();
    final quickSplitPerPerson = totalAmount > 0 ? (totalAmount / _splitCount) : 0.0;
    final roomSplitPerPerson = totalAmount > 0 ? (totalAmount / 5) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Xác nhận hóa đơn'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Đã nhận diện thông tin hóa đơn',
                      style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Form Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nơi chi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _merchantCtrl,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.storefront, color: AppColors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Tổng tiền bill (₫)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _amountCtrl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.attach_money, color: AppColors.danger),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                onChanged: (val) => setState(() {}),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Ngày giao dịch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _dateCtrl,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.calendar_today, color: AppColors.primary),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Category selection
                    const Text('Danh mục:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        {'id': 'food', 'label': '🍜 Ăn uống'},
                        {'id': 'bills', 'label': '🏠 Hóa đơn/Trọ'},
                        {'id': 'shopping', 'label': '🛍️ Mua sắm'},
                        {'id': 'transport', 'label': '🛵 Đi lại'},
                      ].map((cat) {
                        final isSel = _selectedCategory == cat['id'];
                        return ChoiceChip(
                          label: Text(cat['label']!, style: TextStyle(fontSize: 12, color: isSel ? Colors.white : AppColors.textPrimary)),
                          selected: isSel,
                          selectedColor: AppColors.primary,
                          onSelected: (val) {
                            if (val) setState(() => _selectedCategory = cat['id']!);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Scope selector: 3 modes
                    const Text('Hình thức thanh toán & Chia tiền:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Cá nhân', style: TextStyle(fontSize: 12))),
                            selected: _splitMode == 'personal',
                            selectedColor: AppColors.primaryLight,
                            onSelected: (val) => setState(() => _splitMode = 'personal'),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Chia bạn bè', style: TextStyle(fontSize: 12))),
                            selected: _splitMode == 'quick_split',
                            selectedColor: AppColors.primaryLight,
                            onSelected: (val) => setState(() => _splitMode = 'quick_split'),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Ví Nhóm', style: TextStyle(fontSize: 12))),
                            selected: _splitMode == 'group',
                            selectedColor: AppColors.primaryLight,
                            onSelected: (val) => setState(() => _splitMode = 'group'),
                          ),
                        ),
                      ],
                    ),

                    // Mode 2: Quick Split without group
                    if (_splitMode == 'quick_split') ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Số người chia hóa đơn:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary, size: 22),
                                      onPressed: _splitCount > 2 ? () => setState(() => _splitCount--) : null,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      child: Text(
                                        '$_splitCount người',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 22),
                                      onPressed: _splitCount < 20 ? () => setState(() => _splitCount++) : null,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Mỗi người trả:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                Text(
                                  CurrencyFormatter.format(quickSplitPerPerson),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, size: 14, color: Colors.green),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Ví chỉ lưu phần của bạn: ${CurrencyFormatter.format(quickSplitPerPerson)} (Không tạo nhóm)',
                                      style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Mode 3: Group
                    if (_splitMode == 'group') ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFC7D2FE)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.groups_outlined, color: Color(0xFF6366F1), size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Chi phí sẽ được ghi nhận vào Quỹ nhóm chung',
                                style: TextStyle(color: Color(0xFF3730A3), fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Line items breakdown if available
            if (widget.transaction.lineItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Chi tiết hạng mục', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('${widget.transaction.lineItems.length} mục', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(height: 20),
                      ...widget.transaction.lineItems.map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Text(item.icon ?? '📦', style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    if (item.consumption != null)
                                      Text(item.consumption!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                  ],
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(item.amount),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            // Accordion for OCR Raw Text
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ExpansionTile(
                title: const Text('Xem text OCR', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: const Color(0xFF0F172A),
                    child: Text(
                      widget.transaction.rawOcrText ?? '(Không có văn bản thô)',
                      style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            // Save Button with dynamic label
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saveTransaction,
                icon: const Icon(Icons.check, color: Colors.white),
                label: Text(
                  _splitMode == 'quick_split'
                      ? 'Lưu phần của bạn (${CurrencyFormatter.format(quickSplitPerPerson)})'
                      : 'Lưu giao dịch (${CurrencyFormatter.format(totalAmount)})',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
