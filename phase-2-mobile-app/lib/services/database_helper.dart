import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';
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

    // Khởi tạo CSDL sạch, không nạp tài khoản mẫu
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

    double inc = (incResult.first['s'] as num?)?.toDouble() ?? 0.0;
    double exp = (expResult.first['s'] as num?)?.toDouble() ?? 0.0;

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
