import 'package:flutter/material.dart';
import '../services/budget_api_service.dart';

class BankProvider extends ChangeNotifier {
  String _userId = '';
  List<Map<String, dynamic>> _bankAccounts = [];

  final _api = BudgetApiService.instance;

  List<Map<String, dynamic>> get bankAccounts => _bankAccounts;

  // ProxyProvider에서 AppProvider.userId가 바뀔 때 호출
  void update(String userId) {
    if (_userId == userId) return;
    _userId = userId;
    if (userId.isNotEmpty) _loadBankAccounts();
  }

  Future<void> _loadBankAccounts() async {
    try {
      final accounts = await _api.fetchLinkedBankAccounts(_userId);
      _bankAccounts = accounts;
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> linkBankAccount(String bankName) async {
    if (_userId.isEmpty) return false;
    final result = await _api.linkBankAccount(userId: _userId, bankName: bankName);
    if (result != null) {
      _bankAccounts.removeWhere((a) => a['bank_name'] == bankName);
      _bankAccounts.insert(0, result);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> unlinkBankAccount(String accountId) async {
    _bankAccounts.removeWhere((a) => a['id'] == accountId);
    notifyListeners();
    if (_userId.isNotEmpty) {
      await _api.unlinkBankAccount(accountId);
    }
  }
}
