import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../services/ai_service.dart';
import '../services/budget_api_service.dart';
import '../services/notification_service.dart';

class BudgetProvider extends ChangeNotifier {
  String _userId = '';
  List<Budget> _budgets = [];
  List<AiInsight> _insights = [];

  final _api = BudgetApiService.instance;

  List<Budget> get budgets => _budgets;
  List<AiInsight> get insights => _insights;

  // ProxyProvider2에서 AppProvider.userId + TransactionProvider 데이터가 바뀔 때 호출
  void update({
    required String userId,
    required Map<String, double> categoryExpenses,
    required List<Transaction> currentMonthTransactions,
    required double totalIncome,
    required double totalExpense,
    required Map<String, dynamic> appConfig,
  }) {
    if (_userId != userId && userId.isNotEmpty) {
      _userId = userId;
      _loadBudgets();
    }

    final prevSpent = {for (final b in _budgets) b.category: b.spent};
    for (final b in _budgets) {
      b.spent = categoryExpenses[b.category] ?? 0;
    }
    _checkBudgetAlerts(prevSpent);

    _insights = AiService.generateInsights(
      transactions: currentMonthTransactions,
      budgets: _budgets,
      totalExpense: totalExpense,
      totalIncome: totalIncome,
      thresholds: appConfig['ai_insight_thresholds'] is Map<String, dynamic>
          ? appConfig['ai_insight_thresholds'] as Map<String, dynamic>
          : {},
    );

    notifyListeners();
  }

  Future<void> _loadBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    _loadFromCache(prefs);
    notifyListeners();

    try {
      final budgets = await _api.fetchBudgets(_userId);
      _budgets = budgets;
      _saveToCache(prefs);
      notifyListeners();
    } catch (_) {}
  }

  void _loadFromCache(SharedPreferences prefs) {
    final budgetJson = prefs.getStringList('cached_budgets');
    if (budgetJson != null) {
      _budgets = budgetJson
          .map((s) {
            try {
              return Budget.fromMap(jsonDecode(s) as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .whereType<Budget>()
          .toList();
    }
  }

  Future<void> _saveToCache(SharedPreferences prefs) async {
    await prefs.setStringList(
      'cached_budgets',
      _budgets.map((b) => jsonEncode(b.toMap())).toList(),
    );
  }

  Future<void> updateBudget(String category, double limit) async {
    final idx = _budgets.indexWhere((b) => b.category == category);
    if (idx >= 0) {
      _budgets[idx].limit = limit;
    } else {
      _budgets.add(Budget(category: category, limit: limit));
    }
    notifyListeners();

    if (_userId.isNotEmpty) {
      await _api.upsertBudget(
        userId: _userId,
        category: category,
        monthlyLimit: limit,
      );
    }
  }

  void _checkBudgetAlerts(Map<String, double> prevSpent) {
    for (final budget in _budgets) {
      if (budget.limit <= 0) continue;
      final prev = prevSpent[budget.category] ?? 0;
      if (budget.spent > budget.limit && prev <= budget.limit) {
        NotificationService.showBudgetAlert(
          category: budget.category,
          spent: budget.spent,
          limit: budget.limit,
        );
      }
    }
  }
}
