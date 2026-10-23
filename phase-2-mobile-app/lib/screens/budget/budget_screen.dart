import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_categories.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/budget_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final spend = wallet.spendByCategory;
    final sections = spend.entries.where((e) => e.value > 0).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ngân sách tháng'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: () => _showAddBudget(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Cơ cấu chi tiêu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 180,
                    child: sections.isEmpty
                        ? const Center(child: Text('Chưa có chi tiêu tháng này', style: TextStyle(color: AppColors.textSecondary)))
                        : PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 36,
                              sections: sections.map((e) {
                                return PieChartSectionData(
                                  value: e.value,
                                  title: AppCategories.iconOf(e.key),
                                  radius: 52,
                                  titleStyle: const TextStyle(fontSize: 14),
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Đã chi ${CurrencyFormatter.format(wallet.monthlyExpense)} trong tháng',
                    style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Hạn mức danh mục', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          if (wallet.budgets.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Chưa đặt hạn mức. Bấm + để thêm.', style: TextStyle(color: AppColors.textSecondary))),
            ),
          ...wallet.budgets.map((b) {
            final used = wallet.spentOf(b.category);
            final pct = b.limitAmount <= 0 ? 0.0 : (used / b.limitAmount).clamp(0.0, 1.5);
            final over = used > b.limitAmount;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                title: Text('${AppCategories.iconOf(b.category)} ${AppCategories.labelOf(b.category)}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: pct > 1 ? 1 : pct,
                      color: over ? AppColors.danger : AppColors.primary,
                      backgroundColor: const Color(0xFFE2E8F0),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${CurrencyFormatter.format(used)} / ${CurrencyFormatter.format(b.limitAmount)}',
                      style: TextStyle(color: over ? AppColors.danger : AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                  onPressed: () {
                    if (b.id != null) context.read<WalletProvider>().removeBudget(b.id!);
                  },
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showAddBudget(BuildContext context) {
    String category = 'food';
    final amountCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: StatefulBuilder(
          builder: (context, setSheet) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Thêm hạn mức', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: category,
                items: AppCategories.labels.entries
                    .where((e) => e.key != 'salary')
                    .map((e) => DropdownMenuItem(value: e.key, child: Text('${AppCategories.iconOf(e.key)} ${e.value}')))
                    .toList(),
                onChanged: (v) => setSheet(() => category = v ?? 'food'),
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Danh mục'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Hạn mức (₫)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () {
                    final amt = double.tryParse(amountCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
                    if (amt <= 0) return;
                    final uid = context.read<AuthProvider>().userId;
                    context.read<WalletProvider>().saveBudget(BudgetModel(userId: uid, category: category, limitAmount: amt));
                    Navigator.pop(ctx);
                  },
                  child: const Text('Lưu hạn mức', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
