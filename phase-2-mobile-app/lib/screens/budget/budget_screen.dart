import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_categories.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/budget_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({Key? key}) : super(key: key);

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  int _activeChartTab = 0; // 0: Cơ cấu danh mục, 1: Thu - Chi các tháng

  static final List<Color> _palette = [
    const Color(0xFF5286E8),
    const Color(0xFF10B981),
    const Color(0xFFF59E0B),
    const Color(0xFFEC4899),
    const Color(0xFF8B5CF6),
    const Color(0xFF06B6D4),
    const Color(0xFFEF4444),
    const Color(0xFF64748B),
  ];

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final spend = wallet.spendByCategory;
    final sections = spend.entries.where((e) => e.value > 0).toList();
    final totalSpent = wallet.monthlyExpense;
    final trend = wallet.monthlyTrend;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thống kê & Ngân sách'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            tooltip: 'Thêm hạn mức',
            onPressed: () => _showAddBudget(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Segmented Chart Switcher
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeChartTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _activeChartTab == 0 ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Cơ cấu chi tiêu',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _activeChartTab == 0 ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeChartTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _activeChartTab == 1 ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Thu - Chi 6 tháng',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _activeChartTab == 1 ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Main Chart Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _activeChartTab == 0
                  ? _buildPieChartSection(sections, totalSpent)
                  : _buildBarChartSection(trend),
            ),
          ),

          const SizedBox(height: 18),

          // Budget Limits Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Hạn mức danh mục', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton(
                onPressed: () => _showAddBudget(context),
                child: const Text('+ Thêm mới', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 4),

          if (wallet.budgets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.pie_chart_outline, size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    const Text('Chưa thiết lập hạn mức tháng.', style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    const Text('Bấm "+ Thêm mới" để quản lý chi tiêu hiệu quả.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
            )
          else
            ...wallet.budgets.map((b) {
              final used = wallet.spentOf(b.category);
              final pct = b.limitAmount <= 0 ? 0.0 : (used / b.limitAmount).clamp(0.0, 1.5);
              final over = used > b.limitAmount;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(AppCategories.iconOf(b.category), style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Text(AppCategories.labelOf(b.category), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                over ? 'Vượt hạn mức!' : '${(pct * 100).toInt()}%',
                                style: TextStyle(
                                  color: over ? AppColors.danger : AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.textMuted),
                                onPressed: () {
                                  if (b.id != null) context.read<WalletProvider>().removeBudget(b.id!);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          minHeight: 8,
                          value: pct > 1 ? 1 : pct,
                          color: over ? AppColors.danger : AppColors.primary,
                          backgroundColor: const Color(0xFFF1F5F9),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Đã dùng: ${CurrencyFormatter.format(used)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          Text('Hạn mức: ${CurrencyFormatter.format(b.limitAmount)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildPieChartSection(List<MapEntry<String, double>> sections, double totalSpent) {
    if (sections.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('Chưa có chi tiêu phát sinh trong tháng.', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 190,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2.5,
                  centerSpaceRadius: 42,
                  sections: sections.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final e = entry.value;
                    final color = _palette[idx % _palette.length];
                    return PieChartSectionData(
                      value: e.value,
                      title: AppCategories.iconOf(e.key),
                      radius: 46,
                      color: color,
                      titleStyle: const TextStyle(fontSize: 13),
                    );
                  }).toList(),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Tổng chi', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  Text(
                    CurrencyFormatter.formatCompact(totalSpent),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 12),
        // Breakdown List
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: sections.asMap().entries.map((entry) {
            final idx = entry.key;
            final e = entry.value;
            final color = _palette[idx % _palette.length];
            final pct = totalSpent > 0 ? ((e.value / totalSpent) * 100).toStringAsFixed(1) : '0';
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text(
                  '${AppCategories.labelOf(e.key)}: $pct%',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBarChartSection(List<Map<String, dynamic>> trend) {
    if (trend.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Chưa có đủ dữ liệu theo tháng.', style: TextStyle(color: AppColors.textSecondary))),
      );
    }

    double maxY = 100000.0;
    for (final m in trend) {
      final inc = (m['income'] as num?)?.toDouble() ?? 0.0;
      final exp = (m['expense'] as num?)?.toDouble() ?? 0.0;
      maxY = math.max(maxY, math.max(inc, exp));
    }
    maxY = (maxY * 1.25);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('So sánh Thu nhập vs Chi tiêu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Row(
              children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                const Text('Thu', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(width: 10),
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                const Text('Chi', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              barGroups: trend.asMap().entries.map((entry) {
                final idx = entry.key;
                final m = entry.value;
                final inc = (m['income'] as num?)?.toDouble() ?? 0.0;
                final exp = (m['expense'] as num?)?.toDouble() ?? 0.0;
                return BarChartGroupData(
                  x: idx,
                  barsSpace: 4,
                  barRods: [
                    BarChartRodData(
                      toY: inc,
                      color: AppColors.success,
                      width: 10,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    BarChartRodData(
                      toY: exp,
                      color: AppColors.danger,
                      width: 10,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, meta) {
                      final i = val.toInt();
                      if (i >= 0 && i < trend.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(trend[i]['month'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: true, drawVerticalLine: false),
            ),
          ),
        ),
      ],
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
              const Text('Thêm hạn mức danh mục', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
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
                decoration: const InputDecoration(labelText: 'Hạn mức chi tiêu (₫)', border: OutlineInputBorder()),
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
