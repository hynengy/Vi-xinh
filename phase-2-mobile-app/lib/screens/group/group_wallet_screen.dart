import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../services/vietqr_service.dart';
import '../camera/receipt_scanner_screen.dart';

class GroupWalletScreen extends StatefulWidget {
  final bool asTab;
  const GroupWalletScreen({Key? key, this.asTab = false}) : super(key: key);

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
      final uid = context.read<AuthProvider>().userId;
      if (uid > 0) context.read<GroupProvider>().loadForUser(uid);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCreateGroup() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tạo ví nhóm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên nhóm', hintText: 'VD: Phòng trọ 302')),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Mô tả')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              context.read<GroupProvider>().createGroup(
                    name: nameCtrl.text,
                    description: descCtrl.text,
                    createdBy: context.read<AuthProvider>().userId,
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  void _showAddMember() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm thành viên'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Họ tên')),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Số điện thoại'), keyboardType: TextInputType.phone),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              context.read<GroupProvider>().addMember(fullName: nameCtrl.text, phone: phoneCtrl.text);
              Navigator.pop(ctx);
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  void _showContributeDialog() {
    final amountCtrl = TextEditingController();
    final group = context.read<GroupProvider>().currentGroup;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Góp ${group?.name ?? 'quỹ'}'),
        content: TextField(
          controller: amountCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Số tiền', suffixText: '₫'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(amountCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
              if (amt <= 0) return;
              final uid = context.read<AuthProvider>().userId;
              context.read<GroupProvider>().contributeFund(group!.id, amt, userId: uid);
              Navigator.pop(ctx);
            },
            child: const Text('Nộp quỹ'),
          ),
        ],
      ),
    );
  }

  void _showQrReminder(String memberName, double debt) {
    final user = context.read<AuthProvider>().user;
    final qrUrl = user != null && user.hasVietQr
        ? VietQrService.imageUrl(
            bankBin: user.bankBin!,
            accountNo: user.bankAccount!,
            accountName: user.fullName,
            amount: debt,
            addInfo: 'Tra no $memberName',
          )
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nhắc nợ VietQR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(CurrencyFormatter.format(debt), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 12),
            if (qrUrl != null)
              Image.network(qrUrl, height: 180, errorBuilder: (_, __, ___) => const Text('Không tải được mã QR'))
            else
              const Text('Hãy lưu STK ngân hàng trong mục Cá nhân để hiện VietQR.', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text('${user?.bankName ?? 'Chưa ngân hàng'} · ${user?.bankAccount ?? '---'}'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: 'Nhắc $memberName thanh toán ${CurrencyFormatter.format(debt)} cho quỹ nhóm Ví Xinh.'));
                      Navigator.pop(ctx);
                    },
                    child: const Text('Sao chép tin'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final members = context.read<GroupProvider>().group?.members ?? [];
                      final m = members.where((e) => e.fullName == memberName);
                      if (m.isNotEmpty) context.read<GroupProvider>().settleDebt(m.first.userId);
                      Navigator.pop(ctx);
                    },
                    child: const Text('Đã trả'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupProv = context.watch<GroupProvider>();
    final group = groupProv.group;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quỹ & Ví Nhóm'),
        automaticallyImplyLeading: !widget.asTab,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        actions: [
          if (group != null)
            IconButton(icon: const Icon(Icons.person_add_alt, color: AppColors.primary), onPressed: _showAddMember),
        ],
      ),
      body: group == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.groups_outlined, size: 72, color: AppColors.primary),
                    const SizedBox(height: 12),
                    const Text('Chưa có ví nhóm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    const Text('Tạo quỹ phòng trọ, du lịch hoặc gia đình để chia tiền và nhắc nợ.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _showCreateGroup,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: const Text('Tạo ví nhóm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.groupGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('Số dư quỹ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text(CurrencyFormatter.format(group.balance), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showContributeDialog,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Nộp quỹ'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReceiptScannerScreen()));
                              },
                              icon: const Icon(Icons.receipt_long, size: 18),
                              label: const Text('Quét hóa đơn'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.white24, foregroundColor: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  tabs: const [Tab(text: 'Thành viên'), Tab(text: 'Hóa đơn'), Tab(text: 'Lịch sử quỹ')],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      group.members.isEmpty
                          ? const Center(child: Text('Chưa có thành viên'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: group.members.length,
                              itemBuilder: (ctx, idx) {
                                final m = group.members[idx];
                                final isAdmin = m.role == 'admin';
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.primaryLight,
                                      child: Text(m.fullName.isNotEmpty ? m.fullName.trim().split(' ').last[0] : '?'),
                                    ),
                                    title: Text(m.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text(
                                      isAdmin
                                          ? 'Trưởng nhóm · đã nộp ${CurrencyFormatter.format(m.paidFund)}'
                                          : (m.debt > 0 ? 'Nợ ${CurrencyFormatter.format(m.debt)}' : 'Đã hết nợ · nộp ${CurrencyFormatter.format(m.paidFund)}'),
                                      style: TextStyle(color: m.debt > 0 ? AppColors.danger : AppColors.success, fontWeight: FontWeight.w600, fontSize: 12),
                                    ),
                                    trailing: m.debt > 0
                                        ? TextButton(onPressed: () => _showQrReminder(m.fullName, m.debt), child: const Text('Thu QR'))
                                        : const Icon(Icons.verified, color: AppColors.success),
                                  ),
                                );
                              },
                            ),
                      groupProv.bills.isEmpty
                          ? const Center(child: Text('Chưa có hóa đơn nhóm'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: groupProv.bills.length,
                              itemBuilder: (_, i) {
                                final tx = groupProv.bills[i];
                                return Card(
                                  child: ListTile(
                                    leading: const CircleAvatar(
                                      backgroundColor: AppColors.primaryLight,
                                      radius: 18,
                                      child: Icon(Icons.receipt_outlined, size: 16, color: AppColors.primary),
                                    ),
                                    title: Text(tx.merchantName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('${tx.transactionDate} · ${tx.notes ?? ''}'),
                                    trailing: Text('-${CurrencyFormatter.format(tx.amount)}', style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                                  ),
                                );
                              },
                            ),
                      groupProv.ledger.isEmpty
                          ? const Center(child: Text('Chưa có biến động quỹ'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: groupProv.ledger.length,
                              itemBuilder: (_, i) {
                                final item = groupProv.ledger[i];
                                final inFund = item.type == 'contribute';
                                return ListTile(
                                  leading: Icon(inFund ? Icons.arrow_upward : Icons.arrow_downward, color: inFund ? AppColors.success : AppColors.danger),
                                  title: Text(item.note.isEmpty ? item.memberName : item.note),
                                  subtitle: Text('${item.memberName} · ${item.createdAt.split('T').first}'),
                                  trailing: Text(
                                    '${inFund ? '+' : '-'}${CurrencyFormatter.format(item.amount)}',
                                    style: TextStyle(color: inFund ? AppColors.success : AppColors.danger, fontWeight: FontWeight.bold),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
