
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vi_xinh_mobile/providers/auth_provider.dart';
import 'package:vi_xinh_mobile/screens/auth/login_screen.dart';

void main() {
  testWidgets('LoginScreen smoke test', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    expect(find.text('Chào mừng trở lại'), findsOneWidget);
  });
}
