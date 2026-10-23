import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/group_provider.dart';
import '../camera/receipt_scanner_screen.dart';

class GroupWalletScreen extends StatefulWidget {
  const GroupWalletScreen({Key? key}) : super(key: key);

  @override
  State<GroupWalletScreen> createState() => _GroupWalletScreenState();
}

class _GroupWalletScreenState extends State<GroupWalletScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupProvider>().loadGroupDetail(1);
    });
  }

  void _showContributeDialog() {
    final amountCtrl = TextEditingController(text: '');
    final group = context.read<GroupProvider>().currentGroup;
    final groupName = group?.name ?? 'Quỹ Nhóm';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Góp $groupName', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nhập số tiền bạn muốn đóng vào $groupName:'),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Nhập số tiền...',
                suffixText: '₫',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              final amt = double.tryParse(amountCtrl.text) ?? 0;
              if (amt <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ')),
                );
                return;
              }
              context.read<GroupProvider>().contributeFund(group?.id ?? 1, amt);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã nộp quỹ thành công! ✨'), backgroundColor: AppColors.success),
              );
            },
            child: const Text('Xác nhận nộp', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showQrReminder(String memberName, double debt) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: 4, width: 40, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Mã VietQR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Text(CurrencyFormatter.format(debt), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
              child: const Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Chủ TK:'), Text('---', style: TextStyle(fontWeight: FontWeight.bold))]),
                  SizedBox(height: 6),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Ngân hàng:'), Text('Chưa thiết lập', style: TextStyle(fontWeight: FontWeight.bold))]),
                  SizedBox(height: 6),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Số tài khoản:'), Text('---', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))]),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                  final msg = 'Tiền phòng T10: phần của $memberName là ${CurrencyFormatter.format(debt)}. Vui lòng thanh toán sớm nhé!';
                  Clipboard.setData(ClipboardData(text: msg));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã sao chép tin nhắn!'), backgroundColor: AppColors.success),
                  );
                },
                icon: const Icon(Icons.copy, color: Colors.white),
                label: const Text('Sao chép tin nhắn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final group = context.watch<GroupProvider>().group;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quỹ & Ví Nhóm'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt, color: AppColors.primary),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ReceiptScannerScreen()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Quỹ Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.groupGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(group?.name ?? 'Quỹ Chi Tiêu Chung', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                      child: Text('${group?.members.length ?? 0} thành viên', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Số dư quỹ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(group?.balance ?? 2400000.0),
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF6366F1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _showContributeDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Nộp quỹ', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.25),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const ReceiptScannerScreen()));
                        },
                        icon: const Icon(Icons.receipt_long, size: 18),
                        label: const Text('Quét hóa đơn', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Thành viên'),
              Tab(text: 'Hóa đơn'),
              Tab(text: 'Lịch sử quỹ'),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Thành viên & Nợ
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: group?.members.length ?? 0,
                  itemBuilder: (ctx, idx) {
                    final m = group!.members[idx];
                    final isHien = m.userId == 1;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            m.fullName.split(' ').last[0],
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(m.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          isHien ? 'Trưởng phòng (Người ứng tiền)' : 'Nợ tiền phòng T10: ${CurrencyFormatter.format(m.debt)}',
                          style: TextStyle(
                            color: isHien ? AppColors.success : AppColors.danger,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        trailing: !isHien
                            ? ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryLight,
                                  foregroundColor: AppColors.primary,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                ),
                                onPressed: () => _showQrReminder(m.fullName, m.debt),
                                child: const Text('Thu tiền QR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              )
                            : const Icon(Icons.verified, color: AppColors.success),
                      ),
                    );
                  },
                ),

                // Tab 2: Hóa đơn phòng
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        leading: const Icon(Icons.home, color: AppColors.danger, size: 36),
                        title: const Text('Tiền trọ Tháng 10/2026', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('4.500.000 ₫ · Đã chia cho 4 bạn (1.125.000 ₫/bạn)'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
                      ),
                    ),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        leading: const Icon(Icons.shopping_cart, color: AppColors.warning, size: 36),
                        title: const Text('Mua sắm gia vị & nước mắm', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('180.000 ₫ · Trừ quỹ phòng'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
                      ),
                    ),
                  ],
                ),

                // Tab 3: Nhật ký quỹ
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: const [
                    ListTile(
                      leading: Icon(Icons.arrow_upward, color: AppColors.success),
                      title: Text('Đóng quỹ phòng định kỳ'),
                      subtitle: Text('5 thành viên x 500.000 ₫ = 2.500.000 ₫'),
                      trailing: Text('+2.500.000 ₫', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(Icons.arrow_downward, color: AppColors.danger),
                      title: Text('Trừ tiền sửa vòi nước bồn rửa'),
                      subtitle: Text('05/10/2026'),
                      trailing: Text('-100.000 ₫', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
