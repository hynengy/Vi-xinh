import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../models/group_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('vixinh_mobile.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // 1. Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        full_name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        avatar_url TEXT
      )
    ''');

    // 2. Groups table
    await db.execute('''
      CREATE TABLE groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        created_by INTEGER,
        balance REAL DEFAULT 0.0
      )
    ''');

    // 3. Group members
    await db.execute('''
      CREATE TABLE group_members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        role TEXT DEFAULT 'member',
        paid_fund REAL DEFAULT 0.0,
        debt REAL DEFAULT 0.0
      )
    ''');

    // 4. Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        merchant_name TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT DEFAULT 'expense',
        transaction_date TEXT NOT NULL,
        transaction_time TEXT DEFAULT '00:00',
        group_id INTEGER,
        category TEXT DEFAULT 'other',
        receipt_image_path TEXT,
        raw_ocr_text TEXT,
        notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 5. Expense Splits
    await db.execute('''
      CREATE TABLE expense_splits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        split_amount REAL NOT NULL,
        is_settled INTEGER DEFAULT 0
      )
    ''');

    // Seed default users & group 302
    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    final members = [
      {'id': 1, 'username': 'thuyhien', 'full_name': 'Nguyễn Thúy Hiền', 'phone': '0912 345 678', 'email': 'hien@vixinh.vn'},
      {'id': 2, 'username': 'thidiu', 'full_name': 'Lê Thị Dịu', 'phone': '0923 456 789', 'email': 'diu@vixinh.vn'},
      {'id': 3, 'username': 'tienquan', 'full_name': 'Lê Tiến Quân', 'phone': '0934 567 890', 'email': 'quan@vixinh.vn'},
      {'id': 4, 'username': 'ngocduy', 'full_name': 'Lê Ngọc Duy', 'phone': '0945 678 901', 'email': 'duy@vixinh.vn'},
      {'id': 5, 'username': 'vietanh', 'full_name': 'Nguyễn Việt Anh', 'phone': '0956 789 012', 'email': 'vietanh@vixinh.vn'},
    ];

    for (var m in members) {
      await db.insert('users', m);
    }

    await db.insert('groups', {
      'id': 1,
      'name': 'Quỹ Chi Tiêu Chung',
      'description': 'Ví chi tiêu nhóm dùng chung cho các thành viên',
      'created_by': 1,
      'balance': 0.0,
    });

    for (var m in members) {
      await db.insert('group_members', {
        'group_id': 1,
        'user_id': m['id'],
        'role': m['id'] == 1 ? 'admin' : 'member',
        'paid_fund': 500000.0,
        'debt': m['id'] == 1 ? 0.0 : 1125000.0,
      });
    }

    // Sample transaction: Tiền trọ T10
    await db.insert('transactions', {
      'user_id': 1,
      'merchant_name': 'Tiền trọ Phòng 302 (Tháng 10)',
      'amount': 4500000.0,
      'type': 'expense',
      'transaction_date': '2026-10-01',
      'group_id': 1,
      'category': 'bills',
      'notes': 'Nguyễn Thúy Hiền đã ứng trước nộp cho chủ trọ',
    });
  }

  // --- CRUD Transactions ---
  Future<int> insertTransaction(TransactionModel tx) async {
    final db = await instance.database;
    return await db.insert('transactions', tx.toMap());
  }

  Future<List<TransactionModel>> getRecentTransactions({int limit = 30}) async {
    final db = await instance.database;
    final maps = await db.query(
      'transactions',
      orderBy: 'transaction_date DESC, id DESC',
      limit: limit,
    );
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  Future<Map<String, double>> getSummaryStats() async {
    final db = await instance.database;
    final incResult = await db.rawQuery("SELECT SUM(amount) as s FROM transactions WHERE type='income'");
    final expResult = await db.rawQuery("SELECT SUM(amount) as s FROM transactions WHERE type='expense'");

    double inc = (incResult.first['s'] as num?)?.toDouble() ?? 12000000.0;
    double exp = (expResult.first['s'] as num?)?.toDouble() ?? 3750000.0;

    return {
      'income': inc,
      'expense': exp,
      'balance': inc - exp,
    };
  }

  Future<GroupModel> getGroupDetail(int groupId) async {
    final db = await instance.database;
    final groupMaps = await db.query('groups', where: 'id = ?', whereArgs: [groupId]);
    if (groupMaps.isEmpty) {
      return GroupModel(id: 1, name: 'Quỹ Chi Tiêu Chung', createdBy: 1, balance: 0.0);
    }

    final memberMaps = await db.rawQuery('''
      SELECT gm.*, u.full_name, u.avatar_url, u.phone
      FROM group_members gm
      JOIN users u ON gm.user_id = u.id
      WHERE gm.group_id = ?
    ''', [groupId]);

    final members = memberMaps.map((m) => GroupMemberModel.fromMap(m)).toList();

    return GroupModel(
      id: groupMaps.first['id'] as int,
      name: groupMaps.first['name'] as String,
      description: groupMaps.first['description'] as String?,
      createdBy: groupMaps.first['created_by'] as int,
      balance: (groupMaps.first['balance'] as num?)?.toDouble() ?? 0.0,
      members: members,
    );
  }

  Future<void> updateGroupFund(int groupId, double amount) async {
    final db = await instance.database;
    await db.rawUpdate('UPDATE groups SET balance = balance + ? WHERE id = ?', [amount, groupId]);
  }
}
