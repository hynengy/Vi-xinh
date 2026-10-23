import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors (Apple Soft Pastel Blue - Dịu Mắt & Tinh Tế)
  static const Color primary = Color(0xFF5286E8);
  static const Color primaryDark = Color(0xFF3F73D4);
  static const Color primaryLight = Color(0xFFEEF4FD);

  static const Color secondary = Color(0xFF5286E8);
  static const Color gold = Color(0xFF5286E8);
  static const Color accent = Color(0xFF5286E8);

  // Status Colors (Apple Human Interface Guidelines)
  static const Color success = Color(0xFF34C759);
  static const Color danger = Color(0xFFFF3B30);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color info = Color(0xFF5286E8);

  // Backgrounds & Surfaces (Soft Pastel Tint & Pure White)
  static const Color background = Color(0xFFF5F8FC);
  static const Color surface = Colors.white;
  static const Color card = Colors.white;

  // Dark Mode Surfaces (Apple Deep Tile)
  static const Color darkBackground = Color(0xFF1D1D1F);
  static const Color darkSurface = Color(0xFF272729);
  static const Color darkCard = Color(0xFF2A2A2C);

  // Text Colors (Apple Slate & Muted)
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Gradients (Apple Soft Pastel Blue Shades)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF5286E8), Color(0xFF6EA0F8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF568AE8), Color(0xFF3F75D8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient groupGradient = LinearGradient(
    colors: [Color(0xFF568AE8), Color(0xFF3F75D8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
