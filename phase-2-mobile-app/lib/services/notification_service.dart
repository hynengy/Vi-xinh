import 'package:flutter/material.dart';
import '../models/notification_model.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal() {
    _initDefaultNotifications();
  }

  final List<AppNotificationModel> _notifications = [];

  List<AppNotificationModel> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void _initDefaultNotifications() {
    _notifications.addAll([
      AppNotificationModel(
        id: 'notif_1',
        title: 'Nhắc nhở đóng quỹ chung',
        body: 'Đến kỳ đóng quỹ sinh hoạt tháng này. Hãy kiểm tra và nộp đúng hạn nhé!',
        timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
        type: NotificationType.fund,
        actionRoute: '/group',
      ),
      AppNotificationModel(
        id: 'notif_2',
        title: 'Cảnh báo hạn mức Ăn uống 🍔',
        body: 'Bạn đã chi tiêu 82% hạn mức ngân sách Ăn uống trong tháng này.',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        type: NotificationType.budget,
      ),
      AppNotificationModel(
        id: 'notif_3',
        title: 'Nhắc quét hóa đơn tối nay ✨',
        body: 'Đừng quên quét hóa đơn các khoản chi trong ngày để ví xinh luôn chính xác.',
        timestamp: DateTime.now().subtract(const Duration(hours: 14)),
        type: NotificationType.daily,
        actionRoute: '/scanner',
      ),
    ]);
  }

  /// Thêm thông báo mới vào đầu danh sách
  void addNotification({
    required String title,
    required String body,
    required NotificationType type,
    String? actionRoute,
    Map<String, dynamic>? payload,
  }) {
    final notif = AppNotificationModel(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      timestamp: DateTime.now(),
      type: type,
      actionRoute: actionRoute,
      payload: payload,
    );
    _notifications.insert(0, notif);
    notifyListeners();
  }

  /// Thông báo đóng quỹ nhóm
  void notifyFundContribution(String memberName, double amount, String groupName) {
    addNotification(
      title: 'Đã nhận nộp quỹ ✨',
      body: '$memberName vừa nộp ${amount.toStringAsFixed(0)} ₫ vào $groupName.',
      type: NotificationType.fund,
      actionRoute: '/group',
    );
  }

  /// Thông báo cảnh báo vượt ngưỡng ngân sách
  void notifyBudgetThreshold(String categoryName, int percent) {
    addNotification(
      title: 'Cảnh báo ngân sách $categoryName',
      body: 'Khoản chi $categoryName đã đạt $percent% hạn mức tháng. Hãy cân đối chi tiêu!',
      type: NotificationType.budget,
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
