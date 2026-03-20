import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../providers/transaction_provider.dart';
import '../services/gemini_service.dart';

class GeminiProvider extends ChangeNotifier {
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

  // ─── 챗봇 ────────────────────────────────────────────────
  Future<void> sendMessage(String text, TransactionProvider txProvider) async {
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
      transactions: txProvider.currentMonthTransactions,
      budgets: txProvider.budgets,
      income: txProvider.totalIncome,
      expense: txProvider.totalExpense,
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

  // ─── 월말 리포트 ──────────────────────────────────────────
  Future<void> generateReport(TransactionProvider txProvider) async {
    _isReportLoading = true;
    _error = null;
    notifyListeners();

    final now = DateTime.now();
    _monthlyReport = await GeminiService.instance.generateMonthlyReport(
      year: now.year,
      month: now.month,
      transactions: txProvider.currentMonthTransactions,
      budgets: txProvider.budgets,
      totalIncome: txProvider.totalIncome,
      totalExpense: txProvider.totalExpense,
    );

    if (_monthlyReport.isEmpty) {
      _error = '리포트 생성에 실패했습니다. 다시 시도해주세요.';
    }
    _isReportLoading = false;
    notifyListeners();
  }

  // ─── 예산 추천 ────────────────────────────────────────────
  Future<void> fetchBudgetSuggestions(TransactionProvider txProvider) async {
    _isBudgetLoading = true;
    _error = null;
    notifyListeners();

    final currentBudgets = {
      for (final b in txProvider.budgets) b.category: b.limit
    };

    _suggestedBudgets = await GeminiService.instance.suggestBudgets(
      transactions: txProvider.currentMonthTransactions,
      currentBudgets: currentBudgets,
      monthlyIncome: txProvider.totalIncome > 0 ? txProvider.totalIncome : 3000000,
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
