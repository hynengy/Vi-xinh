import 'package:flutter/material.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import '../services/database_helper.dart';

class WalletProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  int? _userId;
  double _totalBalance = 0.0;
  double _monthlyIncome = 0.0;
  double _monthlyExpense = 0.0;
  bool _isBalanceVisible = true;
  List<TransactionModel> _transactions = [];
  List<BudgetModel> _budgets = [];
  Map<String, double> _spendByCategory = {};
  bool _isLoading = false;

  double get totalBalance => _totalBalance;
  double get monthlyIncome => _monthlyIncome;
  double get monthlyExpense => _monthlyExpense;
  bool get isBalanceVisible => _isBalanceVisible;
  List<TransactionModel> get transactions => _transactions;
  List<BudgetModel> get budgets => _budgets;
  Map<String, double> get spendByCategory => _spendByCategory;
  bool get isLoading => _isLoading;

  void toggleBalanceVisibility() {
    _isBalanceVisible = !_isBalanceVisible;
    notifyListeners();
  }

  Future<void> loadWalletData({int? userId}) async {
    if (userId != null) _userId = userId;
    if (_userId == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      _transactions = await _dbHelper.getRecentTransactions(userId: _userId);
      final stats = await _dbHelper.getSummaryStats(userId: _userId);
      _monthlyIncome = stats['income'] ?? 0.0;
      _monthlyExpense = stats['expense'] ?? 0.0;
      _totalBalance = stats['balance'] ?? 0.0;
      _budgets = await _dbHelper.getBudgets(_userId!);
      _spendByCategory = await _dbHelper.getExpenseByCategory(userId: _userId!);
    } catch (e) {
      debugPrint('Error loading wallet data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int> addTransaction(TransactionModel tx) async {
    final id = await _dbHelper.insertTransaction(tx);
    await loadWalletData(userId: tx.userId);
    return id;
  }

  Future<void> deleteTransaction(TransactionModel tx) async {
    if (tx.id == null) return;
    await _dbHelper.deleteTransaction(tx.id!);
    await loadWalletData(userId: tx.userId);
  }

  Future<void> saveBudget(BudgetModel budget) async {
    await _dbHelper.upsertBudget(budget);
    await loadWalletData(userId: budget.userId);
  }

  Future<void> removeBudget(int id) async {
    await _dbHelper.deleteBudget(id);
    if (_userId != null) await loadWalletData(userId: _userId);
  }

  double spentOf(String category) => _spendByCategory[category] ?? 0;

  /// Returns percent 0-999 after adding [amount] to [category], or null if no budget.
  int? budgetPercentAfter({required String category, required double amount}) {
    BudgetModel? b;
    for (final item in _budgets) {
      if (item.category == category) b = item;
    }
    if (b == null || b.limitAmount <= 0) return null;
    return (((spentOf(category) + amount) / b.limitAmount) * 100).round();
  }
}
