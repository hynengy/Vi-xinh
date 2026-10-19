import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors (Rose Gold & Warm Pink)
  static const Color primary = Color(0xFFFF6584);
  static const Color primaryDark = Color(0xFFE04868);
  static const Color primaryLight = Color(0xFFFFEDF0);

  static const Color secondary = Color(0xFFFA8B74);
  static const Color gold = Color(0xFFF6BD60);
  static const Color accent = Color(0xFF7C5CFC);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Backgrounds & Surfaces
  static const Color background = Color(0xFFF8F9FD);
  static const Color surface = Colors.white;
  static const Color card = Colors.white;

  // Dark Mode Surfaces
  static const Color darkBackground = Color(0xFF13111A);
  static const Color darkSurface = Color(0xFF1E1A29);
  static const Color darkCard = Color(0xFF262135);

  // Text Colors
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF6584), Color(0xFFFA8B74)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF2D1F3D), Color(0xFF1B1528)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient groupGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
