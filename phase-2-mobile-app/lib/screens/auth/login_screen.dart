import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/wallet_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isRegister = false;
  bool _busy = false;
  bool _obscurePassword = true;
  final _identityCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _identityCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    setState(() => _busy = true);
    try {
      if (_isRegister) {
        final name = _nameCtrl.text.trim();
        final email = _emailCtrl.text.trim();
        final phone = _phoneCtrl.text.trim();
        final pw = _passwordCtrl.text;
        final hasEmail = email.contains('@');
        final hasPhone = phone.length >= 9;

        if (name.length < 2) {
          _toast('Vui lòng nhập họ và tên của bạn.');
          return;
        }
        if (!hasEmail && !hasPhone) {
          _toast('Vui lòng nhập ít nhất Email hoặc Số điện thoại hợp lệ.');
          return;
        }
        if (pw.length < 6) {
          _toast('Mật khẩu bảo mật phải có ít nhất 6 ký tự.');
          return;
        }
        await auth.register(
          fullName: name,
          email: email,
          phone: phone,
          password: pw,
        );
      } else {
        final id = _identityCtrl.text.trim();
        final pw = _passwordCtrl.text.trim();
        if (id.isEmpty) {
          _toast('Vui lòng nhập email hoặc số điện thoại.');
          return;
        }
        final ok = await auth.login(id, pw);
        if (!ok) {
          _toast('Email/SĐT hoặc mật khẩu không đúng.');
          return;
        }
      }
      final uid = auth.userId;
      if (uid > 0 && mounted) {
        await context.read<WalletProvider>().loadWalletData(userId: uid);
        await context.read<GroupProvider>().loadForUser(uid);
      }
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.danger));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.account_balance_wallet_outlined, size: 30, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      _isRegister ? 'Tạo tài khoản' : 'Chào mừng trở lại',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      _isRegister ? 'Đăng ký tài khoản để quản lý chi tiêu' : 'Ví Xinh - Quản lý chi tiêu thông minh',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_isRegister) ...[
                    _field(_nameCtrl, 'Họ và tên', Icons.person_outline),
                    _field(_emailCtrl, 'Email', Icons.mail_outline, type: TextInputType.emailAddress),
                    _field(_phoneCtrl, 'Số điện thoại', Icons.phone_outlined, type: TextInputType.phone),
                  ] else
                    _field(_identityCtrl, 'Email hoặc số điện thoại', Icons.person_outline),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      height: 46,
                      child: TextField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Mật khẩu',
                          hintStyle: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: AppColors.textSecondary,
                              size: 18,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _busy ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _busy
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(_isRegister ? 'Đăng ký' : 'Đăng nhập',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() => _isRegister = !_isRegister),
                      child: Text(
                        _isRegister ? 'Đã có tài khoản? Đăng nhập' : 'Chưa có tài khoản? Đăng ký',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, IconData icon, {TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        height: 46,
        child: TextField(
          controller: c,
          keyboardType: type,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          ),
        ),
      ),
    );
  }
}
