import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/transaction.dart';
import '../models/ocr_result.dart';
import '../services/ai_service.dart';
import '../utils/app_config.dart';

class GeminiService {
  GeminiService._();
  static final GeminiService instance = GeminiService._();

  static const _categories = [
    '식비', '교통', '쇼핑', '문화/여가', '의료', '통신', '주거', '교육', '기타'
  ];

  String get _base => '${AppConfig.apiBaseUrl}/api/ai';

  // ─── 초기화 (백엔드 방식에서는 no-op) ──────────────────────
  void initialize() {
    debugPrint('[Gemini] 백엔드 프록시 모드 (${AppConfig.apiBaseUrl}/api/ai)');
  }

  Future<Map<String, dynamic>?> _post(String path, Map<String, dynamic> body) async {
    try {
      final res = await http.post(
        Uri.parse('$_base$path'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      debugPrint('[Gemini] $path 오류 ${res.statusCode}: ${res.body}');
      return null;
    } catch (e) {
      debugPrint('[Gemini] $path 네트워크 오류: $e');
      return null;
    }
  }

  // ─── Feature 3: 카테고리 분류 고도화 ────────────────────
  Future<String> classifyTransaction(String title) async {
    final data = await _post('/classify', {'title': title});
    final result = data?['category'] as String? ?? '';
    return _categories.contains(result) ? result : AiService.classifyTransaction(title);
  }

  // ─── Feature 2: 영수증 OCR ───────────────────────────────
  Future<OcrResult?> parseReceiptImage(Uint8List imageBytes) async {
    final data = await _post('/ocr', {
      'imageBase64': base64Encode(imageBytes),
    });
    if (data == null) return null;
    return OcrResult(
      title: data['merchant'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble(),
      category: data['category'] as String? ?? '기타',
    );
  }

  // ─── Feature 1: AI 소비 상담 챗봇 ───────────────────────
  void resetChat() {}  // 백엔드 방식은 stateless

  Future<String> chat({
    required String message,
    required List<Transaction> transactions,
    required List<Budget> budgets,
    required double income,
    required double expense,
  }) async {
    final data = await _post('/chat', {
      'message': message,
      'context': _buildContext(transactions, budgets, income, expense),
    });
    return data?['reply'] as String? ?? '답변을 생성하지 못했습니다.';
  }

  // ─── Feature 4: 월말 AI 리포트 ──────────────────────────
  Future<String> generateMonthlyReport({
    required int year,
    required int month,
    required List<Transaction> transactions,
    required List<Budget> budgets,
    required double totalIncome,
    required double totalExpense,
  }) async {
    final ctx = _buildContext(transactions, budgets, totalIncome, totalExpense);
    final data = await _post('/report', {
      'year': year,
      'month': month,
      'context': '카테고리별 지출: ${ctx['catSummary']}\n예산 현황: ${ctx['budgetSummary']}\n최근 거래: ${ctx['recentTxs']}',
      'totalIncome': totalIncome.toInt(),
      'totalExpense': totalExpense.toInt(),
    });
    return data?['report'] as String? ?? '';
  }

  // ─── Feature 5: 예산 자동 추천 ──────────────────────────
  Future<Map<String, double>> suggestBudgets({
    required List<Transaction> transactions,
    required Map<String, double> currentBudgets,
    required double monthlyIncome,
  }) async {
    final catExpenses = <String, int>{};
    for (final t in transactions.where((t) => t.type == 'expense')) {
      catExpenses[t.category] = (catExpenses[t.category] ?? 0) + t.amount.toInt();
    }
    final data = await _post('/suggest-budgets', {
      'monthlyIncome': monthlyIncome.toInt(),
      'catExpenses': catExpenses,
      'currentBudgets': currentBudgets.map((k, v) => MapEntry(k, v.toInt())),
    });
    if (data == null) return {};
    final budgets = data['budgets'] as Map<String, dynamic>? ?? {};
    return budgets.map((k, v) => MapEntry(k, (v as num).toDouble()));
  }

  // ─── Feature 6: 이상 지출 감지 설명 ────────────────────
  Future<String?> explainAnomaly({
    required Transaction transaction,
    required double categoryAverage,
  }) async {
    final data = await _post('/anomaly', {
      'title': transaction.title,
      'amount': transaction.amount.toInt(),
      'category': transaction.category,
      'categoryAverage': categoryAverage.toInt(),
    });
    return data?['explanation'] as String?;
  }

  // ─── 내부 헬퍼 ───────────────────────────────────────────
  Map<String, String> _buildContext(
    List<Transaction> transactions,
    List<Budget> budgets,
    double income,
    double expense,
  ) {
    final catExpenses = <String, double>{};
    for (final t in transactions.where((t) => t.type == 'expense')) {
      catExpenses[t.category] = (catExpenses[t.category] ?? 0) + t.amount;
    }
    return {
      'income': income.toInt().toString(),
      'expense': expense.toInt().toString(),
      'catSummary': catExpenses.entries.map((e) => '${e.key}: ${e.value.toInt()}원').join(', '),
      'budgetSummary': budgets.map((b) => '${b.category}: ${b.spent.toInt()}/${b.limit.toInt()}원').join(', '),
      'recentTxs': transactions.take(8).map((t) => '${t.title}(${t.amount.toInt()}원)').join(', '),
    };
  }
}
