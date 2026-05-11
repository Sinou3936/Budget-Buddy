import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../models/transaction.dart';
import '../services/gemini_service.dart';

class AiProvider extends ChangeNotifier {
  final _uuid = const Uuid();

  final List<ChatMessage> _chatHistory = [];
  String _monthlyReport = '';
  Map<String, double> _suggestedBudgets = {};

  bool _isChatLoading = false;
  bool _isReportLoading = false;
  bool _isBudgetLoading = false;
  String? _error;

  List<ChatMessage> get chatHistory => List.unmodifiable(_chatHistory);
  String get monthlyReport => _monthlyReport;
  Map<String, double> get suggestedBudgets => Map.unmodifiable(_suggestedBudgets);
  bool get isChatLoading => _isChatLoading;
  bool get isReportLoading => _isReportLoading;
  bool get isBudgetLoading => _isBudgetLoading;
  String? get error => _error;

  Future<void> sendMessage({
    required String text,
    required List<Transaction> transactions,
    required List<Budget> budgets,
    required double income,
    required double expense,
  }) async {
    if (text.trim().isEmpty) return;

    _chatHistory.add(ChatMessage(
      id: _uuid.v4(),
      role: ChatRole.user,
      text: text.trim(),
    ));
    _isChatLoading = true;
    _error = null;
    notifyListeners();

    final reply = await GeminiService.instance.chat(
      message: text,
      transactions: transactions,
      budgets: budgets,
      income: income,
      expense: expense,
    );

    _chatHistory.add(ChatMessage(
      id: _uuid.v4(),
      role: ChatRole.assistant,
      text: reply,
    ));
    _isChatLoading = false;
    notifyListeners();
  }

  void clearChat() {
    _chatHistory.clear();
    GeminiService.instance.resetChat();
    notifyListeners();
  }

  Future<void> generateReport({
    required int year,
    required int month,
    required List<Transaction> transactions,
    required List<Budget> budgets,
    required double totalIncome,
    required double totalExpense,
  }) async {
    _isReportLoading = true;
    _error = null;
    notifyListeners();

    _monthlyReport = await GeminiService.instance.generateMonthlyReport(
      year: year,
      month: month,
      transactions: transactions,
      budgets: budgets,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
    );

    if (_monthlyReport.isEmpty) {
      _error = '리포트 생성에 실패했습니다. 다시 시도해주세요.';
    }
    _isReportLoading = false;
    notifyListeners();
  }

  Future<void> fetchBudgetSuggestions({
    required List<Transaction> transactions,
    required Map<String, double> currentBudgets,
    required double monthlyIncome,
  }) async {
    _isBudgetLoading = true;
    _error = null;
    notifyListeners();

    _suggestedBudgets = await GeminiService.instance.suggestBudgets(
      transactions: transactions,
      currentBudgets: currentBudgets,
      monthlyIncome: monthlyIncome > 0 ? monthlyIncome : 3000000,
    );

    if (_suggestedBudgets.isEmpty) {
      _error = '예산 추천에 실패했습니다. 다시 시도해주세요.';
    }
    _isBudgetLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
