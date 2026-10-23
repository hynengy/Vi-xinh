import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/database_helper.dart';

class AuthProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  UserModel? _user;
  bool _loading = true;
  bool _unlocked = true;
  bool _biometricEnabled = false;
  bool _reminderEnabled = true;

  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _loading;
  bool get isUnlocked => _unlocked;
  bool get biometricEnabled => _biometricEnabled;
  bool get reminderEnabled => _reminderEnabled;
  int get userId => _user?.id ?? 0;

  Future<void> bootstrap() async {
    _loading = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    _reminderEnabled = prefs.getBool('vx_reminder') ?? true;
    final uid = prefs.getInt('vx_user_id');
    if (uid != null) {
      _user = await _db.getUserById(uid);
      _biometricEnabled = prefs.getBool('vx_biometric_$uid') ?? false;
      _unlocked = !_biometricEnabled;
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final created = await _db.registerUser(
      fullName: fullName,
      email: email,
      phone: phone,
      password: password,
    );
    await _persistSession(created);
  }

  Future<bool> login(String identity, String password) async {
    final found = await _db.loginUser(identity, password);
    if (found == null) return false;
    await _persistSession(found);
    return true;
  }

  Future<bool> verifyPassword(String password) async {
    if (_user == null) return false;
    return _user!.password == password;
  }

  Future<void> unlock() async {
    _unlocked = true;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('vx_user_id');
    _user = null;
    _unlocked = true;
    notifyListeners();
  }

  Future<void> updateProfile(UserModel updated) async {
    await _db.updateUser(updated);
    _user = updated;
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vx_biometric_${_user?.id ?? 0}', value);
    _biometricEnabled = value;
    notifyListeners();
  }

  Future<void> setReminderEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vx_reminder', value);
    _reminderEnabled = value;
    notifyListeners();
  }

  Future<void> _persistSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('vx_user_id', user.id);
    _user = user;
    _biometricEnabled = prefs.getBool('vx_biometric_${user.id}') ?? false;
    _unlocked = !_biometricEnabled;
    notifyListeners();
  }
}
