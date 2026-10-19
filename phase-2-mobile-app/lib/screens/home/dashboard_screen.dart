import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/transaction_model.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/group_provider.dart';
import '../camera/receipt_scanner_screen.dart';
import '../group/group_wallet_screen.dart';
import '../profile/profile_screen.dart';
import '../notifications/notification_center_screen.dart';
import '../../services/notification_service.dart';

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
      context.read<WalletProvider>().loadWalletData();
    });
  }

  void _showManualAddDialog() {
    final merchantCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String category = 'food';

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
              const Text('Thêm chi tiêu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                  hintText: 'Tên mục chi (ví dụ: Cơm trưa, Cà phê...)',
                  prefixIcon: const Icon(Icons.shopping_bag_outlined, color: AppColors.textSecondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              // Category chips
              Wrap(
                spacing: 8,
                children: [
                  {'id': 'food', 'name': '🍜 Ăn uống'},
                  {'id': 'bills', 'name': '🏠 Tiền phòng/Hóa đơn'},
                  {'id': 'shopping', 'name': '🛍️ Mua sắm'},
                  {'id': 'transport', 'name': '🛵 Đi lại'},
                ].map((c) {
                  final isSelected = category == c['id'];
                  return ChoiceChip(
                    label: Text(c['name']!, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppColors.textPrimary)),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    onSelected: (val) {
                      if (val) setSheetState(() => category = c['id']!);
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
                  onPressed: () {
                    final amt = double.tryParse(amountCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0.0;
                    if (amt > 0) {
                      final now = DateTime.now();
                      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                      final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
                      final tx = TransactionModel(
                        userId: 1,
                        merchantName: merchantCtrl.text.trim().isEmpty ? 'Chi tiêu cá nhân' : merchantCtrl.text.trim(),
                        amount: amt,
                        type: 'expense',
                        category: category,
                        transactionDate: dateStr,
                        transactionTime: timeStr,
                        notes: 'Nhập tay',
                      );
                      context.read<WalletProvider>().addTransaction(tx);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã thêm chi tiêu thành công! ✨'), backgroundColor: AppColors.success),
                      );
                    }
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
    final wallet = context.watch<WalletProvider>();
    final group = context.watch<GroupProvider>().group;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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
                          child: const Text('👛', style: TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Xin chào ✨', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            Text('Nguyễn Thúy Hiền', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const NotificationCenterScreen()),
                                    );
                                  },
                                ),
                                if (unread > 0)
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                      child: Text(
                                        '$unread',
                                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Balance Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: AppColors.cardGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Số dư ví', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        GestureDetector(
                          onTap: () => wallet.toggleBalanceVisibility(),
                          child: Icon(
                            wallet.isBalanceVisible ? Icons.visibility : Icons.visibility_off,
                            color: Colors.white70,
                            size: 20,
                          ),
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
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.arrow_downward, color: AppColors.success, size: 14),
                                    SizedBox(width: 4),
                                    Text('Thu tháng', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  wallet.isBalanceVisible ? '+${CurrencyFormatter.format(wallet.monthlyIncome)}' : '••••',
                                  style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.arrow_upward, color: AppColors.danger, size: 14),
                                    SizedBox(width: 4),
                                    Text('Chi tháng', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  wallet.isBalanceVisible ? '-${CurrencyFormatter.format(wallet.monthlyExpense)}' : '••••',
                                  style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Quick Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildQuickAction(
                      icon: Icons.camera_alt,
                      label: 'Quét bill',
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ReceiptScannerScreen()));
                      },
                    ),
                    _buildQuickAction(
                      icon: Icons.edit_note,
                      label: 'Nhập tay',
                      color: AppColors.accent,
                      onTap: _showManualAddDialog,
                    ),
                    _buildQuickAction(
                      icon: Icons.groups,
                      label: 'Ví Nhóm',
                      color: const Color(0xFF6366F1),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const GroupWalletScreen()));
                      },
                    ),
                    _buildQuickAction(
                      icon: Icons.pie_chart_outline,
                      label: 'Ngân sách',
                      color: AppColors.gold,
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              // Group Room Preview Banner
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const GroupWalletScreen()));
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
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
                            Text(
                              group != null ? '${group.name} (${group.members.length} người)' : 'Ví Nhóm Chi Tiêu Chung',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              group != null
                                  ? 'Quỹ nhóm: ${CurrencyFormatter.format(group.balance)}'
                                  : 'Quản lý quỹ chung, phòng trọ, gia đình',
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

              // Recent Transactions Header
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Gần đây', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),

              // Transaction items
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: wallet.transactions.isEmpty ? 3 : wallet.transactions.length,
                itemBuilder: (ctx, idx) {
                  if (wallet.transactions.isEmpty) {
                    final samples = [
                      {'name': 'Tiền phòng T10', 'amt': 4500000.0, 'sub': 'Phòng trọ · 01/10/2026', 'ic': Icons.home},
                      {'name': 'Highlands Coffee', 'amt': 145000.0, 'sub': 'Ăn uống · 14/10/2026', 'ic': Icons.coffee},
                      {'name': 'WinMart+', 'amt': 235000.0, 'sub': 'Siêu thị · 15/10/2026', 'ic': Icons.shopping_basket},
                    ];
                    final s = samples[idx];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryLight,
                          child: Icon(s['ic'] as IconData, color: AppColors.primary),
                        ),
                        title: Text(s['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text(s['sub'] as String, style: const TextStyle(fontSize: 11)),
                        trailing: Text(
                          '-${CurrencyFormatter.format(s['amt'] as double)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger, fontSize: 13),
                        ),
                      ),
                    );
                  }

                  final tx = wallet.transactions[idx];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryLight,
                        child: const Icon(Icons.receipt, color: AppColors.primary),
                      ),
                      title: Text(tx.merchantName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text('${tx.category} · ${tx.transactionDate}', style: const TextStyle(fontSize: 11)),
                      trailing: Text(
                        '-${CurrencyFormatter.format(tx.amount)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger, fontSize: 13),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        onTap: (idx) {
          setState(() => _currentIndex = idx);
          if (idx == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const GroupWalletScreen()));
          } else if (idx == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ReceiptScannerScreen()));
          } else if (idx == 3) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
          }
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

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
