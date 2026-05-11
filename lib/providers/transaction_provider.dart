import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../services/budget_api_service.dart';
import '../services/notification_service.dart';
import '../services/gemini_service.dart';

class TransactionProvider extends ChangeNotifier {
  String _userId = '';
  List<Transaction> _transactions = [];
  int _adCounter = 0;

  final _uuid = const Uuid();
  final _api = BudgetApiService.instance;

  List<Transaction> get transactions => _transactions;
  int get adCounter => _adCounter;

  List<Transaction> get currentMonthTransactions {
    final now = DateTime.now();
    return _transactions.where((t) {
      return t.date.year == now.year && t.date.month == now.month;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double get totalIncome => currentMonthTransactions
      .where((t) => t.type == 'income')
      .fold(0.0, (s, t) => s + t.amount);

  double get totalExpense => currentMonthTransactions
      .where((t) => t.type == 'expense')
      .fold(0.0, (s, t) => s + t.amount);

  double get totalBalance => totalIncome - totalExpense;

  Map<String, double> get categoryExpenses {
    final map = <String, double>{};
    for (final t in currentMonthTransactions.where((t) => t.type == 'expense')) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }

  List<Map<String, dynamic>> get dailyExpenses {
    final result = <Map<String, dynamic>>[];
    for (int i = 6; i >= 0; i--) {
      final day = DateTime.now().subtract(Duration(days: i));
      final dayTotal = _transactions
          .where((t) =>
              t.type == 'expense' &&
              t.date.year == day.year &&
              t.date.month == day.month &&
              t.date.day == day.day)
          .fold(0.0, (sum, t) => sum + t.amount);
      result.add({'date': day, 'amount': dayTotal});
    }
    return result;
  }

  // ProxyProvider에서 AppProvider.userId가 바뀔 때 호출
  void update(String userId) {
    if (_userId == userId) return;
    _userId = userId;
    if (userId.isNotEmpty) _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    _loadFromCache(prefs);
    notifyListeners();

    try {
      final txs = await _api.fetchTransactions(userId: _userId);
      _transactions = txs;
      _saveToCache(prefs);
      notifyListeners();
    } catch (_) {}
  }

  void _loadFromCache(SharedPreferences prefs) {
    final txJson = prefs.getStringList('cached_transactions');
    if (txJson != null) {
      _transactions = txJson
          .map((s) {
            try {
              return Transaction.fromMap(jsonDecode(s) as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .whereType<Transaction>()
          .toList();
    }
  }

  Future<void> _saveToCache(SharedPreferences prefs) async {
    await prefs.setStringList(
      'cached_transactions',
      _transactions.map((t) => jsonEncode(t.toMap())).toList(),
    );
  }

  Future<void> addTransaction(Transaction transaction) async {
    String category = transaction.category;
    if (transaction.type == 'expense' && category == '기타') {
      category = await GeminiService.instance.classifyTransaction(transaction.title);
    }

    final newTx = transaction.copyWith(category: category, isAiClassified: true);

    _transactions.insert(0, newTx);
    notifyListeners();

    if (_userId.isNotEmpty) {
      final saved = await _api.addTransaction(userId: _userId, transaction: newTx);
      if (saved != null) {
        final idx = _transactions.indexWhere((t) => t.id == newTx.id);
        if (idx >= 0) _transactions[idx] = saved;
      }

      _api.trackEvent(
        eventName: 'transaction_added',
        userId: _userId,
        data: {
          'category': category,
          'type': transaction.type,
          'amount': transaction.amount,
        },
      );

      _adCounter++;
    }

    notifyListeners();
    if (newTx.type == 'expense') _detectAnomaly(newTx);
  }

  Future<void> updateTransaction(Transaction updated) async {
    final idx = _transactions.indexWhere((t) => t.id == updated.id);
    if (idx < 0) return;
    _transactions[idx] = updated;
    notifyListeners();

    if (_userId.isNotEmpty) {
      await _api.updateTransaction(_userId, updated);
    }
  }

  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();

    if (_userId.isNotEmpty) {
      await _api.deleteTransaction(id, userId: _userId);
    }
  }

  bool shouldShowInterstitialAd(int freq) {
    return _adCounter % freq == 0 && _adCounter > 0;
  }

  void _detectAnomaly(Transaction tx) {
    final catTxs = _transactions
        .where((t) => t.type == 'expense' && t.category == tx.category && t.id != tx.id)
        .toList();
    if (catTxs.length < 3) return;
    final avg = catTxs.fold(0.0, (s, t) => s + t.amount) / catTxs.length;
    if (tx.amount > avg * 2.0 && tx.amount > 15000) {
      GeminiService.instance.explainAnomaly(
        transaction: tx,
        categoryAverage: avg,
      ).then((explanation) {
        if (explanation != null) {
          NotificationService.showAnomalyAlert(
            category: tx.category,
            amount: tx.amount,
            explanation: explanation,
          );
        }
      });
    }
  }

  String generateNewId() => _uuid.v4();
}
