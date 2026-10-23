import 'package:flutter/material.dart';
import '../models/budget_model.dart';
import '../models/group_model.dart';
import '../services/database_helper.dart';
import '../models/transaction_model.dart';

class GroupProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  GroupModel? _group;
  List<TransactionModel> _bills = [];
  List<FundLedgerModel> _ledger = [];
  bool _isLoading = false;

  GroupModel? get group => _group;
  GroupModel? get currentGroup => _group;
  List<TransactionModel> get bills => _bills;
  List<FundLedgerModel> get ledger => _ledger;
  bool get isLoading => _isLoading;
  bool get hasGroup => _group != null;

  Future<void> loadForUser(int userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _group = await _dbHelper.getFirstGroupForUser(userId);
      if (_group != null) {
        _bills = await _dbHelper.getGroupTransactions(_group!.id);
        _ledger = await _dbHelper.getFundLedger(_group!.id);
      } else {
        _bills = [];
        _ledger = [];
      }
    } catch (e) {
      debugPrint('Error loading group: $e');
      _group = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadGroupDetail(int groupId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _group = await _dbHelper.getGroupDetail(groupId);
      _bills = await _dbHelper.getGroupTransactions(groupId);
      _ledger = await _dbHelper.getFundLedger(groupId);
    } catch (e) {
      debugPrint('Error loading group detail: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createGroup({
    required String name,
    String? description,
    required int createdBy,
  }) async {
    final id = await _dbHelper.createGroup(
      name: name,
      description: description,
      createdBy: createdBy,
    );
    await loadGroupDetail(id);
  }

  Future<void> addMember({required String fullName, String? phone}) async {
    if (_group == null) return;
    await _dbHelper.addGroupMember(groupId: _group!.id, fullName: fullName, phone: phone);
    await loadGroupDetail(_group!.id);
  }

  Future<void> contributeFund(int groupId, double amount, {required int userId, String note = 'Nộp quỹ'}) async {
    await _dbHelper.contributeFund(groupId: groupId, userId: userId, amount: amount, note: note);
    await loadGroupDetail(groupId);
  }

  Future<void> attachGroupExpense({
    required int transactionId,
    required int payerId,
    required double amount,
    required String note,
  }) async {
    if (_group == null) return;
    await _dbHelper.recordGroupExpense(
      groupId: _group!.id,
      payerId: payerId,
      transactionId: transactionId,
      amount: amount,
      note: note,
    );
    await loadGroupDetail(_group!.id);
  }

  Future<void> settleDebt(int userId) async {
    if (_group == null) return;
    await _dbHelper.settleMemberDebt(groupId: _group!.id, userId: userId);
    await loadGroupDetail(_group!.id);
  }
}
