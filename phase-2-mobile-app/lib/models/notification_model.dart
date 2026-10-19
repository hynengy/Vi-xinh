import 'package:flutter/material.dart';

enum NotificationType {
  fund,      // Quỹ nhóm & đóng tiền
  split,     // Chia tiền hóa đơn
  budget,    // Cảnh báo hạn mức ngân sách
  daily,     // Nhắc quét hóa đơn hàng ngày
  security,  // Bảo mật & sinh trắc học
}

class AppNotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final NotificationType type;
  bool isRead;
  final String? actionRoute;
  final Map<String, dynamic>? payload;

  AppNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.actionRoute,
    this.payload,
  });

  IconData get icon {
    switch (type) {
      case NotificationType.fund:
        return Icons.group_work_outlined;
      case NotificationType.split:
        return Icons.receipt_long_outlined;
      case NotificationType.budget:
        return Icons.warning_amber_rounded;
      case NotificationType.daily:
        return Icons.camera_alt_outlined;
      case NotificationType.security:
        return Icons.shield_outlined;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.fund:
        return const Color(0xFF6366F1); // Indigo
      case NotificationType.split:
        return const Color(0xFFE11D48); // Rose
      case NotificationType.budget:
        return const Color(0xFFF59E0B); // Amber Warning
      case NotificationType.daily:
        return const Color(0xFF10B981); // Emerald
      case NotificationType.security:
        return const Color(0xFF3B82F6); // Blue
    }
  }

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes <= 0 ? 1 : diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
