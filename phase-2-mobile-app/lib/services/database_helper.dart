import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../models/budget_model.dart';

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
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        full_name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        avatar_url TEXT,
        password TEXT,
        bank_name TEXT,
        bank_bin TEXT,
        bank_account TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        created_by INTEGER,
        balance REAL DEFAULT 0.0
      )
    ''');
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
    await db.execute('''
      CREATE TABLE expense_splits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        split_amount REAL NOT NULL,
        is_settled INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        category TEXT NOT NULL,
        limit_amount REAL NOT NULL,
        UNIQUE(user_id, category)
      )
    ''');
    await db.execute('''
      CREATE TABLE fund_ledger (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      Future<void> addCol(String sql) async {
        try {
          await db.execute(sql);
        } catch (_) {}
      }

      await addCol('ALTER TABLE users ADD COLUMN password TEXT');
      await addCol('ALTER TABLE users ADD COLUMN bank_name TEXT');
      await addCol('ALTER TABLE users ADD COLUMN bank_bin TEXT');
      await addCol('ALTER TABLE users ADD COLUMN bank_account TEXT');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS budgets (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          category TEXT NOT NULL,
          limit_amount REAL NOT NULL,
          UNIQUE(user_id, category)
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS fund_ledger (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          group_id INTEGER NOT NULL,
          user_id INTEGER NOT NULL,
          amount REAL NOT NULL,
          type TEXT NOT NULL,
          note TEXT,
          created_at TEXT NOT NULL
        )
      ''');
    }
  }

  // --- Users / Auth ---
  Future<UserModel> registerUser({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final db = await instance.database;
    final username = email.trim().toLowerCase();
    final existing = await db.query(
      'users',
      where: 'username = ? OR email = ? OR phone = ?',
      whereArgs: [username, email.trim(), phone.trim()],
    );
    if (existing.isNotEmpty) {
      throw Exception('Email hoặc số điện thoại đã được dùng.');
    }
    final id = await db.insert('users', {
      'username': username,
      'full_name': fullName.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'password': password,
    });
    return UserModel(
      id: id,
      username: username,
      fullName: fullName.trim(),
      email: email.trim(),
      phone: phone.trim(),
      password: password,
    );
  }

  Future<UserModel?> loginUser(String identity, String password) async {
    final db = await instance.database;
    final key = identity.trim().toLowerCase();
    final maps = await db.query(
      'users',
      where: '(LOWER(email) = ? OR phone = ? OR LOWER(username) = ?) AND password = ?',
      whereArgs: [key, identity.trim(), key, password],
    );
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  Future<UserModel?> getUserById(int id) async {
    final db = await instance.database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  Future<void> updateUser(UserModel user) async {
    final db = await instance.database;
    await db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  Future<int> insertMemberUser({required String fullName, String? phone}) async {
    final db = await instance.database;
    final username = 'member_${DateTime.now().millisecondsSinceEpoch}';
    return await db.insert('users', {
      'username': username,
      'full_name': fullName.trim(),
      'phone': phone?.trim(),
      'password': '',
    });
  }

  // --- Transactions ---
  Future<int> insertTransaction(TransactionModel tx) async {
    final db = await instance.database;
    return await db.insert('transactions', tx.toMap());
  }

  Future<void> deleteTransaction(int id) async {
    final db = await instance.database;
    await db.delete('expense_splits', where: 'transaction_id = ?', whereArgs: [id]);
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TransactionModel>> getRecentTransactions({int? userId, int limit = 50}) async {
    final db = await instance.database;
    final maps = await db.query(
      'transactions',
      where: userId != null ? 'user_id = ?' : null,
      whereArgs: userId != null ? [userId] : null,
      orderBy: 'transaction_date DESC, id DESC',
      limit: limit,
    );
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  Future<List<TransactionModel>> getGroupTransactions(int groupId) async {
    final db = await instance.database;
    final maps = await db.query(
      'transactions',
      where: 'group_id = ?',
      whereArgs: [groupId],
      orderBy: 'transaction_date DESC, id DESC',
    );
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  Future<Map<String, double>> getSummaryStats({int? userId}) async {
    final db = await instance.database;
    final now = DateTime.now();
    final monthPrefix = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final userFilter = userId != null ? 'AND user_id = $userId' : '';
    final incResult = await db.rawQuery(
      "SELECT SUM(amount) as s FROM transactions WHERE type='income' AND transaction_date LIKE ? $userFilter",
      ['$monthPrefix%'],
    );
    final expResult = await db.rawQuery(
      "SELECT SUM(amount) as s FROM transactions WHERE type='expense' AND transaction_date LIKE ? $userFilter",
      ['$monthPrefix%'],
    );
    double inc = (incResult.first['s'] as num?)?.toDouble() ?? 0.0;
    double exp = (expResult.first['s'] as num?)?.toDouble() ?? 0.0;
    return {'income': inc, 'expense': exp, 'balance': inc - exp};
  }

  Future<Map<String, double>> getExpenseByCategory({required int userId}) async {
    final db = await instance.database;
    final now = DateTime.now();
    final monthPrefix = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final rows = await db.rawQuery(
      '''
      SELECT category, SUM(amount) as s FROM transactions
      WHERE user_id = ? AND type = 'expense' AND transaction_date LIKE ?
      GROUP BY category
      ''',
      [userId, '$monthPrefix%'],
    );
    final map = <String, double>{};
    for (final row in rows) {
      map[row['category'] as String? ?? 'other'] = (row['s'] as num?)?.toDouble() ?? 0;
    }
    return map;
  }

  Future<double> getCategorySpend({required int userId, required String category}) async {
    final db = await instance.database;
    final now = DateTime.now();
    final monthPrefix = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final rows = await db.rawQuery(
      '''
      SELECT SUM(amount) as s FROM transactions
      WHERE user_id = ? AND type = 'expense' AND category = ? AND transaction_date LIKE ?
      ''',
      [userId, category, '$monthPrefix%'],
    );
    return (rows.first['s'] as num?)?.toDouble() ?? 0;
  }

  Future<List<Map<String, dynamic>>> getMonthlyTrend({required int userId, int months = 6}) async {
    final db = await instance.database;
    final now = DateTime.now();
    final list = <Map<String, dynamic>>[];
    for (int i = months - 1; i >= 0; i--) {
      final targetDate = DateTime(now.year, now.month - i, 1);
      final monthStr = '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}';
      final incResult = await db.rawQuery(
        "SELECT SUM(amount) as s FROM transactions WHERE user_id = ? AND type='income' AND transaction_date LIKE ?",
        [userId, '$monthStr%'],
      );
      final expResult = await db.rawQuery(
        "SELECT SUM(amount) as s FROM transactions WHERE user_id = ? AND type='expense' AND transaction_date LIKE ?",
        [userId, '$monthStr%'],
      );
      list.add({
        'month': 'T${targetDate.month}',
        'income': (incResult.first['s'] as num?)?.toDouble() ?? 0.0,
        'expense': (expResult.first['s'] as num?)?.toDouble() ?? 0.0,
      });
    }
    return list;
  }

  // --- Budgets ---
  Future<List<BudgetModel>> getBudgets(int userId) async {
    final db = await instance.database;
    final maps = await db.query('budgets', where: 'user_id = ?', whereArgs: [userId]);
    return maps.map((m) => BudgetModel.fromMap(m)).toList();
  }

  Future<void> upsertBudget(BudgetModel budget) async {
    final db = await instance.database;
    await db.insert(
      'budgets',
      budget.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteBudget(int id) async {
    final db = await instance.database;
    await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  // --- Groups ---
  Future<GroupModel?> getFirstGroupForUser(int userId) async {
    final db = await instance.database;
    final member = await db.query(
      'group_members',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (member.isEmpty) return null;
    return getGroupDetail(member.first['group_id'] as int);
  }

  Future<GroupModel> getGroupDetail(int groupId) async {
    final db = await instance.database;
    final groupMaps = await db.query('groups', where: 'id = ?', whereArgs: [groupId]);
    if (groupMaps.isEmpty) {
      throw Exception('Không tìm thấy ví nhóm');
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

  Future<int> createGroup({
    required String name,
    String? description,
    required int createdBy,
  }) async {
    final db = await instance.database;
    final groupId = await db.insert('groups', {
      'name': name.trim(),
      'description': description?.trim(),
      'created_by': createdBy,
      'balance': 0.0,
    });
    await db.insert('group_members', {
      'group_id': groupId,
      'user_id': createdBy,
      'role': 'admin',
      'paid_fund': 0.0,
      'debt': 0.0,
    });
    return groupId;
  }

  Future<void> addGroupMember({
    required int groupId,
    required String fullName,
    String? phone,
  }) async {
    final db = await instance.database;
    final userId = await insertMemberUser(fullName: fullName, phone: phone);
    await db.insert('group_members', {
      'group_id': groupId,
      'user_id': userId,
      'role': 'member',
      'paid_fund': 0.0,
      'debt': 0.0,
    });
  }

  Future<void> contributeFund({
    required int groupId,
    required int userId,
    required double amount,
    String note = 'Nộp quỹ',
  }) async {
    final db = await instance.database;
    await db.rawUpdate('UPDATE groups SET balance = balance + ? WHERE id = ?', [amount, groupId]);
    await db.rawUpdate(
      'UPDATE group_members SET paid_fund = paid_fund + ? WHERE group_id = ? AND user_id = ?',
      [amount, groupId, userId],
    );
    await db.insert('fund_ledger', {
      'group_id': groupId,
      'user_id': userId,
      'amount': amount,
      'type': 'contribute',
      'note': note,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> recordGroupExpense({
    required int groupId,
    required int payerId,
    required int transactionId,
    required double amount,
    required String note,
  }) async {
    final db = await instance.database;
    final members = await db.query('group_members', where: 'group_id = ?', whereArgs: [groupId]);
    if (members.isEmpty) return;
    final share = amount / members.length;
    await db.rawUpdate('UPDATE groups SET balance = balance - ? WHERE id = ?', [amount, groupId]);
    for (final m in members) {
      final uid = m['user_id'] as int;
      await db.insert('expense_splits', {
        'transaction_id': transactionId,
        'user_id': uid,
        'split_amount': share,
        'is_settled': uid == payerId ? 1 : 0,
      });
      if (uid != payerId) {
        await db.rawUpdate(
          'UPDATE group_members SET debt = debt + ? WHERE group_id = ? AND user_id = ?',
          [share, groupId, uid],
        );
      }
    }
    await db.insert('fund_ledger', {
      'group_id': groupId,
      'user_id': payerId,
      'amount': amount,
      'type': 'expense',
      'note': note,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> settleMemberDebt({required int groupId, required int userId}) async {
    final db = await instance.database;
    await db.rawUpdate(
      'UPDATE group_members SET debt = 0 WHERE group_id = ? AND user_id = ?',
      [groupId, userId],
    );
    await db.rawUpdate(
      '''
      UPDATE expense_splits SET is_settled = 1
      WHERE user_id = ? AND transaction_id IN (
        SELECT id FROM transactions WHERE group_id = ?
      )
      ''',
      [userId, groupId],
    );
  }

  Future<List<FundLedgerModel>> getFundLedger(int groupId) async {
    final db = await instance.database;
    final maps = await db.rawQuery('''
      SELECT fl.*, u.full_name
      FROM fund_ledger fl
      JOIN users u ON fl.user_id = u.id
      WHERE fl.group_id = ?
      ORDER BY fl.id DESC
    ''', [groupId]);
    return maps.map((m) => FundLedgerModel.fromMap(m)).toList();
  }
}
