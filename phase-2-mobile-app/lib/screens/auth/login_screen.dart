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
        if (_nameCtrl.text.trim().length < 2 ||
            !_emailCtrl.text.contains('@') ||
            _phoneCtrl.text.trim().length < 9 ||
            _passwordCtrl.text.length < 6) {
          _toast('Vui lòng nhập đầy đủ họ tên, email, SĐT và mật khẩu từ 6 ký tự.');
          return;
        }
        await auth.register(
          fullName: _nameCtrl.text,
          email: _emailCtrl.text,
          phone: _phoneCtrl.text,
          password: _passwordCtrl.text,
        );
      } else {
        final ok = await auth.login(_identityCtrl.text, _passwordCtrl.text);
        if (!ok) {
          _toast('Email/SĐT hoặc mật khẩu không đúng.');
          return;
        }
      }
      if (!mounted) return;
      final uid = context.read<AuthProvider>().userId;
      await context.read<WalletProvider>().loadWalletData(userId: uid);
      await context.read<GroupProvider>().loadForUser(uid);
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.danger));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.account_balance_wallet_outlined, size: 36, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              Text(_isRegister ? 'Tạo tài khoản' : 'Chào mừng trở lại',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              const Text('Quản lý chi tiêu và quét hóa đơn ngay trên điện thoại.',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 28),
              if (_isRegister) ...[
                _field(_nameCtrl, 'Họ và tên', Icons.person_outline),
                _field(_emailCtrl, 'Email', Icons.mail_outline, type: TextInputType.emailAddress),
                _field(_phoneCtrl, 'Số điện thoại', Icons.phone_outlined, type: TextInputType.phone),
              ] else
                _field(_identityCtrl, 'Email hoặc số điện thoại', Icons.login),
              _field(_passwordCtrl, 'Mật khẩu', Icons.lock_outline, obscure: true),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _busy ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _busy
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_isRegister ? 'Đăng ký' : 'Đăng nhập',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _isRegister = !_isRegister),
                  child: Text(
                    _isRegister ? 'Đã có tài khoản? Đăng nhập' : 'Chưa có tài khoản? Đăng ký',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, IconData icon, {bool obscure = false, TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        obscureText: obscure,
        keyboardType: type,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.primary),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        ),
      ),
    );
  }
}
