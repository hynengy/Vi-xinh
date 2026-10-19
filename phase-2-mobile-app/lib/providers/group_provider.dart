import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../services/database_helper.dart';

class GroupProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  GroupModel? _group;
  bool _isLoading = false;

  GroupModel? get group => _group;
  bool get isLoading => _isLoading;

  Future<void> loadGroupDetail(int groupId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _group = await _dbHelper.getGroupDetail(groupId);
    } catch (e) {
      debugPrint('Error loading group detail: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> contributeFund(int groupId, double amount) async {
    await _dbHelper.updateGroupFund(groupId, amount);
    if (_group != null) {
      _group = GroupModel(
        id: _group!.id,
        name: _group!.name,
        description: _group!.description,
        createdBy: _group!.createdBy,
        balance: _group!.balance + amount,
        members: _group!.members,
      );
      notifyListeners();
    }
  }
}
