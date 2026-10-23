import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_categories.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../services/notification_service.dart';

class ReviewReceiptScreen extends StatefulWidget {
  final TransactionModel transaction;
  final int? ocrLines;
  final int? ocrMs;

  const ReviewReceiptScreen({
    Key? key,
    required this.transaction,
    this.ocrLines,
    this.ocrMs,
  }) : super(key: key);

  @override
  State<ReviewReceiptScreen> createState() => _ReviewReceiptScreenState();
}

class _ReviewReceiptScreenState extends State<ReviewReceiptScreen> {
  late TextEditingController _merchantCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _dateCtrl;
  late TextEditingController _notesCtrl;
  String _selectedCategory = 'bills';
  String _splitMode = 'personal';
  int _splitCount = 3;

  bool get _weakOcr =>
      widget.transaction.amount <= 0 ||
      widget.transaction.merchantName.toLowerCase().contains('chưa rõ') ||
      (widget.ocrLines != null && widget.ocrLines! < 2);

  @override
  void initState() {
    super.initState();
    _merchantCtrl = TextEditingController(text: widget.transaction.merchantName);
    _amountCtrl = TextEditingController(
      text: widget.transaction.amount > 0 ? widget.transaction.amount.toStringAsFixed(0) : '',
    );
    _dateCtrl = TextEditingController(text: widget.transaction.transactionDate);
    _notesCtrl = TextEditingController(text: widget.transaction.notes ?? '');
    _selectedCategory = widget.transaction.category;
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
    return double.tryParse(_amountCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
  }

  Future<void> _saveTransaction() async {
    final totalAmount = _getRawTotalAmount();
    if (totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập số tiền hợp lệ trước khi lưu'), backgroundColor: AppColors.danger),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final groupProv = context.read<GroupProvider>();
    double savedAmount = totalAmount;
    int? targetGroupId;
    String finalNotes = _notesCtrl.text.trim();

    if (_splitMode == 'quick_split') {
      savedAmount = totalAmount / _splitCount;
      final splitNote = 'Chia $_splitCount người (Hóa đơn gốc: ${CurrencyFormatter.format(totalAmount)})';
      finalNotes = finalNotes.isNotEmpty ? '$finalNotes · $splitNote' : splitNote;
    } else if (_splitMode == 'group') {
      if (!groupProv.hasGroup) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hãy tạo ví nhóm trước khi ghi quỹ chung'), backgroundColor: AppColors.danger),
        );
        return;
      }
      targetGroupId = groupProv.group!.id;
      finalNotes = finalNotes.isEmpty ? 'Chi cho ví nhóm' : '$finalNotes · Chi cho ví nhóm';
    }

    final userId = auth.userId;
    final updatedTx = TransactionModel(
      userId: userId,
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

    final wallet = context.read<WalletProvider>();
    final txId = await wallet.addTransaction(updatedTx);

    if (_splitMode == 'group') {
      await groupProv.attachGroupExpense(
        transactionId: txId,
        payerId: userId,
        amount: totalAmount,
        note: updatedTx.merchantName,
      );
    }

    try {
      context.read<NotificationService>().notifyExpense(
        merchantName: updatedTx.merchantName,
        amount: updatedTx.amount,
        category: AppCategories.labelOf(updatedTx.category),
      );
      final pct = wallet.budgetPercentAfter(category: updatedTx.category, amount: 0);
      if (pct != null && pct >= 80) {
        context.read<NotificationService>().notifyBudgetThreshold(AppCategories.labelOf(updatedTx.category), pct);
      }
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_splitMode == 'quick_split'
            ? 'Đã lưu phần của bạn: ${CurrencyFormatter.format(savedAmount)}'
            : 'Đã lưu giao dịch'),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = _getRawTotalAmount();
    final quickSplitPerPerson = totalAmount > 0 ? (totalAmount / _splitCount) : 0.0;
    final hasGroup = context.watch<GroupProvider>().hasGroup;

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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: (_weakOcr ? Colors.orange : Colors.green).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: (_weakOcr ? Colors.orange : Colors.green).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(_weakOcr ? Icons.info_outline : Icons.check_circle,
                      color: _weakOcr ? AppColors.warning : AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _weakOcr
                          ? 'OCR chưa chắc. Hãy kiểm tra tên quán và số tiền trước khi lưu.'
                          : 'Đã nhận diện${widget.ocrMs != null ? ' trong ${widget.ocrMs}ms' : ''}${widget.ocrLines != null ? ' · ${widget.ocrLines} dòng' : ''}',
                      style: TextStyle(
                        color: _weakOcr ? const Color(0xFF9A3412) : Colors.green,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
                                ),
                                onChanged: (_) => setState(() {}),
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
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text('Danh mục', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['food', 'bills', 'shopping', 'transport', 'other'].map((id) {
                        final isSel = _selectedCategory == id;
                        return ChoiceChip(
                          label: Text('${AppCategories.iconOf(id)} ${AppCategories.labelOf(id)}',
                              style: TextStyle(fontSize: 12, color: isSel ? Colors.white : AppColors.textPrimary)),
                          selected: isSel,
                          selectedColor: AppColors.primary,
                          onSelected: (val) {
                            if (val) setState(() => _selectedCategory = id);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    const Text('Hình thức thanh toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: ChoiceChip(label: const Center(child: Text('Cá nhân', style: TextStyle(fontSize: 12))), selected: _splitMode == 'personal', onSelected: (_) => setState(() => _splitMode = 'personal'))),
                        const SizedBox(width: 6),
                        Expanded(child: ChoiceChip(label: const Center(child: Text('Chia bạn bè', style: TextStyle(fontSize: 12))), selected: _splitMode == 'quick_split', onSelected: (_) => setState(() => _splitMode = 'quick_split'))),
                        const SizedBox(width: 6),
                        Expanded(child: ChoiceChip(label: const Center(child: Text('Ví nhóm', style: TextStyle(fontSize: 12))), selected: _splitMode == 'group', onSelected: hasGroup ? (_) => setState(() => _splitMode = 'group') : null)),
                      ],
                    ),
                    if (_splitMode == 'quick_split') ...[
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Số người chia', style: TextStyle(fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              IconButton(onPressed: _splitCount > 2 ? () => setState(() => _splitCount--) : null, icon: const Icon(Icons.remove_circle_outline)),
                              Text('$_splitCount', style: const TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(onPressed: _splitCount < 20 ? () => setState(() => _splitCount++) : null, icon: const Icon(Icons.add_circle_outline)),
                            ],
                          ),
                        ],
                      ),
                      Text('Mỗi người: ${CurrencyFormatter.format(quickSplitPerPerson)}',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ],
                    if (_splitMode == 'group')
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Sẽ trừ quỹ ${context.watch<GroupProvider>().group?.name ?? ''} và chia đều các thành viên.',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (widget.transaction.lineItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: widget.transaction.lineItems
                        .map((item) => ListTile(
                              dense: true,
                              leading: Text(item.icon ?? '📦'),
                              title: Text(item.name),
                              trailing: Text(CurrencyFormatter.format(item.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ExpansionTile(
                title: const Text('Xem text OCR', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: const Color(0xFF0F172A),
                    child: Text(widget.transaction.rawOcrText ?? '(Không có văn bản)',
                        style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 11)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
