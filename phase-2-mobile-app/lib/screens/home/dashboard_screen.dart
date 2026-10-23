import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_categories.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/group_provider.dart';
import '../../services/notification_service.dart';
import '../camera/receipt_scanner_screen.dart';
import '../group/group_wallet_screen.dart';
import '../profile/profile_screen.dart';
import '../notifications/notification_center_screen.dart';
import '../budget/budget_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().userId;
      if (uid > 0) {
        context.read<WalletProvider>().loadWalletData(userId: uid);
        context.read<GroupProvider>().loadForUser(uid);
      }
    });
  }

  void _showManualAddDialog() {
    final merchantCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String category = 'food';
    String type = 'expense';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(type == 'expense' ? 'Thêm chi tiêu' : 'Thêm thu nhập', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Chi tiêu'),
                    selected: type == 'expense',
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(color: type == 'expense' ? Colors.white : AppColors.textPrimary),
                    onSelected: (_) => setSheetState(() {
                      type = 'expense';
                      category = 'food';
                    }),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Thu nhập'),
                    selected: type == 'income',
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(color: type == 'income' ? Colors.white : AppColors.textPrimary),
                    onSelected: (_) => setSheetState(() {
                      type = 'income';
                      category = 'salary';
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                decoration: InputDecoration(
                  hintText: '0 ₫',
                  prefixIcon: const Icon(Icons.attach_money, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: merchantCtrl,
                decoration: InputDecoration(
                  hintText: type == 'income' ? 'Nguồn thu (lương, thưởng...)' : 'Tên mục chi',
                  prefixIcon: const Icon(Icons.shopping_bag_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: (type == 'income' ? ['salary', 'other'] : ['food', 'bills', 'shopping', 'transport', 'other']).map((id) {
                  final isSelected = category == id;
                  return ChoiceChip(
                    label: Text(AppCategories.labelOf(id),
                        style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppColors.textPrimary)),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    onSelected: (val) {
                      if (val) setSheetState(() => category = id);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () async {
                    final amt = double.tryParse(amountCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0.0;
                    if (amt <= 0) return;
                    final now = DateTime.now();
                    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
                    final uid = context.read<AuthProvider>().userId;
                    final tx = TransactionModel(
                      userId: uid,
                      merchantName: merchantCtrl.text.trim().isEmpty ? (type == 'income' ? 'Thu nhập' : 'Chi tiêu cá nhân') : merchantCtrl.text.trim(),
                      amount: amt,
                      type: type,
                      category: category,
                      transactionDate: dateStr,
                      transactionTime: timeStr,
                      notes: 'Nhập tay',
                    );
                    await context.read<WalletProvider>().addTransaction(tx);
                    if (type == 'expense') {
                      context.read<NotificationService>().notifyExpense(
                            merchantName: tx.merchantName,
                            amount: amt,
                            category: AppCategories.labelOf(category),
                          );
                      final pct = context.read<WalletProvider>().budgetPercentAfter(category: category, amount: 0);
                      if (pct != null && pct >= 80) {
                        context.read<NotificationService>().notifyBudgetThreshold(AppCategories.labelOf(category), pct);
                      }
                    } else {
                      context.read<NotificationService>().notifyIncome(merchantName: tx.merchantName, amount: amt);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Lưu giao dịch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeTab(
            onAdd: _showManualAddDialog,
            onSwitchTab: (idx) => setState(() => _currentIndex = idx),
          ),
          const GroupWalletScreen(asTab: true),
          const SizedBox.shrink(),
          const ProfileScreen(asTab: true),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex == 2 ? 0 : _currentIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        onTap: (idx) {
          if (idx == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ReceiptScannerScreen()));
            return;
          }
          setState(() => _currentIndex = idx);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Ví Nhóm'),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: 'Quét bill'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final VoidCallback onAdd;
  final ValueChanged<int>? onSwitchTab;
  const _HomeTab({required this.onAdd, this.onSwitchTab});

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final group = context.watch<GroupProvider>().group;
    final user = context.watch<AuthProvider>().user;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(user != null && user.fullName.isNotEmpty ? user.fullName.trim().split(' ').last[0] : 'V'),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Xin chào', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          Text(user?.fullName ?? 'Ví Xinh', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Consumer<NotificationService>(
                        builder: (context, notifService, _) {
                          final unread = notifService.unreadCount;
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.notifications_none, color: AppColors.textPrimary),
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationCenterScreen()));
                                },
                              ),
                              if (unread > 0)
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                    child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
                        onPressed: () => onSwitchTab?.call(3),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Số dư tháng này', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      GestureDetector(
                        onTap: () => wallet.toggleBalanceVisibility(),
                        child: Icon(wallet.isBalanceVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white70, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    wallet.isBalanceVisible ? CurrencyFormatter.format(wallet.totalBalance) : '•••••••• ₫',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(child: _statBox('Thu tháng', wallet.isBalanceVisible ? '+${CurrencyFormatter.format(wallet.monthlyIncome)}' : '••••', AppColors.success, Icons.arrow_downward)),
                      const SizedBox(width: 10),
                      Expanded(child: _statBox('Chi tháng', wallet.isBalanceVisible ? '-${CurrencyFormatter.format(wallet.monthlyExpense)}' : '••••', AppColors.danger, Icons.arrow_upward)),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _quick(Icons.camera_alt, 'Quét bill', AppColors.primary, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ReceiptScannerScreen()));
                  }),
                  _quick(Icons.edit_note, 'Nhập tay', AppColors.accent, onAdd),
                  _quick(Icons.groups, 'Ví nhóm', const Color(0xFF6366F1), () {
                    onSwitchTab?.call(1);
                  }),
                  _quick(Icons.pie_chart_outline, 'Ngân sách', AppColors.gold, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetScreen()));
                  }),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => onSwitchTab?.call(1),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.home_work, color: Color(0xFF6366F1), size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(group != null ? '${group.name} (${group.members.length} người)' : 'Chưa có ví nhóm', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(
                            group != null ? 'Quỹ nhóm: ${CurrencyFormatter.format(group.balance)}' : 'Tạo quỹ chung để chia tiền và nhắc nợ',
                            style: const TextStyle(color: Color(0xFF6366F1), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Gần đây', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            if (wallet.transactions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                child: Center(
                  child: Text('Chưa có giao dịch. Quét hóa đơn hoặc nhập tay để bắt đầu.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: wallet.transactions.length,
                itemBuilder: (ctx, idx) {
                  final tx = wallet.transactions[idx];
                  final isExpense = tx.type == 'expense';
                  return Dismissible(
                    key: ValueKey('tx_${tx.id}_$idx'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      color: AppColors.danger,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) => context.read<WalletProvider>().deleteTransaction(tx),
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryLight,
                          radius: 18,
                          child: Icon(
                            isExpense ? Icons.north_east_rounded : Icons.south_west_rounded,
                            size: 16,
                            color: isExpense ? AppColors.danger : AppColors.success,
                          ),
                        ),
                        title: Text(tx.merchantName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text('${AppCategories.labelOf(tx.category)} · ${tx.transactionDate}', style: const TextStyle(fontSize: 11)),
                        trailing: Text(
                          '${isExpense ? '-' : '+'}${CurrencyFormatter.format(tx.amount)}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: isExpense ? AppColors.danger : AppColors.success, fontSize: 13),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: color, size: 14), const SizedBox(width: 4), Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11))]),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _quick(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
