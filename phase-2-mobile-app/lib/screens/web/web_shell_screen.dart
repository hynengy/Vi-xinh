import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/constants/app_colors.dart';

class WebShellScreen extends StatefulWidget {
  final String? initialUrl;
  const WebShellScreen({Key? key, this.initialUrl}) : super(key: key);

  @override
  State<WebShellScreen> createState() => _WebShellScreenState();
}

class _WebShellScreenState extends State<WebShellScreen> {
  late final WebViewController _controller;
  String _currentUrl = 'https://vi-xinh.vercel.app';
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    _initController();
    _loadSavedUrl();
  }

  Future<void> _loadSavedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('vixinh_server_url');
    // Nếu chưa lưu hoặc lưu dải IP cũ 192.168.x / localhost -> tự động dùng link cloud public
    if (saved != null && saved.isNotEmpty && !saved.contains('192.168.') && !saved.contains('localhost')) {
      setState(() {
        _currentUrl = saved;
      });
      _controller.loadRequest(Uri.parse(_currentUrl));
    } else {
      _controller.loadRequest(Uri.parse('https://vi-xinh.vercel.app'));
    }
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress;
                _isLoading = progress < 100;
              });
            }
          },
          onPageStarted: (url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            }
          },
          onPageFinished: (url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasError = false;
              });
            }
          },
          onWebResourceError: (error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
                _errorMessage = error.description;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(_currentUrl));
  }

  void _showChangeServerDialog() {
    final textCtrl = TextEditingController(text: _currentUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.wifi_tethering, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Địa chỉ Máy chủ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập địa chỉ máy chủ Ví Xinh (IP máy tính trên Wi-Fi hoặc tên miền):',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textCtrl,
              decoration: InputDecoration(
                hintText: 'https://vi-xinh.vercel.app',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              String val = textCtrl.text.trim();
              if (val.isNotEmpty) {
                if (!val.startsWith('http://') && !val.startsWith('https://')) {
                  val = 'http://$val';
                }
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('vixinh_server_url', val);
                setState(() {
                  _currentUrl = val;
                });
                _controller.loadRequest(Uri.parse(val));
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Lưu & Kết nối'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _controller.canGoBack()) {
          await _controller.goBack();
        } else {
          if (context.mounted) {
            final exit = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Thoát Ví Xinh?'),
                content: const Text('Bạn có chắc muốn thoát ứng dụng không?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Ở lại')),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Thoát')),
                ],
              ),
            );
            if (exit == true) {
              Navigator.of(context).pop();
            }
          }
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              if (!_hasError)
                RefreshIndicator(
                  onRefresh: () async {
                    await _controller.reload();
                  },
                  child: WebViewWidget(controller: _controller),
                ),
              if (_isLoading && !_hasError)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    value: _loadingProgress / 100,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 3,
                  ),
                ),
              if (_hasError)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off_rounded, size: 64, color: AppColors.danger),
                        const SizedBox(height: 16),
                        const Text(
                          'Không thể kết nối đến máy chủ Ví Xinh',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Máy chủ hiện tại: $_currentUrl\nHãy đảm bảo máy tính và điện thoại cùng mạng Wi-Fi và server đang chạy.',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _showChangeServerDialog,
                              icon: const Icon(Icons.settings),
                              label: const Text('Đổi IP Máy Chủ'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                _controller.loadRequest(Uri.parse(_currentUrl));
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Thử Lại'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
