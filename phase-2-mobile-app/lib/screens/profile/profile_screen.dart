import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/biometric_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final BiometricService _biometricService = BiometricService();
  bool _biometricEnabled = false;
  bool _reminderEnabled = true;
  String _biometricName = 'Face ID / Vân tay';

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final name = await _biometricService.getBiometricDisplayName();
    if (mounted) {
      setState(() {
        _biometricName = name;
      });
    }
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (value) {
      final success = await _biometricService.authenticate(
        reason: 'Xác thực sinh trắc học để kích hoạt bảo vệ Ví Xinh',
      );
      if (success) {
        setState(() => _biometricEnabled = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã kích hoạt $_biometricName thành công! ✨'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Xác thực không thành công. Chưa bật bảo mật.'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    } else {
      setState(() => _biometricEnabled = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tắt khóa sinh trắc học.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cá nhân'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primaryLight,
                    child: const Text('👛', style: TextStyle(fontSize: 28)),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Người dùng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        SizedBox(height: 4),
                        Text('Tài khoản cá nhân', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                        SizedBox(height: 2),
                        Text('Chưa liên kết tài khoản', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Bank VietQR Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.qr_code_2, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text('Tài khoản nhận tiền (VietQR)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      Icon(Icons.check_circle, color: AppColors.success, size: 18),
                    ],
                  ),
                  const Divider(height: 20),
                  _buildInfoRow('Ngân hàng', 'Chưa thiết lập'),
                  const SizedBox(height: 8),
                  _buildInfoRow('Số tài khoản', '---'),
                  const SizedBox(height: 8),
                  _buildInfoRow('Chủ tài khoản', '---'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Settings Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  _buildSettingTile(
                    icon: Icons.notifications_active_outlined,
                    title: 'Nhắc hẹn chi tiêu',
                    subtitle: 'Thông báo định kỳ theo lịch cá nhân',
                    trailing: Switch(
                      value: _reminderEnabled,
                      onChanged: (v) => setState(() => _reminderEnabled = v),
                      activeColor: AppColors.primary,
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildSettingTile(
                    icon: Icons.document_scanner_outlined,
                    title: 'Quét OCR On-Device',
                    subtitle: 'Google ML Kit bảo mật ngoại tuyến',
                    trailing: const Text('Bật', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildSettingTile(
                    icon: Icons.fingerprint,
                    title: 'Bảo mật sinh trắc học',
                    subtitle: _biometricName,
                    trailing: Switch(
                      value: _biometricEnabled,
                      onChanged: _toggleBiometrics,
                      activeColor: AppColors.primary,
                    ),
                  ),

                  const Divider(height: 1, indent: 56),
                  _buildSettingTile(
                    icon: Icons.info_outline,
                    title: 'Phiên bản ứng dụng',
                    subtitle: 'Ví Xinh v1.0.0 (Bản chính thức)',
                    trailing: const Text('Mới nhất', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  static Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      trailing: trailing,
    );
  }
}
