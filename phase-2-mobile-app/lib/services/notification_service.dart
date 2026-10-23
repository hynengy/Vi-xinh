import 'package:flutter/material.dart';
import '../models/notification_model.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal();

  final List<AppNotificationModel> _notifications = [];

  List<AppNotificationModel> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Thêm thông báo mới vào đầu danh sách
  void addNotification({
    required String title,
    required String body,
    required NotificationType type,
    DateTime? timestamp,
    String? actionRoute,
    Map<String, dynamic>? payload,
  }) {
    final notif = AppNotificationModel(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      timestamp: timestamp ?? DateTime.now(),
      type: type,
      actionRoute: actionRoute,
      payload: payload,
    );
    _notifications.insert(0, notif);
    notifyListeners();
  }

  /// Thông báo chi tiêu biến động số dư với ngày giờ cụ thể
  void notifyIncome({
    required String merchantName,
    required double amount,
    DateTime? timestamp,
  }) {
    final dt = timestamp ?? DateTime.now();
    addNotification(
      title: 'Biến động số dư: Thu nhập 💰',
      body: 'Đã ghi +${amount.toStringAsFixed(0)} ₫ từ $merchantName.',
      type: NotificationType.expense,
      timestamp: dt,
    );
  }

  void notifyExpense({
    required String merchantName,
    required double amount,
    required String category,
    DateTime? timestamp,
  }) {
    final dt = timestamp ?? DateTime.now();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final timeStr = '$hour:$minute ngày $day/$month/$year';

    addNotification(
      title: 'Biến động số dư: Chi tiêu 💸',
      body: 'Đã chi -${amount.toStringAsFixed(0)} ₫ tại $merchantName ($category) vào lúc $timeStr.',
      type: NotificationType.expense,
      timestamp: dt,
    );
  }

  /// Thông báo đóng quỹ nhóm
  void notifyFundContribution(String memberName, double amount, String groupName) {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ngày ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    addNotification(
      title: 'Đã nhận nộp quỹ ✨',
      body: '$memberName vừa nộp ${amount.toStringAsFixed(0)} ₫ vào $groupName lúc $timeStr.',
      type: NotificationType.fund,
      actionRoute: '/group',
      timestamp: now,
    );
  }

  /// Thông báo cảnh báo vượt ngưỡng ngân sách
  void notifyBudgetThreshold(String categoryName, int percent) {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ngày ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    addNotification(
      title: 'Cảnh báo ngân sách $categoryName',
      body: 'Cảnh báo lúc $timeStr: Khoản chi $categoryName đã đạt $percent% hạn mức tháng. Hãy cân đối chi tiêu!',
      type: NotificationType.budget,
      timestamp: now,
    );
  }

  /// Đánh dấu đã đọc 1 thông báo
  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }

  /// Đánh dấu tất cả là đã đọc
  void markAllAsRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  /// Xóa 1 thông báo
  void removeNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  /// Xóa toàn bộ thông báo
  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }
}
