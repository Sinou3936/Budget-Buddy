import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../services/ai_service.dart';
import '../services/budget_api_service.dart';
import '../services/notification_service.dart';
import '../services/gemini_service.dart';

class TransactionProvider extends ChangeNotifier {
  // ─── State ───────────────────────────────────────────────
  List<Transaction> _transactions = [];
  List<Budget>      _budgets      = [];
  List<AiInsight>   _insights     = [];
  List<Map<String, dynamic>> _banks        = [];
  List<Map<String, dynamic>> _plans        = [];
  List<Map<String, dynamic>> _bankAccounts = [];
  Map<String, dynamic> _appConfig  = {};

  bool    _isPremium = false;
  bool    _isLoading = false;
  bool    _isOffline = false;
  String  _userId    = '';
  int     _adCounter = 0;

  final _uuid = const Uuid();
  final _api  = BudgetApiService.instance;

  // ─── Getters ─────────────────────────────────────────────
  List<Transaction>          get transactions  => _transactions;
  List<Budget>               get budgets       => _budgets;
  List<AiInsight>            get insights      => _insights;
  List<Map<String, dynamic>> get banks         => _banks;
  List<Map<String, dynamic>> get plans         => _plans;
  List<Map<String, dynamic>> get bankAccounts  => _bankAccounts;
  Map<String, dynamic>       get appConfig     => _appConfig;
  bool                       get isPremium     => _isPremium;
  bool                       get isLoading     => _isLoading;
  bool                       get isOffline     => _isOffline;
  String                     get userId        => _userId;

  // 광고 노출 빈도 (서버 설정값)
  int get adInterstitialFreq {
    return int.tryParse(_appConfig['ad_interstitial_freq']?.toString() ?? '5') ?? 5;
  }

  // 배너 광고 활성화 여부 (서버 설정값)
  bool get adBannerEnabled {
    return _appConfig['ad_banner_enabled']?.toString() != 'false';
  }

  // 앱 이름 (서버 설정값)
  String get appName => _appConfig['app_name']?.toString() ?? 'Budget Buddy';

