class AppCategories {
  static const Map<String, String> labels = {
    'food': 'Ăn uống',
    'transport': 'Di chuyển',
    'shopping': 'Mua sắm',
    'entertainment': 'Giải trí',
    'health': 'Sức khỏe',
    'education': 'Học tập',
    'bills': 'Hóa đơn',
    'salary': 'Lương',
    'other': 'Khác',
  };

  static const Map<String, String> icons = {
    'food': '🍜',
    'transport': '🛵',
    'shopping': '🛍️',
    'entertainment': '🎮',
    'health': '❤️',
    'education': '📚',
    'bills': '🧾',
    'salary': '💰',
    'other': '📦',
  };

  static String labelOf(String id) => labels[id] ?? id;
  static String iconOf(String id) => icons[id] ?? '📦';
}
