import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../services/sync_service.dart';
import '../../services/vietqr_service.dart';

class ProfileScreen extends StatefulWidget {
  final bool asTab;
  const ProfileScreen({Key? key, this.asTab = false}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  void _editProfile() {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final nameCtrl = TextEditingController(text: user.fullName);
    final phoneCtrl = TextEditingController(text: user.phone ?? '');
    final emailCtrl = TextEditingController(text: user.email ?? '');
    String? bankBin = user.bankBin;
    final accCtrl = TextEditingController(text: user.bankAccount ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: StatefulBuilder(
          builder: (context, setSheet) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Cập nhật hồ sơ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 12),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Họ tên', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Số điện thoại', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: bankBin != null && VietQrService.banks.any((b) => b.bin == bankBin) ? bankBin : null,
                  items: VietQrService.banks.map((b) => DropdownMenuItem(value: b.bin, child: Text(b.name))).toList(),
                  onChanged: (v) => setSheet(() => bankBin = v),
                  decoration: const InputDecoration(labelText: 'Ngân hàng', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(controller: accCtrl, decoration: const InputDecoration(labelText: 'Số tài khoản', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    onPressed: () {
                      final bank = VietQrService.banks.where((b) => b.bin == bankBin);
                      final updated = user.copyWith(
                        fullName: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                        bankBin: bankBin,
                        bankName: bank.isEmpty ? user.bankName : bank.first.name,
                        bankAccount: accCtrl.text.trim(),
                      );
                      context.read<AuthProvider>().updateProfile(updated);
                      Navigator.pop(ctx);
                    },
                    child: const Text('Lưu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final qrUrl = user != null && user.hasVietQr
        ? VietQrService.imageUrl(
            bankBin: user.bankBin!,
            accountNo: user.bankAccount!,
            accountName: user.fullName,
          )
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cá nhân'),
        automaticallyImplyLeading: !widget.asTab,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        actions: [
          IconButton(onPressed: _editProfile, icon: const Icon(Icons.edit_outlined, color: AppColors.primary)),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Chưa đăng nhập'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.primaryLight,
                          child: Text(user.fullName.isNotEmpty ? user.fullName.trim().split(' ').last[0] : 'V',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                              Text(user.email ?? '', style: const TextStyle(color: AppColors.primary, fontSize: 13)),
                              Text(user.phone ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                    child: Column(
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Tài khoản nhận tiền (VietQR)', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const Divider(height: 20),
                        _info('Ngân hàng', user.bankName ?? 'Chưa thiết lập'),
                        const SizedBox(height: 8),
                        _info('Số tài khoản', user.bankAccount ?? '---'),
                        const SizedBox(height: 8),
                        _info('Chủ tài khoản', user.fullName),
                        if (qrUrl != null) ...[
                          const SizedBox(height: 12),
                          Image.network(qrUrl, height: 180, errorBuilder: (_, __, ___) => const Text('Không tải được VietQR')),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Nhắc hẹn chi tiêu', style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: const Text('Bật để nhận thông báo trong app'),
                          value: auth.reminderEnabled,
                          onChanged: auth.setReminderEnabled,
                          activeThumbColor: AppColors.primary,
                        ),
                        Consumer<WalletProvider>(
                          builder: (context, wallet, _) => ListTile(
                            leading: const Icon(Icons.cloud_sync_outlined, color: AppColors.primary),
                            title: const Text('Đồng bộ với Web Server', style: TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: const Text('Sao lưu dữ liệu SQLite lên máy chủ'),
                            trailing: wallet.isSyncing
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                            onTap: wallet.isSyncing
                                ? null
                                : () async {
                                    final syncService = context.read<SyncService>();
                                    final res = await wallet.syncWithServer(syncService);
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(res.message),
                                        backgroundColor: res.success ? AppColors.success : AppColors.danger,
                                      ),
                                    );
                                  },
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.logout, color: AppColors.danger),
                          title: const Text('Đăng xuất', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                          onTap: () => auth.logout(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Ví Xinh v1.0.0', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
    );
  }

  Widget _info(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
