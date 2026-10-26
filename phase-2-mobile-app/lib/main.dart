import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'providers/auth_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/group_provider.dart';
import 'screens/home/dashboard_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/lock_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/web/web_shell_screen.dart';
import 'services/notification_service.dart';
import 'services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  final auth = AuthProvider();
  await auth.bootstrap();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
        Provider(create: (_) => SyncService()),
      ],
      child: const ViXinhApp(),
    ),
  );
}

class ViXinhApp extends StatelessWidget {
  const ViXinhApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ví Xinh',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const _RootGate(),
    );
  }
}

class _RootGate extends StatefulWidget {
  const _RootGate();

  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    if (!_splashDone) {
      return SplashScreen(
        onFinish: () => setState(() => _splashDone = true),
      );
    }

    return const WebShellScreen();
  }
}
