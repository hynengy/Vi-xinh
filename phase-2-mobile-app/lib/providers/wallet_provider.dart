import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/database_helper.dart';

class WalletProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  double _totalBalance = 0.0;
  double _monthlyIncome = 0.0;
  double _monthlyExpense = 0.0;
  bool _isBalanceVisible = true;
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;

  double get totalBalance => _totalBalance;
  double get monthlyIncome => _monthlyIncome;
  double get monthlyExpense => _monthlyExpense;
  bool get isBalanceVisible => _isBalanceVisible;
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;

  void toggleBalanceVisibility() {
    _isBalanceVisible = !_isBalanceVisible;
    notifyListeners();
  }

  Future<void> loadWalletData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _transactions = await _dbHelper.getRecentTransactions();
      final stats = await _dbHelper.getSummaryStats();
      _monthlyIncome = stats['income'] ?? 0.0;
      _monthlyExpense = stats['expense'] ?? 0.0;
      _totalBalance = stats['balance'] ?? 0.0;
    } catch (e) {
      debugPrint('Error loading wallet data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTransaction(TransactionModel tx) async {
    await _dbHelper.insertTransaction(tx);
    if (tx.type == 'expense') {
      _monthlyExpense += tx.amount;
      _totalBalance -= tx.amount;
    } else {
      _monthlyIncome += tx.amount;
      _totalBalance += tx.amount;
    }
    _transactions.insert(0, tx);
    notifyListeners();
  }
}