  // ─── 월별 필터 ────────────────────────────────────────────
  List<Transaction> get currentMonthTransactions {
    final now = DateTime.now();
    return _transactions.where((t) {
      return t.date.year == now.year && t.date.month == now.month;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
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

  // ─── 초기화 ───────────────────────────────────────────────
  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. 캐시 로드 → UI 즉시 표시
    _loadFromCache(prefs);
    final hasCachedData = _transactions.isNotEmpty;
    _isLoading = !hasCachedData;
    notifyListeners();

    // 2. 기기 ID
    String? deviceId = prefs.getString('device_id');
    if (deviceId == null) {
      deviceId = _uuid.v4();
      await prefs.setString('device_id', deviceId);
    }

    if (hasCachedData) {
      // 캐시 있음: UI는 이미 표시 중 → 네트워크 갱신은 완전 백그라운드
      _isLoading = false;
      notifyListeners();
      _refreshInBackground(prefs, deviceId);
    } else {
      // 첫 실행(캐시 없음): 네트워크 데이터 기다림
      await _fetchFromNetwork(prefs, deviceId);
      _isLoading = false;
      notifyListeners();
      await _generateAiInsights();
    }
  }

  void _refreshInBackground(SharedPreferences prefs, String deviceId) {
    _fetchFromNetwork(prefs, deviceId).then((_) {
      _generateAiInsights();
    });
  }

  Future<void> _fetchFromNetwork(SharedPreferences prefs, String deviceId) async {
    try {
      final results = await Future.wait([
        _api.fetchAppConfig(),
        _api.fetchPlans(),
        _api.fetchAiKeywords(),
      ]);

      _appConfig = results[0] as Map<String, dynamic>;
      _plans     = results[1] as List<Map<String, dynamic>>;
      _isOffline = _appConfig.isEmpty;
      AiService.updateKeywords(results[2] as Map<String, List<String>>);

      final user = await _api.registerUser(deviceId);
      if (user != null) {
        _userId    = user['id'] as String;
        _isPremium = user['is_premium'] == true;
        await prefs.setString('user_id', _userId);
        await prefs.setBool('is_premium', _isPremium);
      } else {
        _userId    = prefs.getString('user_id') ?? '';
        _isPremium = prefs.getBool('is_premium') ?? false;
      }

      if (_userId.isNotEmpty) {
        final txBudget = await Future.wait([
          _api.fetchTransactions(userId: _userId),
          _api.fetchBudgets(_userId),
        ]);
        _transactions = txBudget[0] as List<Transaction>;
        _budgets      = txBudget[1] as List<Budget>;
        _saveToCache(prefs);
        notifyListeners();
      }

      _api.trackEvent(eventName: 'app_open', userId: _userId.isNotEmpty ? _userId : null);
    } catch (_) {
      _isOffline = true;
      notifyListeners();
    }
  }

  void _loadFromCache(SharedPreferences prefs) {
    _userId    = prefs.getString('user_id') ?? '';
    _isPremium = prefs.getBool('is_premium') ?? false;

    final txJson = prefs.getStringList('cached_transactions');
    if (txJson != null) {
      _transactions = txJson
          .map((s) { try { return Transaction.fromMap(jsonDecode(s) as Map<String, dynamic>); } catch (_) { return null; } })
          .whereType<Transaction>()
          .toList();
    }

    final budgetJson = prefs.getStringList('cached_budgets');
    if (budgetJson != null) {
      _budgets = budgetJson
          .map((s) { try { return Budget.fromMap(jsonDecode(s) as Map<String, dynamic>); } catch (_) { return null; } })
          .whereType<Budget>()
          .toList();
    }

    _updateBudgetSpent();
  }

  Future<void> _saveToCache(SharedPreferences prefs) async {
    await prefs.setStringList(
      'cached_transactions',
      _transactions.map((t) => jsonEncode(t.toMap())).toList(),
    );
    await prefs.setStringList(
      'cached_budgets',
      _budgets.map((b) => jsonEncode(b.toMap())).toList(),
    );
  }

  // ─── 거래 추가 ────────────────────────────────────────────
  Future<void> addTransaction(Transaction transaction) async {
    // AI 자동 분류 (Gemini 우선, 폴백으로 키워드 분류)
    String category = transaction.category;
    if (transaction.type == 'expense' && category == '기타') {
      category = await GeminiService.instance.classifyTransaction(transaction.title);
    }

    final newTx = transaction.copyWith(category: category, isAiClassified: true);

    // 낙관적 업데이트 (UI 즉시 반영)
    _transactions.insert(0, newTx);
    final prevSpent = {for (final b in _budgets) b.category: b.spent};
    _updateBudgetSpent();
    _checkBudgetAlerts(prevSpent);
    notifyListeners();

    // API 저장
    if (_userId.isNotEmpty) {
      final saved = await _api.addTransaction(userId: _userId, transaction: newTx);
      if (saved != null) {
        // 서버 저장 성공 - 서버 ID로 교체
        final idx = _transactions.indexWhere((t) => t.id == newTx.id);
        if (idx >= 0) _transactions[idx] = saved;
      }

      // 이벤트 추적
      _api.trackEvent(
        eventName: 'transaction_added',
        userId: _userId,
        data: {'category': category, 'type': transaction.type, 'amount': transaction.amount},
      );

      // 광고 카운터 증가
      _adCounter++;
    }

    _updateBudgetSpent();
    notifyListeners();
    await _generateAiInsights();

    // 이상 지출 감지 (비동기, 결과 기다리지 않음)
    if (newTx.type == 'expense') _detectAnomaly(newTx);
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

  /// 광고 노출 여부 체크 (거래 추가 후 호출)
  bool shouldShowInterstitialAd() {
    if (_isPremium) return false;
    return _adCounter % adInterstitialFreq == 0 && _adCounter > 0;
  }

  // ─── 거래 수정 ────────────────────────────────────────────
  Future<void> updateTransaction(Transaction updated) async {
    final idx = _transactions.indexWhere((t) => t.id == updated.id);
    if (idx < 0) return;
    _transactions[idx] = updated;
    final prevSpent = {for (final b in _budgets) b.category: b.spent};
    _updateBudgetSpent();
    _checkBudgetAlerts(prevSpent);
    notifyListeners();

    if (_userId.isNotEmpty) {
      await _api.updateTransaction(_userId, updated);
    }
    await _generateAiInsights();
  }

  // ─── 거래 삭제 ────────────────────────────────────────────
  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((t) => t.id == id);
    _updateBudgetSpent();
    notifyListeners();

    if (_userId.isNotEmpty) {
      await _api.deleteTransaction(id, userId: _userId);
    }
    await _generateAiInsights();
  }

  // ─── 예산 업데이트 ────────────────────────────────────────
  Future<void> updateBudget(String category, double limit) async {
    final idx = _budgets.indexWhere((b) => b.category == category);
    if (idx >= 0) {
      _budgets[idx].limit = limit;
    } else {
      _budgets.add(Budget(category: category, limit: limit));
    }
    _updateBudgetSpent();
    notifyListeners();

    if (_userId.isNotEmpty) {
      await _api.upsertBudget(userId: _userId, category: category, monthlyLimit: limit);
    }
  }

  // ─── 은행 연동 ────────────────────────────────────────────
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

  // ─── 프리미엄 설정 ────────────────────────────────────────
  Future<void> setPremium(bool value) async {
    _isPremium = value;
    notifyListeners();

    if (_userId.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_premium', value);
      await _api.setPremium(_userId, isPremium: value);
      _api.trackEvent(
        eventName: value ? 'premium_purchased' : 'premium_cancelled',
        userId: _userId,
      );
    }
  }

  // ─── 이벤트 추적 (화면 방문 등) ──────────────────────────
  void trackPageView(String pageName) {
    _api.trackEvent(
      eventName: 'page_view',
      userId: _userId.isNotEmpty ? _userId : null,
      data: {'page': pageName},
    );
  }

  void trackAdShown(String adType) {
    _api.trackAdEvent(
      userId: _userId.isNotEmpty ? _userId : null,
      adType: adType,
    );
  }

  // ─── 내부 헬퍼 ───────────────────────────────────────────
  void _checkBudgetAlerts(Map<String, double> prevSpent) {
    for (final budget in _budgets) {
      if (budget.limit <= 0) continue;
      final prev = prevSpent[budget.category] ?? 0;
      // 이번 거래로 인해 처음으로 예산을 초과한 경우에만 알림
      if (budget.spent > budget.limit && prev <= budget.limit) {
        NotificationService.showBudgetAlert(
          category: budget.category,
          spent: budget.spent,
          limit: budget.limit,
        );
      }
    }
  }

  void _updateBudgetSpent() {
    final expenses = categoryExpenses;
    for (final budget in _budgets) {
      budget.spent = expenses[budget.category] ?? 0;
    }
  }

  Future<void> _generateAiInsights() async {
    // AI 임계값도 서버에서 가져온 값 사용
    Map<String, dynamic> thresholds = {};
    try {
      final raw = _appConfig['ai_insight_thresholds'];
      if (raw is Map<String, dynamic>) thresholds = raw;
    } catch (_) {}

    _insights = AiService.generateInsights(
      transactions: currentMonthTransactions,
      budgets: _budgets,
      totalExpense: totalExpense,
      totalIncome: totalIncome,
      thresholds: thresholds,
    );
    notifyListeners();
  }

  String generateNewId() => _uuid.v4();
}
